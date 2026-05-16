import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/session_controller.dart';
import '../../models/session_data_point.dart';

class TelemetryMap extends ConsumerStatefulWidget {
  const TelemetryMap({super.key});

  @override
  ConsumerState<TelemetryMap> createState() => _TelemetryMapState();
}

class _TelemetryMapState extends ConsumerState<TelemetryMap> {
  final MapController _mapController = MapController();
  bool _followUser = true;
  LatLng? _lastLocation;
  double _currentHeading = 0.0;

  @override
  Widget build(BuildContext context) {
    final liveData = ref.watch(liveTelemetryProvider);

    // Motor de Seguimento
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

    final initialLocation = (liveData.latitude != 0.0 && liveData.longitude != 0.0)
        ? LatLng(liveData.latitude, liveData.longitude)
        : const LatLng(41.2865, -7.7405);

    return Stack(
      children: [
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
                    child: const Icon(Icons.navigation, color: Colors.cyanAccent, size: 40, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
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
                if (_lastLocation != null) _mapController.move(_lastLocation!, 18.0);
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
      ],
    );
  }
}

class CachedTileProvider extends TileProvider {
  CachedTileProvider();
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(getTileUrl(coordinates, options));
  }
}