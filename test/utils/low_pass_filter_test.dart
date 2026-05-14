import 'package:test/test.dart';
import 'package:apexgrid/models/telemetry_point.dart';
import 'package:apexgrid/utils/low_pass_filter.dart';

void main() {
  group('LowPassFilter Tests', () {
    test('O primeiro ponto deve passar sem alterações (inicialização)', () {
      final filter = LowPassFilter(0.2);
      final point = TelemetryPoint(x: 1.0, y: 2.0, z: 3.0, timestamp: DateTime.now());
      
      final result = filter.apply(point);
      
      expect(result.x, 1.0);
      expect(result.y, 2.0);
      expect(result.z, 3.0);
    });

    test('Deve suavizar um pico brusco de vibração mecânica', () {
      final filter = LowPassFilter(0.5); // Alpha 0.5 para matemática simples no teste
      final t1 = DateTime.now();
      
      // Ponto base (ex: a andar em linha reta constante)
      filter.apply(TelemetryPoint(x: 0.0, y: 0.0, z: 9.8, timestamp: t1));
      
      // Simulação de um buraco na estrada (pico brusco no eixo Z)
      final impactPoint = TelemetryPoint(x: 0.0, y: 0.0, z: 20.0, timestamp: t1);
      final result = filter.apply(impactPoint);
      
      // A fórmula: NovoZ = (0.5 * 20.0) + (0.5 * 9.8) = 10.0 + 4.9 = 14.9
      // O filtro impediu que o Z saltasse logo para 20.0, atenuando o solavanco.
      expect(result.z, closeTo(14.9, 0.01)); 
    });
  });
}