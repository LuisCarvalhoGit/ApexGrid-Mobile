import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/settings_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/session_controller.dart';
import '../services/database_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DEFINIÇÕES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildSectionHeader('PERFIL DO PILOTO'),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.cyanAccent, size: 32),
            title: const Text('Conta Local', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Modo offline ativo', style: TextStyle(color: Colors.white54)),
          ),
          ListTile(
            leading: const Icon(Icons.two_wheeler, color: Colors.amberAccent, size: 32),
            title: const Text('Veículo Principal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Yamaha Tracer 7 (2022)', style: TextStyle(color: Colors.white54)),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildSectionHeader('TELEMETRIA E SENSORES'),
          SwitchListTile(
            // ATUALIZAÇÃO 1: 'activeColor' mudou para 'activeThumbColor' no SDK mais recente
            activeThumbColor: Colors.cyanAccent,
            title: const Text('Gravação a 50Hz (Alta Precisão)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Desativa para poupar bateria e espaço.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: settings.highFrequency,
            onChanged: (val) => settingsNotifier.toggleHighFreq(val),
          ),
          SwitchListTile(
            // ATUALIZAÇÃO 2: 'activeColor' mudou para 'activeThumbColor'
            activeThumbColor: Colors.cyanAccent,
            title: const Text('Autocalibração ao Iniciar', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Define o ângulo 0° automaticamente ao dar Start.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: settings.autoCalibrate,
            onChanged: (val) => settingsNotifier.toggleAutoCalibrate(val),
          ),
          ListTile(
            title: const Text('Diagnóstico de Hardware', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Verificar estado do giroscópio e GPS', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.memory, color: Colors.white24),
            onTap: () => _showDiagnostics(context, ref), // Abre o painel de diagnóstico
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildSectionHeader('MAPAS E NAVEGAÇÃO'),
          SwitchListTile(
            // ATUALIZAÇÃO 3: 'activeColor' mudou para 'activeThumbColor'
            activeThumbColor: Colors.amberAccent,
            title: const Text('Segmentos Offline', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Cache da região: Vila Real e Norte', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: settings.offlineMaps,
            onChanged: (val) => settingsNotifier.toggleOfflineMaps(val),
          ),

          const Divider(color: Colors.white10, height: 32),

          _buildSectionHeader('SISTEMA E ARMAZENAMENTO'),
          ListTile(
            title: const Text('Unidades de Medida', style: TextStyle(color: Colors.white)),
            subtitle: Text(settings.isMetric ? 'Quilómetros (km/h)' : 'Milhas (mph)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.swap_horiz, color: Colors.white24),
            onTap: () => settingsNotifier.toggleMetric(),
          ),
          ListTile(
            title: const Text('Exportar Base de Dados', style: TextStyle(color: Colors.cyanAccent)),
            subtitle: const Text('Partilha os ficheiros CSV das tuas sessões.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.ios_share, color: Colors.cyanAccent),
            onTap: () => _exportData(context, ref), // Partilha os ficheiros
          ),
          ListTile(
            title: const Text('Limpar Histórico Local', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Apaga todas as sessões gravadas.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: () => _clearHistory(context, ref), // Alerta e apaga
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11),
      ),
    );
  }

  // --- FUNÇÕES DE LÓGICA DO ECRÃ ---

  void _showDiagnostics(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('DIAGNÓSTICO AO VIVO', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 2)),
        content: Consumer(
          builder: (context, ref, child) {
            final data = ref.watch(liveTelemetryProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ângulo Bruto: ${data.leanAngle.toStringAsFixed(2)}°', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                Text('Força G (X): ${data.gForceX.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                Text('Força G (Y): ${data.gForceY.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                const SizedBox(height: 10),
                const Text('Se os valores flutuarem enquanto a mota está parada, os sensores estão a funcionar bem.', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('FECHAR', style: TextStyle(color: Colors.white54)))
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(historyProvider).value ?? [];
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum dado para exportar.', style: TextStyle(color: Colors.black))));
      return;
    }
    
    final files = sessions.map((s) => XFile(s.csvFilePath)).toList();
    final box = context.findRenderObject() as RenderBox?;
    
    // A SINTAXE NOVA DO SHARE_PLUS
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: 'Backup de Telemetria ApexGrid',
        // O sharePositionOrigin continua a ser obrigatório para não dar crash no iPad
        sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null,
      ),
    );
  }

  void _clearHistory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Aviso Crítico', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Tens a certeza? Esta ação vai apagar todas as viagens gravadas no teu telemóvel de forma irreversível.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // 1. Apaga tudo da base de dados
              await DatabaseService().clearAllSessions();
              // 2. Força o Riverpod a ler a base de dados (que agora está vazia)
              ref.invalidate(historyProvider);
              
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('Histórico limpo com sucesso.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ));
              }
            },
            child: const Text('APAGAR TUDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}