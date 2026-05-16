import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/csv_replay_controller.dart';
import '../services/map_matching_service.dart'; // Garante que este ficheiro existe

class SessionReplayScreen extends ConsumerStatefulWidget {
  final String csvFilePath;

  const SessionReplayScreen({super.key, required this.csvFilePath});

  @override
  ConsumerState<SessionReplayScreen> createState() => _SessionReplayScreenState();
}

class _SessionReplayScreenState extends ConsumerState<SessionReplayScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _snappedRoute = [];
  bool _isMatching = true;
  bool _followMarker = true; // Permite ao utilizador soltar a câmara para explorar o mapa

  @override
  void initState() {
    super.initState();
    // Iniciamos o processamento da rota assim que o widget é criado
    _initializeRoute();
  }

  Future<void> _initializeRoute() async {
    // Pequeno delay para garantir que o provider carregou o CSV
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final timeline = ref.read(replayProvider(widget.csvFilePath)).timeline;
    
    if (timeline.isNotEmpty) {
      // Chamada ao serviço que "cola" os pontos à estrada real
      final matched = await MapMatchingService.snapToRoads(timeline);
      
      if (mounted) {
        setState(() {
          _snappedRoute = matched;
          _isMatching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final replayState = ref.watch(replayProvider(widget.csvFilePath));
    final controller = ref.read(replayProvider(widget.csvFilePath).notifier);

    // Mostra loading enquanto processa o CSV ou o Map Matching
    if (replayState.isLoading || _isMatching) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amberAccent),
              SizedBox(height: 16),
              Text('A AJUSTAR TRAJETO À ESTRADA...', 
                style: TextStyle(color: Colors.amberAccent, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // Ponto interpolado para fluidez máxima
    final currentPoint = replayState.interpolatedPoint!;
    final currentLatLng = LatLng(currentPoint.latitude, currentPoint.longitude);

    // Gestão da Câmara: Só move se o "Follow" estiver ativo
    if (_followMarker && currentLatLng.latitude != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentLatLng, _mapController.camera.zoom);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ANÁLISE DE SESSÃO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Botão para travar/destravar a câmara no marcador
          IconButton(
            icon: Icon(_followMarker ? Icons.gps_fixed : Icons.gps_not_fixed, 
                       color: _followMarker ? Colors.amberAccent : Colors.white24),
            onPressed: () => setState(() => _followMarker = !_followMarker),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. O MAPA COM TRAJETO REAL
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _snappedRoute.isNotEmpty ? _snappedRoute.first : const LatLng(0, 0),
                initialZoom: 17.0,
                // Se o utilizador arrastar o mapa, desativa o auto-center automaticamente
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && _followMarker) {
                    setState(() => _followMarker = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.apexgrid.app',
                ),
                // Linha que segue a estrada (Snap to Road)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _snappedRoute,
                      strokeWidth: 5.0,
                      color: Colors.cyanAccent.withValues(alpha:0.6),
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
                // Marcador Fluido e Rotativo
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLatLng,
                      width: 60,
                      height: 60,
                      child: Transform.rotate(
                        angle: currentPoint.leanAngle * (3.14159 / 180), // Inclina com a mota
                        child: const Icon(Icons.motorcycle, size: 36, color: Colors.amberAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. PAINEL DE TELEMETRIA
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              border: Border(top: BorderSide(color: Colors.amberAccent.withValues(alpha:0.3), width: 2)),
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
                const SizedBox(height: 20),
                
                // 3. SLIDER DE ALTA PRECISÃO
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.amberAccent,
                    thumbColor: Colors.amberAccent,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    min: 0,
                    max: (replayState.timeline.length - 1).toDouble(),
                    value: replayState.currentIndex.clamp(0, (replayState.timeline.length - 1).toDouble()),
                    onChanged: (value) => controller.scrubTo(value),
                  ),
                ),
                Text(
                  'Tempo: ${(currentPoint.timeMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Colors.white24, fontSize: 11, fontFamily: 'monospace'),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}