import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_record.dart';
import '../services/database_service.dart';

// Este provider vai ler a base de dados e manter a lista atualizada
final historyProvider = FutureProvider<List<SessionRecord>>((ref) async {
  return await DatabaseService().getAllSessions();
});