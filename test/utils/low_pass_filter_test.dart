import 'package:flutter_test/flutter_test.dart';
import 'package:apexgrid/utils/low_pass_filter.dart';
import 'package:apexgrid/models/telemetry_point.dart';

void main() {
  group('LowPassFilter Tests | Suavização de Vibração', () {
    test('Deve suavizar o ruído aplicando o fator Alpha corretamente', () {
      // Inicializa o filtro com um fator de 0.2 (20% do novo valor, 80% do valor anterior)
      final filter = LowPassFilter(0.2);
      
      // Simula uma mota parada no primeiro milissegundo
      final pt1 = TelemetryPoint(x: 0.0, y: 0.0, z: 1.0, timestamp: DateTime.now());
      final result1 = filter.apply(pt1);
      
      expect(result1.x, 0.0); // No primeiro ponto, como não há histórico, passa direto

      // Simula um buraco na estrada (Pico brusco de 5G no eixo X)
      final pt2 = TelemetryPoint(x: 5.0, y: 0.0, z: 1.0, timestamp: DateTime.now());
      final result2 = filter.apply(pt2);

      // A matemática do Low Pass: (NovoValor * alpha) + (ValorAntigo * (1 - alpha))
      // (5.0 * 0.2) + (0.0 * 0.8) = 1.0
      expect(result2.x, closeTo(1.0, 0.001), 
          reason: 'O filtro devia ter abafado o impacto do buraco de 5G para apenas 1G');
    });
  });
}