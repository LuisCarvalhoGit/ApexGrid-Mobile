import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/history_controller.dart';
import '../services/database_service.dart';
import 'session_summary_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('HISTÓRICO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
      ),
      body: historyAsync.when(
        data: (sessions) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              color: const Color(0xFF121212),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  session.title?.toUpperCase() ?? 'SESSÃO SEM TÍTULO',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  '${session.startTime.day}/${session.startTime.month} • ${session.maxLeanAngle.toStringAsFixed(1)}° MAX',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão para Renomear
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white24, size: 20),
                      onPressed: () => _showRenameDialog(context, ref, session.id!, session.title ?? ''),
                    ),
                    // Botão de Eliminar (Caixote do Lixo)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDelete(context, ref, session.id!),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => SessionSummaryScreen(csvFilePath: session.csvFilePath)),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, int id, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('DAR TÍTULO À SESSÃO', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Ex: Curvas do Marão",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              await DatabaseService().updateSessionTitle(id, controller.text);
              ref.invalidate(historyProvider);
              Navigator.pop(ctx);
            },
            child: const Text('GUARDAR', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('ELIMINAR SESSÃO?', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('VOLTAR', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DatabaseService().deleteSession(id);
              ref.invalidate(historyProvider);
              Navigator.pop(ctx);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}