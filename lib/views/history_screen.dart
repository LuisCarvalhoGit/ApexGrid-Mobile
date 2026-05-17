import 'dart:io';
import 'package:apexgrid/models/session_record.dart';
import 'package:apexgrid/services/telemetry_sync_service.dart';
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
                  '${session.startTime.day}/${session.startTime.month} • ${session.totalDistanceKm.toStringAsFixed(1)} km • ${session.maxLeanAngle.toStringAsFixed(1)}° MAX',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- A NUVEM INTERATIVA ---
                    session.isSynced
                        ? const Icon(Icons.cloud_done, color: Colors.green, size: 20)
                        : IconButton(
                            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.amberAccent, size: 20),
                            tooltip: 'Sincronizar agora',
                            onPressed: () => _retrySync(context, ref, session),
                          ),
                    const SizedBox(width: 4),
                    
                    // Botão para Renomear
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white24, size: 20),
                      onPressed: () => _showRenameDialog(context, ref, session.id!, session.title ?? ''),
                    ),
                    // Botão de Eliminar
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
              if (!context.mounted) return;
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
              if (!context.mounted) return;
              ref.invalidate(historyProvider);
              Navigator.pop(ctx);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE RE-SINCRONIZAÇÃO ---
  void _retrySync(BuildContext context, WidgetRef ref, SessionRecord session) async {
    // Mostra um aviso ao utilizador de que está a tentar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A tentar sincronizar viagem...'), duration: Duration(seconds: 2)),
    );

    final syncService = TelemetrySyncService();
    
    // Dispara o Upload
    final success = await syncService.uploadRide(
      userId: '3fa85f64-5717-4562-b3fc-2c963f66afa6', // O ID fixo de teste
      motorcycleModel: 'Yamaha Tracer 7', 
      startTime: session.startTime,
      endTime: session.endTime,
      maxLeanAngleDegrees: session.maxLeanAngle,
      maxGForce: session.maxGForce,
      totalDistanceKm: session.totalDistanceKm,
      maxSpeedKmh: session.maxSpeedKmh,
      csvFile: File(session.csvFilePath),
    );

    // Valida o resultado e atualiza a UI
    if (success) {
      await DatabaseService().markAsSynced(session.id!);
      if (!context.mounted) return;
      
      ref.invalidate(historyProvider); // Atualiza o ecrã instantaneamente
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Sincronização concluída!'), backgroundColor: Colors.green),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Falha ao sincronizar. Verifica o servidor/rede.'), backgroundColor: Colors.red),
      );
    }
  }
}