import 'package:latlong2/latlong.dart';
import '../models/session_data_point.dart';
import '../models/segment.dart';

class SegmentEngine {
  // Uma base de dados simulada de segmentos épicos para o teu MVP
  // No futuro, isto virá do teu backend (Firebase/PostgreSQL)
  static final List<ApexSegment> _knownSegments = [
    ApexSegment(
      id: 'seg_marao_01',
      name: 'N15 - Curvas do Marão (Subida)',
      difficulty: 'Técnica',
      startPoint: const LatLng(41.265, -7.881), // Coordenadas exemplo no sopé
      endPoint: const LatLng(41.258, -7.925),   // Coordenadas exemplo no topo
      distanceKmh: 4.2,
    ),
    ApexSegment(
      id: 'seg_sabrosa_02',
      name: 'N322 - Ganchos de Sabrosa',
      difficulty: 'Fluida',
      startPoint: const LatLng(41.282, -7.653),
      endPoint: const LatLng(41.267, -7.611),
      distanceKmh: 6.5,
    ),
  ];

  static const double _detectionRadiusMeters = 50.0;

  // Função principal chamada no fim de uma Ride pelo SummaryController
  static List<SegmentEffort> analyzeSession(List<SessionDataPoint> timeline) {
    List<SegmentEffort> efforts = [];
    if (timeline.isEmpty) return efforts;

    for (var segment in _knownSegments) {
      int? startIndex = _findClosestPointIndex(timeline, segment.startPoint);
      int? endIndex = _findClosestPointIndex(timeline, segment.endPoint);

      // Verificamos se o piloto passou pelo início e DEPOIS pelo fim do segmento
      if (startIndex != null && endIndex != null && endIndex > startIndex) {
        
        final segmentData = timeline.sublist(startIndex, endIndex + 1);
        
        efforts.add(SegmentEffort(
          segment: segment,
          entrySpeed: segmentData.first.speedKmh,
          exitSpeed: segmentData.last.speedKmh,
          maxLeanAngle: _calculateMaxLean(segmentData),
          smoothnessScore: _calculateSmoothness(segmentData),
          duration: Duration(milliseconds: segmentData.last.timeMs - segmentData.first.timeMs),
        ));
      }
    }
    return efforts;
  }

  // Encontra se a mota passou perto do ponto de controlo (Check-in do Segmento)
  static int? _findClosestPointIndex(List<SessionDataPoint> timeline, LatLng target) {
    const distance = Distance();
    for (int i = 0; i < timeline.length; i++) {
      if (timeline[i].latitude != 0) {
        final point = LatLng(timeline[i].latitude, timeline[i].longitude);
        final dist = distance.as(LengthUnit.Meter, target, point);
        
        // Se passou a menos de 50 metros do ponto ideal, regista a entrada/saída
        if (dist <= _detectionRadiusMeters) return i;
      }
    }
    return null;
  }

  // Descobre a inclinação máxima atingida DENTRO deste segmento
  static double _calculateMaxLean(List<SessionDataPoint> data) {
    double maxAngle = 0;
    for (var p in data) {
      if (p.leanAngle.abs() > maxAngle) maxAngle = p.leanAngle.abs();
    }
    return maxAngle;
  }

  // O ALGORITMO DE FLUIDEZ (O teu "Gold Standard" de avaliação)
  static double _calculateSmoothness(List<SessionDataPoint> data) {
    if (data.length < 2) return 0.0;

    double penalty = 0.0;
    
    for (int i = 1; i < data.length; i++) {
      // 1. Penalização por travagens/acelerações bruscas a meio da curva (Força G no eixo Y)
      double gForceDelta = (data[i].gForceY - data[i-1].gForceY).abs();
      if (gForceDelta > 0.4) penalty += (gForceDelta * 5); // Multiplicador para penalizar solavancos

      // 2. Penalização por correções nervosas de inclinação (tremer o guiador)
      double leanDelta = (data[i].leanAngle - data[i-1].leanAngle).abs();
      if (leanDelta > 2.0) penalty += leanDelta; 
    }

    // Normaliza para uma pontuação máxima de 100
    double rawScore = 100.0 - penalty;
    return rawScore.clamp(0.0, 100.0);
  }
}