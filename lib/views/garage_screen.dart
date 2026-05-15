import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/garage_controller.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garageState = ref.watch(garageProvider);
    final activeBike = garageState.activeBike;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GARAGEM VIRTUAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
            onPressed: () {
              // Futuro: Abrir modal para adicionar nova mota
            },
          )
        ],
      ),
      body: activeBike == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD PRINCIPAL DA MOTA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activeBike.brand.toUpperCase(),
                              style: const TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 3),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amberAccent),
                              ),
                              child: const Text('MÁQUINA ATIVA', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeBike.model,
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeBike.year} • ${activeBike.category}',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontFamily: 'monospace'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Icon(Icons.two_wheeler, size: 80, color: Colors.white24), // Placeholder para futura foto da mota
                        ),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('ODÓMETRO', '${activeBike.totalDistanceKmh.toStringAsFixed(0)} km'),
                            _buildStat('PNEUS', activeBike.currentTires),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('AFINAÇÕES E SETUP', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // LISTA DE AFINAÇÕES
                  _buildSetupTile(Icons.settings_applications, 'Pressão dos Pneus', 'F: 2.5 bar | T: 2.9 bar'),
                  _buildSetupTile(Icons.compress, 'Pré-Carga Suspensão', 'Nível 4 (Standard)'),
                  
                  const Spacer(),
                  // BOTAO DE PARTILHA DO PERFIL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('PARTILHAR PERFIL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                      onPressed: () {
                        // Implementaremos o gerador de imagem na próxima fase
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildSetupTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
              ],
            ),
          ),
          const Icon(Icons.edit, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}