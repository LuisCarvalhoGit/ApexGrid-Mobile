import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'widgets/telemetry_map.dart';
import 'history_screen.dart';
import 'garage_screen.dart';
import '../controllers/session_controller.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TelemetryMap(),
    const HistoryScreen(),
    const GarageScreen(), // A Garagem é o índice 3
  ];

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final isRecording = sessionState == SessionState.recording;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isRecording ? Colors.redAccent : Colors.amberAccent,
        foregroundColor: Colors.black,
        icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
        label: Text(
          isRecording ? 'PARAR TELEMETRIA' : 'INICIAR SESSÃO',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        onPressed: () async {
          if (isRecording) {
            final success = await ref.read(sessionControllerProvider.notifier).stopRecording();
            if (context.mounted && success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Sessão guardada no Histórico!', style: TextStyle(color: Colors.white)),
                ),
              );
            }
          } else {
            ref.read(sessionControllerProvider.notifier).startRecording();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed, // Mantém as cores estáveis com 4 itens!
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amberAccent,
          unselectedItemColor: Colors.white38,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Painel'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Navegação'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
            BottomNavigationBarItem(icon: Icon(Icons.two_wheeler), label: 'Garagem'), // <--- NOVO BOTÃO AQUI
          ],
        ),
      ),
    );
  }
}