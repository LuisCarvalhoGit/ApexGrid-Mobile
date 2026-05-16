import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart'; // NOVO IMPORT

import '../controllers/session_controller.dart';
import '../controllers/lean_angle_controller.dart';
import '../models/session_data_point.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final MapController _mapController = MapController();
  bool _isExpanded = true;
  bool _followUser = true;

  LatLng? _lastLocation;
  double _currentHeading = 0.0;

  void _togglePanel(bool expand) {
    setState(() {
      _isExpanded = expand;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveData = ref.watch(liveTelemetryProvider);

    // --- MOTOR DE SEGUIMENTO ---
    ref.listen<SessionDataPoint>(liveTelemetryProvider, (previous, next) {
      if (next.latitude == 0.0 && next.longitude == 0.0) return;

      final newLocation = LatLng(next.latitude, next.longitude);

      if (_lastLocation == null) {
        if (_followUser) _mapController.move(newLocation, 18.0);
        _lastLocation = newLocation;
        return;
      }

      const distanceCalc = Distance();
      final meters = distanceCalc.as(LengthUnit.Meter, _lastLocation!, newLocation);

      if (meters > 1.0) {
        _currentHeading = distanceCalc.bearing(_lastLocation!, newLocation);
        _lastLocation = newLocation; 
      }

      if (_followUser) {
        _mapController.move(newLocation, _mapController.camera.zoom);
        _mapController.rotate(-_currentHeading);
      }
    });

    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (previous != SessionState.recording && next == SessionState.recording) {
        if (_isExpanded) _togglePanel(false);
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final double panelHeight = _isExpanded ? screenHeight * 0.85 : 220.0;

    final initialLocation = (liveData.latitude != 0.0 && liveData.longitude != 0.0) 
        ? LatLng(liveData.latitude, liveData.longitude) 
        : const LatLng(41.2865, -7.7405);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- O MAPA AGORA COM CACHE OFFLINE ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: 18.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.apexgrid.app',
                // A MAGIA DO CACHE ACONTECE AQUI:
                tileProvider: CachedTileProvider(), 
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _lastLocation ?? initialLocation,
                    width: 60,
                    height: 60,
                    child: Transform.rotate(
                      angle: 0,
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.cyanAccent,
                        size: 40,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (!_followUser)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton.small(
                backgroundColor: Colors.cyanAccent,
                onPressed: () {
                  setState(() => _followUser = true);
                  _mapController.rotate(-_currentHeading);
                  if (_lastLocation != null) {
                     _mapController.move(_lastLocation!, 18.0);
                  }
                },
                child: const Icon(Icons.my_location, color: Colors.black),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: 0,
            left: 0,
            right: 0,
            height: panelHeight,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _togglePanel(true);
                } else if (details.primaryVelocity! > 0) {
                  _togglePanel(false);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A).withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: Colors.cyanAccent.withOpacity(0.3), width: 1)),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 5)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: _buildDashboardContent(liveData),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERFACE (INALTERADA) ---
  Widget _buildDashboardContent(SessionDataPoint liveData) {
    if (!_isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          liveData.speedKmh.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0, left: 4),
                          child: Text('KM/H', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildLeanBar(liveData.leanAngle > 0 ? liveData.leanAngle : 0, true)),
                            Container(
                              width: 60,
                              alignment: Alignment.center,
                              child: Text(
                                '${liveData.leanAngle.abs().toStringAsFixed(0)}°',
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                              ),
                            ),
                            Expanded(child: _buildLeanBar(liveData.leanAngle < 0 ? liveData.leanAngle.abs() : 0, false)),
                          ],
                        ),
                        const Text('ÂNGULO DE INCLINAÇÃO', style: TextStyle(color: Colors.white10, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 30),
        const Text('TELEMETRIA ATIVA', style: TextStyle(color: Colors.white10, letterSpacing: 5, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Text(
          liveData.speedKmh.toStringAsFixed(0),
          style: const TextStyle(color: Colors.white, fontSize: 150, fontWeight: FontWeight.w900, height: 0.9, fontFamily: 'monospace'),
        ),
        const Text('KM/H', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            children: [
              Expanded(child: _buildLeanBar(liveData.leanAngle > 0 ? liveData.leanAngle : 0, true)),
              Container(
                width: 130,
                alignment: Alignment.center,
                child: Text(
                  '${liveData.leanAngle.abs().toStringAsFixed(0)}°',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 56, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                ),
              ),
              Expanded(child: _buildLeanBar(liveData.leanAngle < 0 ? liveData.leanAngle.abs() : 0, false)),
            ],
          ),
        ),
        const Text('ÂNGULO DE INCLINAÇÃO', style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        TextButton.icon(
          onPressed: () => ref.read(leanAngleProvider.notifier).setZeroCalibration(),
          icon: const Icon(Icons.refresh, size: 14, color: Colors.white24),
          label: const Text('CALIBRAR SENSORES', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildLeanBar(double angle, bool isLeft) {
    const double maxLean = 50.0;
    final double percentage = (angle / maxLean).clamp(0.0, 1.0);

    return Container(
      height: _isExpanded ? 10 : 6,
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

// --- CLASSE DO INTERCEPTOR DE CACHE ---
// Substitui o motor de rede padrão do mapa por um que grava e lê do armazenamento local.
class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
    );
  }
}