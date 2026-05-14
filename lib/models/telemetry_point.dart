class TelemetryPoint {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const TelemetryPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'TelemetryPoint(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';
  }
}