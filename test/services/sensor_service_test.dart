import 'dart:async';
import 'package:flutter_test/flutter_test.dart'; // Usar flutter_test em vez de apenas 'test'
import 'package:sensors_plus/sensors_plus.dart';
import 'package:apexgrid/services/sensor_service.dart';
import 'package:apexgrid/models/telemetry_point.dart';

void main() {
  group('SensorService Tests | Conversão Física', () {
    late StreamController<UserAccelerometerEvent> mockStreamController;
    late SensorService sensorService;
    
    // A constante de gravidade que definiste no teu serviço
    final double g = SensorService.standardGravity;

    setUp(() {
      mockStreamController = StreamController<UserAccelerometerEvent>();
      sensorService = SensorService(mockStreamController.stream);
    });

    tearDown(() {
      mockStreamController.close();
    });

    test('Deve mapear UserAccelerometerEvent convertendo m/s² para Força G (Gs)', () async {
      // Expectativa: Como vamos injetar múltiplos da força G em baixo, 
      // esperamos que o serviço os divida e devolva números inteiros/limpos.
      expectLater(
        sensorService.telemetryStream,
        emits(
          isA<TelemetryPoint>()
              // Usamos closeTo(valor_esperado, margem_de_erro) para evitar falhas de casas decimais
              .having((p) => p.x, 'Eixo X em Gs', closeTo(1.5, 0.001))
              .having((p) => p.y, 'Eixo Y em Gs', closeTo(-0.5, 0.001))
              .having((p) => p.z, 'Eixo Z em Gs', closeTo(1.0, 0.001)),
        ),
      );

      // Injeção de dado simulando o hardware do telemóvel (que fala em m/s²)
      mockStreamController.add(
        UserAccelerometerEvent(1.5 * g, -0.5 * g, 1.0 * g, DateTime.now())
      );
    });
  });
}