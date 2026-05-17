class SessionRecord {
  final int? id;
  final String? title; 
  final DateTime startTime;
  final DateTime endTime;
  final double maxLeanAngle;
  final double maxGForce;
  final String csvFilePath;
  final double totalDistanceKm;
  final double maxSpeedKmh;
  final bool isSynced;

  SessionRecord({
    this.id,
    this.title, 
    required this.startTime,
    required this.endTime,
    required this.maxLeanAngle,
    required this.maxGForce,
    required this.csvFilePath,
    required this.totalDistanceKm,
    required this.maxSpeedKmh,
    this.isSynced = false,
  });

  // Converte a Sessão para um Mapa para o SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title, 
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'maxLeanAngle': maxLeanAngle,
      'maxGForce': maxGForce,
      'csvFilePath': csvFilePath,
      'totalDistanceKm': totalDistanceKm,
      'maxSpeedKmh': maxSpeedKmh,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Cria uma Sessão a partir dos dados do SQLite
  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'],
      title: map['title'], 
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      maxLeanAngle: map['maxLeanAngle'],
      maxGForce: map['maxGForce'],
      csvFilePath: map['csvFilePath'],
      totalDistanceKm: map['totalDistanceKm'] ?? 0.0,
      maxSpeedKmh: map['maxSpeedKmh'] ?? 0.0,
      isSynced: map['isSynced'] == 1,
    );
  }
}