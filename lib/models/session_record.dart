class SessionRecord {
  final int? id;
  final String? title; 
  final DateTime startTime;
  final DateTime endTime;
  final double maxLeanAngle;
  final double maxGForce;
  final String csvFilePath;

  SessionRecord({
    this.id,
    this.title, 
    required this.startTime,
    required this.endTime,
    required this.maxLeanAngle,
    required this.maxGForce,
    required this.csvFilePath,
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
    );
  }
}