import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/session_data_point.dart';
import '../models/segment.dart';
import '../services/segment_engine.dart';

class SessionSummaryData {
  final List<LatLng> route;
  final List<SegmentEffort> efforts;
  final double maxLeanAngle;
  final double topSpeed;
  final Duration totalDuration;

  SessionSummaryData({
    required this.route,
    required this.efforts,
    required this.maxLeanAngle,
    required this.topSpeed,
    required this.totalDuration,
  });
}

final sessionSummaryProvider = FutureProvider.family<SessionSummaryData, String>((ref, filePath) async {
  final file = File(filePath);
  if (!await file.exists()) throw Exception('Ficheiro não encontrado');

  final lines = await file.readAsLines();
  final List<SessionDataPoint> timeline = [];
  double maxLean = 0;
  double topSpeed = 0;

  // Lemos o CSV (ignorando o cabeçalho)
  for (int i = 1; i < lines.length; i++) {
    final cols = lines[i].split(',');
    if (cols.length >= 7) {
      final point = SessionDataPoint(
        timeMs: int.tryParse(cols[0]) ?? 0,
        leanAngle: double.tryParse(cols[1]) ?? 0.0,
        gForceX: double.tryParse(cols[2]) ?? 0.0,
        gForceY: double.tryParse(cols[3]) ?? 0.0,
        latitude: double.tryParse(cols[4]) ?? 0.0,
        longitude: double.tryParse(cols[5]) ?? 0.0,
        speedKmh: double.tryParse(cols[6]) ?? 0.0,
      );
      timeline.add(point);
      if (point.leanAngle.abs() > maxLean) maxLean = point.leanAngle.abs();
      if (point.speedKmh > topSpeed) topSpeed = point.speedKmh;
    }
  }

  // Extraímos a rota para o mapa
  final route = timeline
      .where((p) => p.latitude != 0)
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

  // O Motor entra em ação para descobrir se bateste recordes
  final efforts = SegmentEngine.analyzeSession(timeline);
  final duration = timeline.isNotEmpty 
      ? Duration(milliseconds: timeline.last.timeMs - timeline.first.timeMs)
      : Duration.zero;

  return SessionSummaryData(
    route: route,
    efforts: efforts,
    maxLeanAngle: maxLean,
    topSpeed: topSpeed,
    totalDuration: duration,
  );
});