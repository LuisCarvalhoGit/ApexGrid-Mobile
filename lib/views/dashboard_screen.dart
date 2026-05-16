import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/session_controller.dart';
import '../controllers/lean_angle_controller.dart';
import '../models/session_data_point.dart';
import 'widgets/telemetry_map.dart';
import 'widgets/g_force_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isExpanded = true;

  void _togglePanel(bool expand) => setState(() => _isExpanded = expand);

  @override
  Widget build(BuildContext context) {
    final liveData = ref.watch(liveTelemetryProvider);

    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (previous != SessionState.recording && next == SessionState.recording) {
        if (_isExpanded) _togglePanel(false);
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final double panelHeight = _isExpanded ? screenHeight * 0.85 : 220.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. O Mapa encapsulado
          const TelemetryMap(),

          // 2. O HUD Deslizante
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: 0,
            left: 0,
            right: 0,
            height: panelHeight,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _togglePanel(true);
                }
                else if (details.primaryVelocity! > 0) { 
                  _togglePanel(false);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A).withValues(alpha:0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: Colors.cyanAccent.withValues(alpha:0.3), width: 1)),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 5)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: _buildDashboardContent(liveData),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(SessionDataPoint liveData) {
    if (!_isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(liveData.speedKmh.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    const Padding(padding: EdgeInsets.only(bottom: 8.0, left: 4), child: Text('KM/H', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: GForceBar(angle: liveData.leanAngle > 0 ? liveData.leanAngle : 0, isLeft: true, isExpanded: false)),
                        Container(width: 60, alignment: Alignment.center, child: Text('${liveData.leanAngle.abs().toStringAsFixed(0)}°', style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace'))),
                        Expanded(child: GForceBar(angle: liveData.leanAngle < 0 ? liveData.leanAngle.abs() : 0, isLeft: false, isExpanded: false)),
                      ],
                    ),
                    const Text('ÂNGULO DE INCLINAÇÃO', style: TextStyle(color: Colors.white10, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 30),
        const Text('TELEMETRIA ATIVA', style: TextStyle(color: Colors.white10, letterSpacing: 5, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Text(liveData.speedKmh.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 150, fontWeight: FontWeight.w900, height: 0.9, fontFamily: 'monospace')),
        const Text('KM/H', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            children: [
              Expanded(child: GForceBar(angle: liveData.leanAngle > 0 ? liveData.leanAngle : 0, isLeft: true, isExpanded: true)),
              Container(width: 130, alignment: Alignment.center, child: Text('${liveData.leanAngle.abs().toStringAsFixed(0)}°', style: const TextStyle(color: Colors.amberAccent, fontSize: 56, fontWeight: FontWeight.w900, fontFamily: 'monospace'))),
              Expanded(child: GForceBar(angle: liveData.leanAngle < 0 ? liveData.leanAngle.abs() : 0, isLeft: false, isExpanded: true)),
            ],
          ),
        ),
        const Text('ÂNGULO DE INCLINAÇÃO', style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        TextButton.icon(
          onPressed: () => ref.read(leanAngleProvider.notifier).setZeroCalibration(),
          icon: const Icon(Icons.refresh, size: 14, color: Colors.white24),
          label: const Text('CALIBRAR SENSORES', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}