import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/history_controller.dart';
import 'session_replay_screen.dart';
import 'session_summary_screen.dart'; 

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agora escutamos o estado global em vez de um Future estático
    final historyAsyncValue = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTÓRICO DE TELEMETRIA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: historyAsyncValue.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('Nenhuma viagem registada ainda.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: sessions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final dateStr = '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}';
              final timeStr = '${session.startTime.hour}h${session.startTime.minute.toString().padLeft(2, '0')}';
              
              // 1. ENVOLVEMOS O CARTÃO NUM GESTURE DETECTOR
              return GestureDetector(
                onTap: () {
                  // 2. A MÁGICA DA NAVEGAÇÃO AQUI: Vai primeiro para o Resumo!
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionSummaryScreen(csvFilePath: session.csvFilePath),
                    ),
                  );
                },
                child: Card(
                  color: const Color(0xFF121212),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.05))),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$dateStr às $timeStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s', style: const TextStyle(color: Colors.amberAccent)),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniMetric('Pico Força-G', '${session.maxGForce.toStringAsFixed(2)} G', Colors.cyanAccent),
                            _buildMiniMetric('Max Inclinação', '${session.maxLeanAngle.toStringAsFixed(0)}°', Colors.greenAccent),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Share.shareXFiles([XFile(session.csvFilePath)], text: 'Telemetria $dateStr'),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('EXPORTAR DADOS (.CSV)'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.amberAccent, side: const BorderSide(color: Colors.amberAccent)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
        error: (error, stack) => Center(child: Text('Erro: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}