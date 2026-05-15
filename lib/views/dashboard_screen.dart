import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/session_controller.dart';
import '../controllers/lean_angle_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveData = ref.watch(liveTelemetryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text('TELEMETRIA ATIVA', style: TextStyle(color: Colors.white10, letterSpacing: 5, fontSize: 10, fontWeight: FontWeight.bold)),
            
            const Spacer(),

            // VELOCIDADE GIGANTE
            Column(
              children: [
                Text(
                  liveData.speedKmh.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.white, fontSize: 150, fontWeight: FontWeight.w900, height: 0.9, fontFamily: 'monospace'),
                ),
                const Text('KM/H', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 12, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 80),

            // INDICADOR DE INCLINAÇÃO CORRIGIDO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                children: [
                  // Lado Esquerdo (Agora lê valores Positivos para bater certo com o giroscópio)
                  Expanded(child: _buildLeanBar(liveData.leanAngle > 0 ? liveData.leanAngle : 0, true)),
                  
                  // Caixa do ângulo aumentada para não quebrar a linha
                  Container(
                    width: 130, // Aumentado de 100 para 130
                    alignment: Alignment.center,
                    child: Text(
                      '${liveData.leanAngle.abs().toStringAsFixed(0)}°',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 56, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                      maxLines: 1, // Força a ficar na mesma linha
                    ),
                  ),
                  
                  // Lado Direito (Lê valores Negativos)
                  Expanded(child: _buildLeanBar(liveData.leanAngle < 0 ? liveData.leanAngle.abs() : 0, false)),
                ],
              ),
            ),
            const Text('ÂNGULO DE INCLINAÇÃO', style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),

            const Spacer(),

            // BOTÃO DE CALIBRAGEM
            TextButton.icon(
              onPressed: () => ref.read(leanAngleProvider.notifier).setZeroCalibration(),
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white24),
              label: const Text('CALIBRAR SENSORES', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              ),
            ),
            
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  Widget _buildLeanBar(double angle, bool isLeft) {
    const double maxLean = 50.0;
    final double percentage = (angle / maxLean).clamp(0.0, 1.0);

    return Container(
      height: 10,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(2)),
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amberAccent,
            boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.3), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}