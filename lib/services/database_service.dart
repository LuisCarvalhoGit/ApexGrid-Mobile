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
      version: 2, // Aumenta a versão para 2 se já tiveres a app instalada
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,           --- NOVO: Coluna para o título
            startTime TEXT,
            endTime TEXT,
            maxLeanAngle REAL,
            maxGForce REAL,
            csvFilePath TEXT
          )
        ''');
      },
      // Se a base de dados já existir, isto força a recriar a tabela com a nova coluna.
      // NOTA: Para um projeto final, usaríamos scripts de migração, mas para o MVP isto é o mais prático!
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE sessions ADD COLUMN title TEXT');
        }
      }
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

  // Elimina uma sessão específica pelo ID
  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atualiza apenas o título de uma sessão
  Future<void> updateSessionTitle(int id, String newTitle) async {
    final db = await database;
    await db.update(
      'sessions',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}