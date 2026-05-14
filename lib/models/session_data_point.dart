/// lib/models/session_data_point.dart
class SessionDataPoint {
  final int timeMs;        // Milissegundos desde o início da gravação
  final double leanAngle;  // Ângulo de inclinação calibrado
  final double gForceX;    // Força G Lateral
  final double gForceY;    // Aceleração / Travagem
  final double latitude;   // GPS
  final double longitude;  // GPS
  final double speedKmh;   // GPS

  SessionDataPoint({
    required this.timeMs,
    required this.leanAngle,
    required this.gForceX,
    required this.gForceY,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
  });
}