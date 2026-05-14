/// test/services/sensor_service_test.dart
import 'dart:async';
import 'package:test/test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:apexgrid/services/sensor_service.dart';
import 'package:apexgrid/models/telemetry_point.dart';

void main() {
  group('SensorService Tests', () {
    late StreamController<UserAccelerometerEvent> mockStreamController;
    late SensorService sensorService;

    setUp(() {
      mockStreamController = StreamController<UserAccelerometerEvent>();
      sensorService = SensorService(mockStreamController.stream);
    });

    tearDown(() {
      mockStreamController.close();
    });

    test('Deve mapear UserAccelerometerEvent para TelemetryPoint com timestamp correto', () async {
      // Expectativa assíncrona para a stream de saída
      expectLater(
        sensorService.telemetryStream,
        emits(
          isA<TelemetryPoint>()
              .having((p) => p.x, 'Eixo X', 1.5)
              .having((p) => p.y, 'Eixo Y', -0.5)
              .having((p) => p.z, 'Eixo Z', 9.8),
        ),
      );

      // Injeção de dado falso simulando o hardware
      mockStreamController.add(UserAccelerometerEvent(1.5, -0.5, 9.8, DateTime.now()));
    });
  });
}