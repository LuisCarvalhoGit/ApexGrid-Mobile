import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/telemetry_point.dart';

class SensorService {
  final Stream<UserAccelerometerEvent> _accelerometerStream;

  // Constante da gravidade padrão para conversão de m/s² para G-Force
  static const double standardGravity = 9.80665;

  SensorService(this._accelerometerStream);

  /// Mapeia o evento bruto de hardware para o nosso modelo de domínio
  Stream<TelemetryPoint> get telemetryStream {
    return _accelerometerStream.map((event) {
      return TelemetryPoint(
        // Conversão de m/s² para Força-G
        x: event.x / standardGravity,
        y: event.y / standardGravity,
        z: event.z / standardGravity,
        timestamp: DateTime.now(),
      );
    });
  }
}