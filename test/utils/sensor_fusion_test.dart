import 'package:flutter_test/flutter_test.dart';
import 'package:apexgrid/utils/sensor_fusion.dart';

void main() {
  group('SensorFusion Tests | Física de Inclinação', () {
    late SensorFusion fusion;

    setUp(() {
      fusion = SensorFusion();
    });

    test('Mota na vertical a andar a direito (0º de inclinação)', () {
      // A gravidade (1G) puxa apenas o eixo Y para baixo. Eixo X (lateral) está a zero.
      final angle = fusion.calculateLeanAngle(
        accX: 0.0, accY: 9.81, accZ: 0.0,
        gyroX: 0.0, gyroY: 0.0, gyroZ: 0.0,
      );
      
      expect(angle, closeTo(0.0, 0.5));
    });

    test('Mota a curvar com forte inclinação (eixo X capta gravidade)', () {
      // Mota deitada, com a gravidade a atuar fortemente no eixo X lateral
      final angle = fusion.calculateLeanAngle(
        accX: 5.0, accY: 5.0, accZ: 0.0, // Força dividida em curva
        gyroX: 0.0, gyroY: 0.0, gyroZ: 0.0,
      );
      
      // Verifica se a trigonometria devolve um ângulo real (esperado aprox. 45 graus)
      expect(angle.abs(), greaterThan(30.0));
    });
  });
}