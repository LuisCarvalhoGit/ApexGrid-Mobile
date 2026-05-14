import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart'; // Onde está o filteredTelemetryStreamProvider
import '../controllers/lean_angle_controller.dart';
import 'widgets/realtime_chart.dart';
import 'widgets/g_force_bar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuta os dados puros dos sensores em tempo real
    final telemetryStream = ref.watch(filteredTelemetryStreamProvider);
    
    // 2. Escuta o ângulo de inclinação calibrado diretamente do cérebro
    final currentLeanAngle = ref.watch(leanAngleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('APEXGRID RACING', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // O ícone do histórico já não está aqui, foi para a MainNavigation
      ),
      body: SafeArea(
        // Usamos o StreamBuilder clássico em vez do .when()
        child: StreamBuilder(
          stream: telemetryStream,
          builder: (context, snapshot) {
            // Estado de Erro
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
            }
            
            // Estado de Carregamento (à espera do primeiro ponto de dados)
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.amberAccent));
            }

            // Temos dados!
            final data = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // SECÇÃO 1: O Gráfico Vivo no Topo
                  const Expanded(
                    flex: 3, 
                    child: RealtimeChart()
                  ),
                  const SizedBox(height: 24),
                  
                  // SECÇÃO 2: O Ângulo de Inclinação (Ao centro)
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('LEAN ANGLE', style: TextStyle(color: Colors.white54, letterSpacing: 3)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLeanAngle.abs().toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 96, 
                                fontWeight: FontWeight.w900, 
                                height: 1.0, 
                                color: Colors.amberAccent
                              ),
                            ),
                            const Text('°', style: TextStyle(fontSize: 40, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          currentLeanAngle > 1 ? 'LEFT (ESQUERDA)' : currentLeanAngle < -1 ? 'RIGHT (DIREITA)' : 'CENTER',
                          style: TextStyle(
                            color: currentLeanAngle.abs() > 1 ? Colors.cyanAccent : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // SECÇÃO 3: Barras de Força-G (Livres de Overflow)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GForceBar(
                            label: 'ACELERAÇÃO / TRAVAGEM',
                            value: data.y, // Acelerar (verde) / Travar (vermelho)
                            positiveColor: Colors.greenAccent,
                            negativeColor: Colors.redAccent,
                          ),
                          const SizedBox(height: 24),
                          GForceBar(
                            label: 'FORÇA LATERAL',
                            value: data.x, // Força nas curvas (Ciano)
                            positiveColor: Colors.cyanAccent, 
                            negativeColor: Colors.cyanAccent, 
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Espaço invisível no fundo para o novo botão global não tapar os dados
                  const SizedBox(height: 100), 
                ],
              ),
            );
          },
        ),
      ),
      // O botão de "Iniciar Sessão" já não está aqui, foi para a MainNavigation
    );
  }
}

// (Assumo que tenhas o teu widget GForceBar aqui ou num ficheiro à parte)