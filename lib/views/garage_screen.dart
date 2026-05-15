import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/garage_controller.dart';
import '../models/motorcycle.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleet = ref.watch(garageProvider);
    // Para o MVP, mostramos a mota ativa no topo
    final activeBike = fleet.firstWhere((b) => b.isDefault, orElse: () => fleet.first);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GARAGEM VIRTUAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.cyanAccent),
            onPressed: () {
              // Futuro: Abrir modal para adicionar mota
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve: Adicionar nova mota', style: TextStyle(color: Colors.black))));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 120),
        children: [
          // 1. CARTÃO DA MÁQUINA PRINCIPAL
          const Text('VEÍCULO ATIVO (TELEMETRIA)', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)],
            ),
            child: Column(
              children: [
                // Topo do Cartão
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                        child: const Icon(Icons.two_wheeler, size: 40, color: Colors.amberAccent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activeBike.brand.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                            Text(activeBike.model, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildSpecBadge('${activeBike.engineCc} CC'),
                                const SizedBox(width: 8),
                                _buildSpecBadge('${activeBike.year}'),
                                const SizedBox(width: 8),
                                _buildSpecBadge('${activeBike.weightKg} KG'),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white10, height: 1),

                // Odómetro
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ODÓMETRO TOTAL', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${activeBike.currentOdometer}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                          const Text(' KM', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 2. PIT STOP (Gestão de Manutenção)
          const Text('PIT STOP & MANUTENÇÃO', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
          const SizedBox(height: 12),
          
          _buildMaintenanceTracker(
            context, ref,
            bike: activeBike,
            type: 'chain',
            title: 'LUBRIFICAÇÃO CORRENTE',
            icon: Icons.link,
            lastServiceKm: activeBike.lastChainLubeKm,
            intervalKm: 500, // Avisa a cada 500km
          ),
          const SizedBox(height: 12),
          _buildMaintenanceTracker(
            context, ref,
            bike: activeBike,
            type: 'oil',
            title: 'MUDANÇA DE ÓLEO',
            icon: Icons.water_drop_outlined,
            lastServiceKm: activeBike.lastOilChangeKm,
            intervalKm: 10000, // Avisa aos 10.000km
          ),
          const SizedBox(height: 12),
          _buildMaintenanceTracker(
            context, ref,
            bike: activeBike,
            type: 'tires',
            title: 'ESTADO DOS PNEUS',
            icon: Icons.trip_origin,
            lastServiceKm: activeBike.lastTiresChangeKm,
            intervalKm: 12000, // Avisa aos 12.000km
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMaintenanceTracker(BuildContext context, WidgetRef ref, {
    required Motorcycle bike,
    required String type,
    required String title,
    required IconData icon,
    required int lastServiceKm,
    required int intervalKm,
  }) {
    final kmsSinceService = bike.currentOdometer - lastServiceKm;
    final remainingKms = intervalKm - kmsSinceService;
    final percentage = (kmsSinceService / intervalKm).clamp(0.0, 1.0);
    
    // Se passou o limite, fica vermelho (Alerta)
    final bool isWarning = remainingKms <= 0;
    final Color barColor = isWarning ? Colors.redAccent : Colors.cyanAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              
              // Botão para registar a manutenção
              SizedBox(
                height: 28,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(garageProvider.notifier).registerMaintenance(bike.id, type);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.greenAccent,
                      content: Text('$title registada aos ${bike.currentOdometer}km.', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('REGISTAR', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isWarning ? 'MUDANÇA EXIGIDA' : 'Faltam ${remainingKms} km', style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('${(percentage * 100).toInt()}% Desgaste', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de Progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: barColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}