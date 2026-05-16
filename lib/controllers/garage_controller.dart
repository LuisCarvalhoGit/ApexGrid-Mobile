import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/motorcycle.dart';

class GarageController extends Notifier<List<Motorcycle>> {
  @override
  List<Motorcycle> build() => [
    // Mota inicial para testes
    Motorcycle(
      id: 'tracer_01',
      brand: 'Yamaha',
      model: 'Tracer 7',
      year: 2022,
      engineCc: 689,
      weightKg: 196,
      currentOdometer: 14200,
      isDefault: true,
    )
  ];

  // --- 1. GESTÃO DE FROTA ---

  void addMotorcycle(Motorcycle bike) {
    state = [...state, bike];
  }

  void updateMotorcycle(Motorcycle updatedBike) {
    state = [for (final b in state) if (b.id == updatedBike.id) updatedBike else b];
  }

  // Define qual a mota que a telemetria vai usar
  void setAsDefault(String id) {
    state = [
      for (final bike in state)
        bike.copyWith(isDefault: bike.id == id)
    ];
  }

  // Atualização automática vinda da sessão de telemetria
  void updateOdometer(String bikeId, int newOdometer) {
    state = [
      for (final b in state)
        if (b.id == bikeId)
          b.copyWith(currentOdometer: newOdometer > b.currentOdometer ? newOdometer : b.currentOdometer)
        else
          b
    ];
  }

  // --- 2. GESTÃO DE MANUTENÇÃO ---

  void addMaintenance(String bikeId, String type, MaintenanceEvent event) {
    state = [for (final b in state) if (b.id == bikeId) _addEventByType(b, type, event) else b];
  }

  void editMaintenance(String bikeId, String type, String eventId, MaintenanceEvent updatedEvent) {
    state = [for (final b in state) if (b.id == bikeId) _editEventByType(b, type, eventId, updatedEvent) else b];
  }

  // Lógica privada para injetar o evento na lista correta
  Motorcycle _addEventByType(Motorcycle b, String type, MaintenanceEvent e) {
    if (type == 'oil') return b.copyWith(oilHistory: [...b.oilHistory, e]);
    if (type == 'chain') return b.copyWith(chainHistory: [...b.chainHistory, e]);
    return b.copyWith(tiresHistory: [...b.tiresHistory, e]);
  }

  Motorcycle _editEventByType(Motorcycle b, String type, String eId, MaintenanceEvent e) {
    List<MaintenanceEvent> updateList(List<MaintenanceEvent> list) => 
        [for (final item in list) if (item.id == eId) e else item];
    
    if (type == 'oil') return b.copyWith(oilHistory: updateList(b.oilHistory));
    if (type == 'chain') return b.copyWith(chainHistory: updateList(b.chainHistory));
    return b.copyWith(tiresHistory: updateList(b.tiresHistory));
  }
}

final garageProvider = NotifierProvider<GarageController, List<Motorcycle>>(GarageController.new);