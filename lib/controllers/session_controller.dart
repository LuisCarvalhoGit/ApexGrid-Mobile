import 'dart:async';
import 'dart:math'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/telemetry_point.dart';
import '../models/session_record.dart';
import '../services/csv_storage_service.dart';
import '../services/database_service.dart';
import '../main.dart'; 

import 'history_controller.dart';
import 'lean_angle_controller.dart';
import '../models/session_data_point.dart';
import 'location_controller.dart';
import 'settings_controller.dart';

import 'package:latlong2/latlong.dart'; // Para os cálculos de GPS
import 'garage_controller.dart'; // Para aceder à frota

enum SessionState { idle, recording }

// NOVO: A ponte de comunicação entre os sensores reais e o Dashboard!
final liveTelemetryProvider = StateProvider<SessionDataPoint>((ref) {
  return SessionDataPoint(
    timeMs: 0, leanAngle: 0.0, gForceX: 0.0, gForceY: 0.0, latitude: 0, longitude: 0, speedKmh: 0.0
  );
});

class SessionController extends Notifier<SessionState> {
  final List<SessionDataPoint> _buffer = [];
  StreamSubscription<TelemetryPoint>? _subscription;
  DateTime? _sessionStartTime;
  
  double _currentMaxLean = 0.0;

  @override
  SessionState build() {
    ref.listen<double>(leanAngleProvider, (previous, currentAngle) {
      if (state == SessionState.recording) {
        final absAngle = currentAngle.abs();
        if (absAngle > _currentMaxLean) {
          _currentMaxLean = absAngle;
        }
      }
    });
    
    return SessionState.idle;
  }

  void startRecording() {
    _buffer.clear();
    _sessionStartTime = DateTime.now();
    _currentMaxLean = 0.0; 
    state = SessionState.recording;

    final settings = ref.read(settingsProvider);
    if (settings.autoCalibrate) {
      ref.read(leanAngleProvider.notifier).setZeroCalibration();
    }
    
    _subscription = ref.read(filteredTelemetryStreamProvider).listen((point) {
      final currentLean = ref.read(leanAngleProvider);
      final currentLoc = ref.read(locationProvider);
      final timeMs = DateTime.now().difference(_sessionStartTime!).inMilliseconds;

      final currentDataPoint = SessionDataPoint(
        timeMs: timeMs,
        leanAngle: currentLean,
        gForceX: point.x,
        gForceY: point.y,
        latitude: currentLoc.currentPosition?.latitude ?? 0.0,
        longitude: currentLoc.currentPosition?.longitude ?? 0.0,
        speedKmh: currentLoc.speedKmh, // Atualiza a velocidade
      );

      // 1. Guardamos no ficheiro
      _buffer.add(currentDataPoint);

      // 2. NOVO: Disparamos o dado para a UI do Cockpit (Isto anima a mota e o velocímetro!)
      ref.read(liveTelemetryProvider.notifier).state = currentDataPoint;
    });
  }

  Future<bool> stopRecording() async {
    state = SessionState.idle;
    await _subscription?.cancel();
    
    if (_buffer.isEmpty || _sessionStartTime == null) return false;

    final csvService = CsvStorageService();
    final savedPath = await csvService.saveSession(_buffer);
    
    double maxG = 0.0;
    
    for (final point in _buffer) {
      final gForce = sqrt(point.gForceX * point.gForceX + point.gForceY * point.gForceY);
      if (gForce > maxG) maxG = gForce;
    }

    final record = SessionRecord(
      title: "Sem Titulo",
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
      maxLeanAngle: _currentMaxLean, 
      maxGForce: maxG,
      csvFilePath: savedPath,
    );

    await DatabaseService().insertSession(record);
    ref.invalidate(historyProvider);

    // --- LÓGICA DE ATUALIZAÇÃO DO ODÓMETRO ---
    double totalDistanceKm = 0.0;
    const distanceCalc = Distance(); // Motor de cálculo de distâncias do latlong2
    
    // Percorremos os pontos do GPS da sessão para calcular a distância
    for (int i = 1; i < _buffer.length; i++) {
      final prev = _buffer[i - 1];
      final curr = _buffer[i];
      
      // Ignora pontos sem sinal de GPS (0.0)
      if (prev.latitude != 0.0 && curr.latitude != 0.0) {
        final meters = distanceCalc.as(LengthUnit.Meter, 
          LatLng(prev.latitude, prev.longitude), 
          LatLng(curr.latitude, curr.longitude)
        );
        totalDistanceKm += meters / 1000.0; // Converte para KM
      }
    }

    // Procura a mota principal e soma os quilómetros
    final fleet = ref.read(garageProvider);
    if (fleet.isNotEmpty && totalDistanceKm >= 1.0) {
      final defaultBike = fleet.firstWhere((b) => b.isDefault, orElse: () => fleet.first);
      final newOdometer = defaultBike.currentOdometer + totalDistanceKm.round(); // Arredondamos os KM
      ref.read(garageProvider.notifier).updateOdometer(defaultBike.id, newOdometer);
    }
    
    _buffer.clear();
    _sessionStartTime = null;

    // NOVO: Faz reset ao painel (mota direita, 0km/h) quando terminas a viagem
    ref.read(liveTelemetryProvider.notifier).state = SessionDataPoint(
      timeMs: 0, leanAngle: 0.0, gForceX: 0.0, gForceY: 0.0, latitude: 0, longitude: 0, speedKmh: 0.0
    );

    return true;
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(() {
  return SessionController();
});