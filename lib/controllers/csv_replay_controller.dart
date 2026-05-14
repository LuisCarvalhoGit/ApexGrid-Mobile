import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/session_data_point.dart';

// 1. O ESTADO (Simples e funcional)
class ReplayState {
  final List<SessionDataPoint> timeline;
  final double currentIndex;
  final bool isLoading;

  ReplayState({
    this.timeline = const [],
    this.currentIndex = 0,
    this.isLoading = true,
  });

  SessionDataPoint? get currentPoint => 
      timeline.isNotEmpty ? timeline[currentIndex.toInt()] : null;

  ReplayState copyWith({List<SessionDataPoint>? timeline, double? currentIndex, bool? isLoading}) {
    return ReplayState(
      timeline: timeline ?? this.timeline,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Interpolação Linear
  SessionDataPoint? get interpolatedPoint {
    if (timeline.isEmpty) return null;
    
    int indexA = currentIndex.floor();
    int indexB = (indexA + 1).clamp(0, timeline.length - 1);
    double fraction = currentIndex - indexA;

    final pA = timeline[indexA];
    final pB = timeline[indexB];

    return SessionDataPoint(
      timeMs: pA.timeMs, // O tempo podemos manter o do ponto inicial
      // Interpolação da Inclinação
      leanAngle: pA.leanAngle + (pB.leanAngle - pA.leanAngle) * fraction,
      // Interpolação das Coordenadas (O segredo da suavidade no mapa)
      latitude: pA.latitude + (pB.latitude - pA.latitude) * fraction,
      longitude: pA.longitude + (pB.longitude - pA.longitude) * fraction,
      // Interpolação da Velocidade e G-Force
      speedKmh: pA.speedKmh + (pB.speedKmh - pA.speedKmh) * fraction,
      gForceX: pA.gForceX + (pB.gForceX - pA.gForceX) * fraction,
      gForceY: pA.gForceY + (pB.gForceY - pA.gForceY) * fraction,
    );
  }
}

// 2. O CONTROLADOR (StateNotifier é o mais estável para implementações manuais)
class CsvReplayController extends StateNotifier<ReplayState> {
  
  CsvReplayController(String filePath) : super(ReplayState()) {
  _loadCsvData(filePath);
  }

  Future<void> _loadCsvData(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
    state = state.copyWith(isLoading: false);
    return;
    }

    final fileContent = await file.readAsString();
    
    // Processamento nativo: evitamos conflitos com o pacote 'csv'
    final lines = fileContent.split('\n');
    final List<SessionDataPoint> parsedTimeline = [];

    // i = 1 para saltar o cabeçalho
    for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final columns = line.split(',');
    
    if (columns.length >= 7) {
      parsedTimeline.add(SessionDataPoint(
      timeMs: int.tryParse(columns[0]) ?? 0,
      leanAngle: double.tryParse(columns[1]) ?? 0.0,
      gForceX: double.tryParse(columns[2]) ?? 0.0,
      gForceY: double.tryParse(columns[3]) ?? 0.0,
      latitude: double.tryParse(columns[4]) ?? 0.0,
      longitude: double.tryParse(columns[5]) ?? 0.0,
      speedKmh: double.tryParse(columns[6]) ?? 0.0,
      ));
    }
    }

    state = state.copyWith(timeline: parsedTimeline, isLoading: false);
  } catch (e) {
    state = state.copyWith(isLoading: false);
  }
  }

  void scrubTo(double value) {
  if (state.timeline.isEmpty) return;
  final double newIndex = value.toDouble().clamp(0, state.timeline.length - 1);
  state = state.copyWith(currentIndex: newIndex);
  }
}

// 3. O PROVIDER (A forma correta para famílias manuais)
final replayProvider = StateNotifierProvider.autoDispose.family<CsvReplayController, ReplayState, String>((ref, filePath) {
  return CsvReplayController(filePath);
});