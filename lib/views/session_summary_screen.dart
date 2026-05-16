import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/summary_controller.dart';
import '../models/segment.dart';
import 'session_replay_screen.dart'; // <-- NOVO IMPORT ADICIONADO AQUI

class SessionSummaryScreen extends ConsumerWidget {
  final String csvFilePath;

  const SessionSummaryScreen({super.key, required this.csvFilePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sessionSummaryProvider(csvFilePath));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('RESUMO DA RIDE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amberAccent),
              SizedBox(height: 16),
              Text('A ANALISAR SEGMENTOS...', style: TextStyle(color: Colors.amberAccent, letterSpacing: 2)),
            ],
          )
        ),
        error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.red))),
        data: (data) => CustomScrollView(
          slivers: [
            // 1. O MAPA DA ROTA GERAL
            SliverToBoxAdapter(
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12, width: 2)),
                ),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: data.route.isNotEmpty ? data.route[data.route.length ~/ 2] : const LatLng(0, 0),
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: data.route,
                          strokeWidth: 4.0,
                          color: Colors.amberAccent.withValues(alpha:0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. ESTATÍSTICAS GERAIS DA VIAGEM
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGlobalStat('INCLINAÇÃO MÁX', '${data.maxLeanAngle.toStringAsFixed(1)}°', Colors.greenAccent),
                    _buildGlobalStat('VELOCIDADE MÁX', '${data.topSpeed.toStringAsFixed(0)} km/h', Colors.cyanAccent),
                    _buildGlobalStat('DURAÇÃO', '${data.totalDuration.inMinutes} min', Colors.white),
                  ],
                ),
              ),
            ),

            // 3. O CORAÇÃO DA APP: OS APEX SEGMENTS
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('SEGMENTOS CONQUISTADOS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),

            if (data.efforts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('Nenhum segmento conhecido nesta rota.', style: TextStyle(color: Colors.white24)),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final effort = data.efforts[index];
                    return _buildSegmentCard(effort);
                  },
                  childCount: data.efforts.length,
                ),
              ),
              
            // 4. O BOTÃO DE TELEMETRIA (ESTAVA A FALTAR AQUI)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Colors.cyanAccent, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('VER TELEMETRIA DETALHADA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionReplayScreen(csvFilePath: csvFilePath),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSegmentCard(SegmentEffort effort) {
    Color scoreColor;
    if (effort.smoothnessScore >= 90) {
      scoreColor = Colors.amberAccent; // Ouro
     } 
    else if (effort.smoothnessScore >= 75) {
      scoreColor = Colors.grey[300]!; // Prata
    }
    else {
      scoreColor = Colors.deepOrangeAccent; // Bronze/Aviso
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(effort.segment.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                child: Text(effort.segment.difficulty, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SMOOTHNESS SCORE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(effort.smoothnessScore.toStringAsFixed(1), style: TextStyle(color: scoreColor, fontSize: 32, fontWeight: FontWeight.w900)),
                      const Text(' / 100', style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Entrada: ${effort.entrySpeed.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  Text('Saída: ${effort.exitSpeed.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  Text('Inclinação: ${effort.maxLeanAngle.toStringAsFixed(1)}°', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontFamily: 'monospace')),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}