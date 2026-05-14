import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/sensor_fusion.dart';

class LeanAngleController extends Notifier<double> {
  final SensorFusion _fusion = SensorFusion();
  double _calibrationOffset = 0.0;
  AccelerometerEvent? _lastAcc;

  @override
  double build() {
    // 1. Escutamos o acelerómetro puro
    accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((acc) {
      _lastAcc = acc;
    });

    // 2. Escutamos o giroscópio e emitimos o ângulo atualizado
    gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval).listen((gyro) {
      if (_lastAcc == null) return;

      final rawAngle = _fusion.calculateLeanAngle(
        accX: _lastAcc!.x, accY: _lastAcc!.y, accZ: _lastAcc!.z,
        gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
      );

      // Atualizamos o estado global com o ângulo já calibrado
      state = rawAngle - _calibrationOffset;
    });

    return 0.0; // Estado inicial (0 graus)
  }

  // A função que o botão de "Tarar" vai chamar
  void setZeroCalibration() {
    // Somamos o ângulo atual ao offset existente para criar o novo "zero" absoluto
    _calibrationOffset += state;
    state = 0.0;
  }
}

// O Provider global que o Gráfico e a Sessão vão escutar
final leanAngleProvider = NotifierProvider<LeanAngleController, double>(() {
  return LeanAngleController();
});