import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/session_controller.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'garage_screen.dart';
import 'settings_screen.dart'; // O novo ecrã

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  // Adicionámos a SettingsScreen à lista de ecrãs
  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const GarageScreen(),
    const SettingsScreen(), // Posição 3
  ];

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final isRecording = sessionState == SessionState.recording;

    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isRecording) {
            ref.read(sessionControllerProvider.notifier).stopRecording();
          } else {
            ref.read(sessionControllerProvider.notifier).startRecording();
          }
        },
        backgroundColor: isRecording ? Colors.redAccent : Colors.amberAccent,
        elevation: 8,
        shape: const CircleBorder(),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 36,
          color: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0D0D0D),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.speed, 
                  color: _currentIndex == 0 ? Colors.cyanAccent : Colors.white24),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              IconButton(
                icon: Icon(Icons.history, 
                  color: _currentIndex == 1 ? Colors.cyanAccent : Colors.white24),
                onPressed: () => setState(() => _currentIndex = 1),
              ),
              
              const SizedBox(width: 48),

              IconButton(
                icon: Icon(Icons.two_wheeler, 
                  color: _currentIndex == 2 ? Colors.cyanAccent : Colors.white24),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              // Agora a engrenagem funciona e muda para a aba de Definições
              IconButton(
                icon: Icon(Icons.settings_outlined, 
                  color: _currentIndex == 3 ? Colors.cyanAccent : Colors.white24),
                onPressed: () => setState(() => _currentIndex = 3), 
              ),
            ],
          ),
        ),
      ),
    );
  }
}