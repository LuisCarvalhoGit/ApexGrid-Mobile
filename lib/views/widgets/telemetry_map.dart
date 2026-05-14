import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/location_controller.dart';

class TelemetryMap extends ConsumerStatefulWidget {
  const TelemetryMap({super.key});

  @override
  ConsumerState<TelemetryMap> createState() => _TelemetryMapState();
}

class _TelemetryMapState extends ConsumerState<TelemetryMap> {
  // O "Volante" do mapa que nos permite controlar a câmara
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);

    if (locationState.currentPosition == null) {
      return Container(
        decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(24)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.satellite_alt, color: Colors.amberAccent, size: 32),
              SizedBox(height: 8),
              Text('A PROCURAR SATÉLITES...', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final currentPos = locationState.currentPosition!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController, // Ligar o volante ao mapa
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 17.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all), // Mapa livre!
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.example.apexgrid',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: locationState.route,
                    strokeWidth: 5.0,
                    color: Colors.cyanAccent.withOpacity(0.8),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.navigation, color: Colors.amberAccent, size: 32),
                  ),
                ],
              ),
            ],
          ),
          
          // O NOVO BOTÃO DE RECENTRAR (Alvo de GPS)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter_map',
              backgroundColor: Colors.black.withOpacity(0.7),
              foregroundColor: Colors.amberAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
              ),
              onPressed: () {
                // Comando para a câmara "voar" de volta para a posição atual da mota
                _mapController.move(currentPos, 17.5);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          
          // Velocímetro (mantém-se igual)
          Positioned(
            bottom: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    locationState.speedKmh.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 4),
                  const Text('KM/H', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}