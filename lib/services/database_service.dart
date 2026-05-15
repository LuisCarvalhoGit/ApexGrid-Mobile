import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session_record.dart';

class DatabaseService {
  // Padrão Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Encontra o caminho seguro do dispositivo para gravar a base de dados
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'apexgrid_telemetry.db');

    // Abre (ou cria) a base de dados
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Cria a tabela com linguagem SQL pura (Gold Standard para performance relacional)
        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime TEXT NOT NULL,
            endTime TEXT NOT NULL,
            maxLeanAngle REAL NOT NULL,
            maxGForce REAL NOT NULL,
            csvFilePath TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Método para guardar uma nova viagem
  Future<int> insertSession(SessionRecord session) async {
    final db = await database;
    return await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para ler todo o histórico de viagens, ordenado da mais recente para a mais antiga
  Future<List<SessionRecord>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'startTime DESC',
    );

    return List.generate(maps.length, (i) => SessionRecord.fromMap(maps[i]));
  }

  Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete('sessions'); // Apaga todos os registos da tabela
  }
}