class SessionRecord {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final double maxLeanAngle;
  final double maxGForce;
  final String csvFilePath;

  SessionRecord({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.maxLeanAngle,
    required this.maxGForce,
    required this.csvFilePath,
  });

  Duration get duration => endTime.difference(startTime);

  // Converte o Objeto para um Mapa (necessário para guardar no SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'maxLeanAngle': maxLeanAngle,
      'maxGForce': maxGForce,
      'csvFilePath': csvFilePath,
    };
  }

  // Constrói o Objeto a partir de um Mapa (necessário quando lemos do SQLite)
  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      maxLeanAngle: map['maxLeanAngle'] as double,
      maxGForce: map['maxGForce'] as double,
      csvFilePath: map['csvFilePath'] as String,
    );
  }
}