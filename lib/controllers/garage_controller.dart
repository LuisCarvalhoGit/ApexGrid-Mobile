import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/motorcycle.dart';

class GarageController extends Notifier<List<Motorcycle>> {
  @override
  List<Motorcycle> build() {
    // Carrega a frota inicial (MVP Database)
    return [
      Motorcycle(
        id: 'bike_01',
        brand: 'Yamaha',
        model: 'Tracer 7',
        year: 2022,
        engineCc: 689,
        weightKg: 196,
        isDefault: true,
        currentOdometer: 14200,
        lastOilChangeKm: 10000, // Óleo trocado aos 10k
        lastChainLubeKm: 13800, // Corrente lubrificada há 400km
        lastTiresChangeKm: 8000,
      ),
      // Podes adicionar mais motas aqui no futuro
    ];
  }

  void setAsDefault(String id) {
    state = state.map((bike) {
      return bike.copyWith(isDefault: bike.id == id);
    }).toList();
  }

  void updateOdometer(String id, int newOdometer) {
    state = state.map((bike) {
      if (bike.id == id && newOdometer >= bike.currentOdometer) {
        return bike.copyWith(currentOdometer: newOdometer);
      }
      return bike;
    }).toList();
  }

  void registerMaintenance(String id, String type) {
    state = state.map((bike) {
      if (bike.id == id) {
        switch (type) {
          case 'chain': return bike.copyWith(lastChainLubeKm: bike.currentOdometer);
          case 'oil': return bike.copyWith(lastOilChangeKm: bike.currentOdometer);
          case 'tires': return bike.copyWith(lastTiresChangeKm: bike.currentOdometer);
        }
      }
      return bike;
    }).toList();
  }
}

final garageProvider = NotifierProvider<GarageController, List<Motorcycle>>(() {
  return GarageController();
});