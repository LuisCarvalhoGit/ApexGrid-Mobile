import 'dart:math';

class SensorFusion {
  // Fator de peso: 98% confiança no Giroscópio, 2% no Acelerómetro
  final double alpha = 0.98; 
  
  double currentRoll = 0.0; // Inclinação lateral (Lean Angle) em graus
  DateTime? _lastUpdate;

  /// Retorna a inclinação lateral em Graus (Roll)
  double calculateLeanAngle({
    required double accX, required double accY, required double accZ,
    required double gyroX, required double gyroY, required double gyroZ,
  }) {
    final now = DateTime.now();
    
    // Inicialização no primeiro frame
    if (_lastUpdate == null) {
      _lastUpdate = now;
      currentRoll = - atan2(accX, sqrt(accY * accY + accZ * accZ)) * 180 / pi;
      return currentRoll;
    }

    // Calcular o Delta Time (tempo passado desde a última leitura)
    final dt = now.difference(_lastUpdate!).inMicroseconds / 1000000.0;
    _lastUpdate = now;

    // 1. Onde o Acelerómetro acha que estamos (Força bruta da gravidade)
    final accRoll = atan2(accX, sqrt(accY * accY + accZ * accZ)) * 180 / pi;

    // 2. O quanto o Giroscópio diz que rodámos neste micro-instante
    // Dependendo da montagem, usamos o eixo Y ou Z do giroscópio. Assumindo telemóvel em pé:
    final gyroRate = gyroY; // Rotação lateral (Roll)

    // 3. A Fusão (Filtro Complementar)
    currentRoll = alpha * (currentRoll + gyroRate * dt) + (1.0 - alpha) * accRoll;

    return currentRoll;
  }
}