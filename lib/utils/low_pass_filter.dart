import '../models/telemetry_point.dart';

class LowPassFilter {
  final double alpha;
  
  // Guardamos o estado anterior de cada eixo
  double? _lastX;
  double? _lastY;
  double? _lastZ;

  LowPassFilter(this.alpha);

  TelemetryPoint apply(TelemetryPoint current) {
    // Se for o primeiro ponto, não há filtro a aplicar ainda
    if (_lastX == null || _lastY == null || _lastZ == null) {
      _lastX = current.x;
      _lastY = current.y;
      _lastZ = current.z;
      return current;
    }

    // Aplicação da fórmula EMA: F_n = alpha * S_n + (1 - alpha) * F_{n-1}
    _lastX = alpha * current.x + (1 - alpha) * _lastX!;
    _lastY = alpha * current.y + (1 - alpha) * _lastY!;
    _lastZ = alpha * current.z + (1 - alpha) * _lastZ!;

    return TelemetryPoint(
      x: _lastX!,
      y: _lastY!,
      z: _lastZ!,
      timestamp: current.timestamp,
    );
  }
}