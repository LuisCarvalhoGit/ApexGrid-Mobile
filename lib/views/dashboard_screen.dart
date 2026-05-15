import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:math' as math;

import '../controllers/session_controller.dart';
import '../models/session_data_point.dart';

// NOTA: Se já tiveres um provider que exponha os dados do teu SensorService em tempo real,
// podes apagar este e usar o teu.


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Estado da gravação (para mudar a UI se estiver a gravar)
    final sessionState = ref.watch(sessionControllerProvider);
    final isRecording = sessionState == SessionState.recording;

    // Dados em tempo real dos sensores
    final liveData = ref.watch(liveTelemetryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. CABEÇALHO E STATUS DE GRAVAÇÃO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('APEX COCKPIT', style: TextStyle(color: Colors.white54, letterSpacing: 3, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isRecording ? Colors.redAccent.withOpacity(0.2) : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isRecording ? Colors.redAccent : Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Icon(isRecording ? Icons.fiber_manual_record : Icons.pause, 
                             color: isRecording ? Colors.redAccent : Colors.white54, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          isRecording ? 'A GRAVAR (50Hz)' : 'STANDBY', 
                          style: TextStyle(color: isRecording ? Colors.redAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  )
                ],
              ),
              
              const Spacer(),

              // 2. INDICADOR DE INCLINAÇÃO (HORIZONTE ARTIFICIAL)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Fundo do arco
                    const Icon(Icons.speed, size: 200, color: Colors.white12),
                    
                    // Mota que roda com o Lean Angle
                    Transform.rotate(
                      angle: liveData.leanAngle * (math.pi / 180), // Converte graus para radianos
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.two_wheeler, size: 80, color: Colors.amberAccent),
                          Container(width: 120, height: 2, color: Colors.amberAccent), // Linha de horizonte da mota
                        ],
                      ),
                    ),
                    
                    // Texto do grau de inclinação
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          '${liveData.leanAngle.abs().toStringAsFixed(1)}°',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 3. VELOCÍMETRO GIGANTE
              Column(
                children: [
                  Text(
                    liveData.speedKmh.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 120, fontWeight: FontWeight.w900, height: 1.0, fontFamily: 'monospace'),
                  ),
                  const Text('KM/H', style: TextStyle(color: Colors.cyanAccent, fontSize: 20, letterSpacing: 5, fontWeight: FontWeight.bold)),
                ],
              ),

              const Spacer(),

              // 4. BARRAS DE FORÇA G (TRAVAGEM E ACELERAÇÃO)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGForceGauge('TRAVAGEM (G)', liveData.gForceY < 0 ? liveData.gForceY.abs() : 0.0, Colors.redAccent),
                  _buildGForceGauge('ACELERAÇÃO (G)', liveData.gForceY > 0 ? liveData.gForceY : 0.0, Colors.greenAccent),
                ],
              ),
              
              // Espaço para a barra de navegação e o botão de gravar
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Widget personalizado para mostrar barras de Força G
  Widget _buildGForceGauge(String label, double value, Color activeColor) {
    // Vamos assumir que 1.5G é uma travagem/aceleração fortíssima na Tracer 7
    final double fillPercentage = (value / 1.5).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(value.toStringAsFixed(2), style: TextStyle(color: activeColor, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fillPercentage,
            child: Container(
              decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}