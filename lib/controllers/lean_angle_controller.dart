import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/sensor_fusion.dart';

class LeanAngleController extends Notifier<double> {
  final SensorFusion _fusion = SensorFusion();
  double _calibrationOffset = 0.0;
  AccelerometerEvent? _lastAcc;
  
  // Guardamos as subscrições para as poder cancelar depois
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  @override
  double build() {
    // 1. Escutamos o acelerómetro puro
    _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((acc) {
      _lastAcc = acc;
    });

    // 2. Escutamos o giroscópio e emitimos o ângulo atualizado
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval).listen((gyro) {
      if (_lastAcc == null) return;

      final rawAngle = _fusion.calculateLeanAngle(
        accX: _lastAcc!.x, accY: _lastAcc!.y, accZ: _lastAcc!.z,
        gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
      );

      // Atualizamos o estado global com o ângulo já calibrado
      state = rawAngle - _calibrationOffset;
    });

    // 3. SEGURANÇA: Cancela as leituras se o provider for destruído
    ref.onDispose(() {
      _accSub?.cancel();
      _gyroSub?.cancel();
    });

    return 0.0; // Estado inicial (0 graus)
  }

  // A função que os botões de calibragem vão chamar!
  void setZeroCalibration() {
    _calibrationOffset += state;
    state = 0.0;
  }
}

final leanAngleProvider = NotifierProvider<LeanAngleController, double>(() {
  return LeanAngleController();
});