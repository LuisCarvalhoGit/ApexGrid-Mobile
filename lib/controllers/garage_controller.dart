import 'package:flutter_riverpod/legacy.dart';
import '../models/motorcycle.dart';

class GarageState {
  final List<Motorcycle> bikes;
  final String activeBikeId;

  GarageState({this.bikes = const [], this.activeBikeId = ''});

  Motorcycle? get activeBike {
    try {
      return bikes.firstWhere((bike) => bike.id == activeBikeId);
    } catch (e) {
      return null;
    }
  }

  GarageState copyWith({List<Motorcycle>? bikes, String? activeBikeId}) {
    return GarageState(
      bikes: bikes ?? this.bikes,
      activeBikeId: activeBikeId ?? this.activeBikeId,
    );
  }
}

class GarageController extends StateNotifier<GarageState> {
  GarageController() : super(GarageState()) {
    _loadGarage();
  }

  void _loadGarage() {
    // Simulação de carregamento de base de dados local (SQLite/Hive)
    final defaultBike = Motorcycle(
      id: 'moto_001',
      brand: 'Yamaha',
      model: 'Tracer 7',
      year: 2022,
      category: 'Sport-Touring',
      currentTires: 'Michelin Road 6',
      totalDistanceKmh: 1240.5,
    );

    state = state.copyWith(
      bikes: [defaultBike],
      activeBikeId: defaultBike.id,
    );
  }

  void setActiveBike(String id) {
    state = state.copyWith(activeBikeId: id);
  }
}

final garageProvider = StateNotifierProvider<GarageController, GarageState>((ref) {
  return GarageController();
});