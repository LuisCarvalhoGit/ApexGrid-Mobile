import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// O Estado que a nossa UI vai observar
class LocationState {
  final LatLng? currentPosition;
  final double speedKmh;
  final List<LatLng> route;

  LocationState({this.currentPosition, this.speedKmh = 0.0, this.route = const []});

  LocationState copyWith({LatLng? currentPosition, double? speedKmh, List<LatLng>? route}) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      speedKmh: speedKmh ?? this.speedKmh,
      route: route ?? this.route,
    );
  }
}

class LocationController extends Notifier<LocationState> {
  StreamSubscription<Position>? _positionStream;

  @override
  LocationState build() {
    _initLocation();
    return LocationState();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; // O GPS está desligado

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Configuração de alta precisão desportiva para motos
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // Atualiza a cada 2 metros movidos
    );

    // Começa a escutar o satélite
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);
      
      // Converte a velocidade de m/s para km/h (ignorando valores negativos/ruído)
      final speed = (position.speed > 0.5) ? position.speed * 3.6 : 0.0;
      
      final updatedRoute = List<LatLng>.from(state.route)..add(newPoint);

      state = state.copyWith(
        currentPosition: newPoint,
        speedKmh: speed,
        route: updatedRoute,
      );
    });
  }
}

final locationProvider = NotifierProvider<LocationController, LocationState>(() {
  return LocationController();
});