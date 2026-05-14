import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'lean_angle_controller.dart'; // Importamos o cérebro

class ChartController extends Notifier<List<FlSpot>> {
  final int _maxDataPoints = 100;
  double _timeX = 0;

  @override
  List<FlSpot> build() {
    // Escuta o ângulo global e desenha-o no gráfico
    ref.listen<double>(leanAngleProvider, (previous, currentAngle) {
      _timeX += 0.02; 
      
      final updatedList = [...state, FlSpot(_timeX, currentAngle)];
      if (updatedList.length > _maxDataPoints) {
        updatedList.removeAt(0);
      }
      state = updatedList;
    });

    return [];
  }
}

final leanAngleChartProvider = NotifierProvider<ChartController, List<FlSpot>>(() {
  return ChartController();
});