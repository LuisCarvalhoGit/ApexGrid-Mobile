import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/sensor_fusion.dart';

class LeanAngleController extends Notifier<double> {
  final SensorFusion _fusion = SensorFusion();
  double _calibrationOffset = 0.0;
  AccelerometerEvent? _lastAcc;
  
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Buffer para captar vários pontos e calcular uma calibração perfeita
  final List<double> _calibrationBuffer = [];

  @override
  double build() {
    _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((acc) {
      _lastAcc = acc;
    });

    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval).listen((gyro) {
      if (_lastAcc == null) return;

      final rawAngle = _fusion.calculateLeanAngle(
        accX: _lastAcc!.x, accY: _lastAcc!.y, accZ: _lastAcc!.z,
        gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
      );

      // Se estivermos a recolher dados para calibrar, guardamos no buffer
      if (_calibrationBuffer.length < 20 && _calibrationBuffer.isNotEmpty) {
        _calibrationBuffer.add(rawAngle);
        if (_calibrationBuffer.length == 20) {
          // Quando atinge 20 amostras, calcula a média para ignorar vibrações do motor
          _calibrationOffset = _calibrationBuffer.reduce((a, b) => a + b) / _calibrationBuffer.length;
          _calibrationBuffer.clear();
        }
      }

      state = rawAngle - _calibrationOffset;
    });

    ref.onDispose(() {
      _accSub?.cancel();
      _gyroSub?.cancel();
    });

    return 0.0;
  }

  // Nova calibração "Senior": Em vez de confiar em 1 leitura, inicia uma recolha de 20 leituras (cerca de 0.4 seg)
  void setZeroCalibration() {
    _calibrationBuffer.clear();
    _calibrationBuffer.add(state + _calibrationOffset); // Inicia o trigger
  }
}

final leanAngleProvider = NotifierProvider<LeanAngleController, double>(() {
  return LeanAngleController();
});