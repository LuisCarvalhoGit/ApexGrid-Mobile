import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/csv_replay_controller.dart';
import '../models/session_data_point.dart';

class SessionReplayScreen extends ConsumerStatefulWidget {
  final String csvFilePath;

  const SessionReplayScreen({super.key, required this.csvFilePath});

  @override
  ConsumerState<SessionReplayScreen> createState() => _SessionReplayScreenState();
}

class _SessionReplayScreenState extends ConsumerState<SessionReplayScreen> {
  final MapController _mapController = MapController();

  // Função utilitária para converter a linha do tempo em coordenadas do FlutterMap
  List<LatLng> _extractRoute(List<SessionDataPoint> timeline) {
    return timeline
        .where((point) => point.latitude != 0.0 && point.longitude != 0.0) // Filtra pontos de GPS inválidos
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Escutamos o estado do replay, passando o caminho do ficheiro que recebemos
    final replayState = ref.watch(replayProvider(widget.csvFilePath));
    final controller = ref.read(replayProvider(widget.csvFilePath).notifier);

    if (replayState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
      );
    }

    if (replayState.timeline.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ERRO DE REPLAY'), backgroundColor: Colors.transparent),
        body: const Center(child: Text('Ficheiro vazio ou corrompido.', style: TextStyle(color: Colors.white54))),
      );
    }

    final route = _extractRoute(replayState.timeline);
    final currentPoint = replayState.currentPoint!;
    final currentLatLng = LatLng(currentPoint.latitude, currentPoint.longitude);

    // Tentamos animar a câmara se houver movimento significativo do GPS, mas de forma suave
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentLatLng.latitude != 0 && currentLatLng.longitude != 0) {
        _mapController.move(currentLatLng, 18.0); 
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ANÁLISE DE SESSÃO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. O Mapa (Metade Superior)
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: route.isNotEmpty ? route.first : const LatLng(0, 0),
                initialZoom: 18.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.apexgrid.app',
                ),
                // A linha do trajeto percorrido
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 6.0,
                      color: Colors.cyanAccent.withOpacity(0.5),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                // O indicador do instante selecionado (O Alvo)
                if (currentLatLng.latitude != 0)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLatLng,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amberAccent, width: 2),
                          ),
                          child: const Center(child: Icon(Icons.gps_fixed, size: 24, color: Colors.amberAccent)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 2. O Painel de Telemetria do Instante Selecionado
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              border: Border(top: BorderSide(color: Colors.amberAccent.withOpacity(0.5), width: 2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildReplayMetric('INCLINAÇÃO', '${currentPoint.leanAngle.toStringAsFixed(0)}°', Colors.greenAccent),
                    _buildReplayMetric('VELOCIDADE', '${currentPoint.speedKmh.toStringAsFixed(0)} km/h', Colors.amberAccent),
                    _buildReplayMetric('ACEL/TRAV', '${currentPoint.gForceY.toStringAsFixed(2)}G', Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 3. A Linha do Tempo (O Slider Mágico)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.amberAccent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.amberAccent,
                    overlayColor: Colors.amberAccent.withOpacity(0.2),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    min: 0,
                    max: (replayState.timeline.length - 1).toDouble(),
                    value: replayState.currentIndex.toDouble(),
                    onChanged: (value) {
                      // Movemos o dedo e pedimos ao controller para recalcular
                      controller.scrubTo(value);
                    },
                  ),
                ),
                Text(
                  'Tempo da Viagem: ${(currentPoint.timeMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplayMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}