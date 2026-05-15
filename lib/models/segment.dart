import 'package:latlong2/latlong.dart';

class ApexSegment {
  final String id;
  final String name;
  final String difficulty; // ex: Técnica, Rápida, Fluida
  final LatLng startPoint;
  final LatLng endPoint;
  final double distanceKmh;

  ApexSegment({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.startPoint,
    required this.endPoint,
    required this.distanceKmh,
  });
}

class SegmentEffort {
  final ApexSegment segment;
  final double entrySpeed;
  final double exitSpeed;
  final double maxLeanAngle;
  final double smoothnessScore; // De 0 a 100 (O verdadeiro troféu)
  final Duration duration;

  SegmentEffort({
    required this.segment,
    required this.entrySpeed,
    required this.exitSpeed,
    required this.maxLeanAngle,
    required this.smoothnessScore,
    required this.duration,
  });
}