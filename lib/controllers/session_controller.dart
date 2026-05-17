import 'dart:async';
import 'dart:io';
import 'dart:math'; 
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/telemetry_point.dart';
import '../models/session_record.dart';
import '../services/csv_storage_service.dart';
import '../services/database_service.dart';
import '../services/telemetry_sync_service.dart';
import '../main.dart'; 

import 'history_controller.dart';
import 'lean_angle_controller.dart';
import '../models/session_data_point.dart';
import 'location_controller.dart';
import 'settings_controller.dart';

import 'package:latlong2/latlong.dart'; // Para os cálculos de GPS
import 'garage_controller.dart'; // Para aceder à frota

enum SessionState { idle, recording }

// A ponte de comunicação entre os sensores reais e o Dashboard!
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

      // Guardamos no ficheiro
      _buffer.add(currentDataPoint);

      // Disparamos o dado para a UI do Cockpit
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
    double maxSpeed = 0.0;
    double totalDistanceKm = 0.0;
    const distanceCalc = Distance();
    
    for (int i = 0; i < _buffer.length; i++) {
      final point = _buffer[i];
      
      // Velocidade e Força G
      if (point.speedKmh > maxSpeed) maxSpeed = point.speedKmh;
      final gForce = sqrt(point.gForceX * point.gForceX + point.gForceY * point.gForceY);
      if (gForce > maxG) maxG = gForce;

      // Distância de GPS
      if (i > 0) {
        final prev = _buffer[i - 1];
        if (prev.latitude != 0.0 && point.latitude != 0.0) {
          final meters = distanceCalc.as(LengthUnit.Meter, 
            LatLng(prev.latitude, prev.longitude), 
            LatLng(point.latitude, point.longitude)
          );
          totalDistanceKm += meters / 1000.0; 
        }
      }
    }

    // Congelamos o tempo de fim
    final endTime = DateTime.now();

    // Grava no SQL Local do telemóvel (Histórico)
    final record = SessionRecord(
      title: "Nova Viagem",
      startTime: _sessionStartTime!,
      endTime: endTime,
      maxLeanAngle: _currentMaxLean, 
      maxGForce: maxG,
      csvFilePath: savedPath,
      totalDistanceKm: totalDistanceKm + 1,
      maxSpeedKmh: maxSpeed,
    );

    final insertedId = await DatabaseService().insertSession(record);
    ref.invalidate(historyProvider);

    // Lógica da Garagem e Odómetro
    final fleet = ref.read(garageProvider);
    String bikeName = 'Mota Desconhecida';
    
    if (fleet.isNotEmpty) {
      final defaultBike = fleet.firstWhere((b) => b.isDefault, orElse: () => fleet.first);
      bikeName = '${defaultBike.brand} ${defaultBike.model}'; // Ex: "Yamaha Tracer 7"
      
      if (totalDistanceKm >= 1.0) {
        final newOdometer = defaultBike.currentOdometer + totalDistanceKm.round(); 
        ref.read(garageProvider.notifier).updateOdometer(defaultBike.id, newOdometer);
      }
    }

    // =======================================================
    // 5. NOVO: O TIRO PARA O NOSSO SERVIDOR C# / MINIO
    // =======================================================
    try {
      final syncService = TelemetrySyncService();
      
      // Corremos de forma assíncrona para não bloquear a UI
      final syncSuccess = await syncService.uploadRide(
        userId: '3fa85f64-5717-4562-b3fc-2c963f66afa6', // Guid de teste (Igual ao ficheiro .http)
        motorcycleModel: bikeName,
        startTime: _sessionStartTime!,
        endTime: endTime,
        totalDistanceKm: totalDistanceKm + 1,
        maxSpeedKmh: maxSpeed,
        maxLeanAngleDegrees: _currentMaxLean,
        maxGForce: maxG,
        csvFile: File(savedPath),
      );

      if (syncSuccess) {
        debugPrint("🚀 BACKEND: Upload e sincronização concluídos com sucesso!");

        await DatabaseService().markAsSynced(insertedId); 
        ref.invalidate(historyProvider);
      } else {
        debugPrint("⚠️ BACKEND: Falha ao enviar a viagem para o servidor.");
      }
    } catch (e) {
      debugPrint("❌ BACKEND: Erro ao tentar sincronizar: $e");
    }
    // =======================================================
    
    // Limpa a memória RAM e reseta o dashboard
    _buffer.clear();
    _sessionStartTime = null;

    ref.read(liveTelemetryProvider.notifier).state = SessionDataPoint(
      timeMs: 0, leanAngle: 0.0, gForceX: 0.0, gForceY: 0.0, latitude: 0, longitude: 0, speedKmh: 0.0
    );

    return true;
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(() {
  return SessionController();
});