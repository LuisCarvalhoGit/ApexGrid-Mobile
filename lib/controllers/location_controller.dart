import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

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

    // A SOLUÇÃO: Fechar a stream quando o controlador for descartado
    ref.onDispose(() {
      _positionStream?.cancel();
    });

    return LocationState();
  }

  Future<void> _initLocation() async {
    // 1. Verificação crítica: Permissão de Notificações (Android 13+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        // Pede proativamente ao utilizador
        final result = await Permission.notification.request();
        // Se ele recusar, podemos querer avisá-lo na UI (omitido por simplicidade)
        if (!result.isGranted) {
           debugPrint("Aviso: Permissão de notificações negada. O serviço de background pode falhar.");
        }
      }
    }

    // 2. Verificação de GPS (O teu código original)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; 

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // 3. A MÁGICA ACONTECE AQUI: Configurações dinâmicas por Plataforma
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        forceLocationManager: true, 
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "A gravar telemetria da sessão...",
          notificationTitle: "ApexGrid - Telemetria Ativa",
          enableWakeLock: true,
          notificationIcon: AndroidResource(name: 'ic_notification', defType: 'drawable'),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 2,
        pauseLocationUpdatesAutomatically: false, 
        showBackgroundLocationIndicator: true, 
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);
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