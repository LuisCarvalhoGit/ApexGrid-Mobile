import 'dart:async';
import 'dart:math'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/telemetry_point.dart';
import '../models/session_record.dart';
import '../services/csv_storage_service.dart';
import '../services/database_service.dart';
import '../main.dart'; 

import 'history_controller.dart';
import 'lean_angle_controller.dart';
import '../models/session_data_point.dart';
import 'location_controller.dart';

enum SessionState { idle, recording }

class SessionController extends Notifier<SessionState> {
  final List<SessionDataPoint> _buffer = [];
  StreamSubscription<TelemetryPoint>? _subscription;
  DateTime? _sessionStartTime;
  
  // Guarda o ângulo real e calibrado durante a viagem
  double _currentMaxLean = 0.0;

  @override
  SessionState build() {
    // Ouve diretamente a fonte matemática pura, sem depender do gráfico!
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
    
    _subscription = ref.read(filteredTelemetryStreamProvider).listen((point) {
      // 2. Lemos o estado ATUAL do Ângulo e do GPS no momento exato deste pulso
      final currentLean = ref.read(leanAngleProvider);
      final currentLoc = ref.read(locationProvider);
      final timeMs = DateTime.now().difference(_sessionStartTime!).inMilliseconds;

      // 3. Juntamos tudo no nosso novo formato de alta densidade
      _buffer.add(SessionDataPoint(
        timeMs: timeMs,
        leanAngle: currentLean,
        gForceX: point.x,
        gForceY: point.y,
        latitude: currentLoc.currentPosition?.latitude ?? 0.0,
        longitude: currentLoc.currentPosition?.longitude ?? 0.0,
        speedKmh: currentLoc.speedKmh,
      ));
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
      // Cálculo da Força-G combinada (Aceleração/Travagem Y + Força Lateral X)
      final gForce = sqrt(point.gForceX * point.gForceX + point.gForceY * point.gForceY);
      if (gForce > maxG) maxG = gForce;
    }

    final record = SessionRecord(
      startTime: _sessionStartTime!,
      endTime: DateTime.now(),
      maxLeanAngle: _currentMaxLean, // Usamos o nosso valor calibrado pelo Sensor Fusion!
      maxGForce: maxG,
      csvFilePath: savedPath,
    );

    await DatabaseService().insertSession(record);

    // Invalida a cache do histórico. Da próxima vez que o utilizador
    // abrir a aba, o Riverpod vai ler a base de dados de novo automaticamente!
    ref.invalidate(historyProvider);
    
    _buffer.clear();
    _sessionStartTime = null;
    return true;
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(() {
  return SessionController();
});