import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import 'services/sensor_service.dart';
import 'services/database_service.dart';
import 'models/telemetry_point.dart';
import 'utils/low_pass_filter.dart';

import 'views/main_navigation.dart';

/// 1. Provider da Stream bruta (isolamento do hardware físico)
final rawAccelerometerStreamProvider = Provider<Stream<UserAccelerometerEvent>>((ref) {
  // gameInterval = ~50Hz, ideal para captar a física da mota com precisão
  return userAccelerometerEventStream(samplingPeriod: SensorInterval.gameInterval);
});

/// 2. Provider do Serviço com injeção de dependência
final sensorServiceProvider = Provider<SensorService>((ref) {
  final rawStream = ref.watch(rawAccelerometerStreamProvider);
  return SensorService(rawStream);
});

/// 3. Provider reativo (StreamProvider) que a UI irá escutar
final telemetryProvider = StreamProvider<TelemetryPoint>((ref) {
  final service = ref.watch(sensorServiceProvider);
  return service.telemetryStream;
});

/// 4. Provider da Stream Filtrada Pura (Para Lógica de Negócio / Gravação)
final filteredTelemetryStreamProvider = Provider<Stream<TelemetryPoint>>((ref) {
  final rawStream = ref.watch(sensorServiceProvider).telemetryStream;
  final filter = LowPassFilter(0.2); // Fator de suavização
  
  return rawStream.map((rawPoint) => filter.apply(rawPoint));
});

/// 5. Provider Reativo para a UI (Converte Stream em AsyncValue)
final filteredTelemetryProvider = StreamProvider<TelemetryPoint>((ref) {
  // A UI apenas observa a stream pura e transforma-a em AsyncData/AsyncLoading
  return ref.watch(filteredTelemetryStreamProvider);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. NOVO: Força o ecrã a manter-se ligado enquanto a app estiver em 1º plano
  WakelockPlus.enable();

  await DatabaseService().database;

  runApp(
    const ProviderScope(
      child: ApexGridApp(),
    ),
  );
}

class ApexGridApp extends StatelessWidget {
  const ApexGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApexGrid MVP',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // Preto puro OLED
        colorScheme: const ColorScheme.dark(
          primary: Colors.amberAccent,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF121212), // Cinza muito escuro para os cartões
        ),
        fontFamily: 'RobotoMono', // Ou importar a fonte 'Inter' para um look hiper-moderno
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}