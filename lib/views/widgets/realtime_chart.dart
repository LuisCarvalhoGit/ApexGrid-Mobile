import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/chart_controller.dart';
import '../../controllers/lean_angle_controller.dart';

class RealtimeChart extends ConsumerWidget {
  const RealtimeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(leanAngleChartProvider);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16), // Voltamos ao padding normal
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. O botão no topo, seguro e dentro do layout
          TextButton.icon(
            onPressed: () {
              ref.read(leanAngleProvider.notifier).setZeroCalibration();
            },
            icon: const Icon(Icons.center_focus_strong, color: Colors.greenAccent, size: 16),
            label: const Text('CALIBRAR 0°', style: TextStyle(color: Colors.greenAccent)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha:0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero, 
              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Fica compacto
            ),
          ),
          
          const SizedBox(height: 12), // Espaço a respirar
          
          // 2. O Gráfico ocupa o resto do espaço do Container
          Expanded(
            child: points.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    // (Mantém as definições exatas do teu LineChart aqui)
                    LineChartData(
                      minY: -60,
                      maxY: 60,
                      lineBarsData: [
                        LineChartBarData(
                          spots: points,
                          isCurved: true,
                          color: Colors.amberAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}°', style: const TextStyle(color: Colors.white70)),
                          ),
                        ),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 15,
                        getDrawingHorizontalLine: (value) => value == 0 
                            ? const FlLine(color: Colors.greenAccent, strokeWidth: 2)
                            : FlLine(color: Colors.white.withValues(alpha:0.1), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}