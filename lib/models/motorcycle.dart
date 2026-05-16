class MaintenanceEvent {
  final String id;
  final DateTime date;
  final int odometerAtEvent;
  final String notes;

  MaintenanceEvent({
    required this.id,
    required this.date,
    required this.odometerAtEvent,
    this.notes = '',
  });
}

class Motorcycle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int engineCc;
  final int weightKg;
  final int currentOdometer;
  final bool isDefault;

  // Históricos detalhados
  final List<MaintenanceEvent> oilHistory;
  final List<MaintenanceEvent> chainHistory;
  final List<MaintenanceEvent> tiresHistory;

  Motorcycle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.engineCc,
    required this.weightKg,
    required this.currentOdometer,
    this.isDefault = false,
    this.oilHistory = const [],
    this.chainHistory = const [],
    this.tiresHistory = const [],
  });

  // Métodos auxiliares para obter o último registo
  int get lastOilKm => oilHistory.isEmpty ? 0 : oilHistory.last.odometerAtEvent;
  int get lastChainKm => chainHistory.isEmpty ? 0 : chainHistory.last.odometerAtEvent;
  int get lastTiresKm => tiresHistory.isEmpty ? 0 : tiresHistory.last.odometerAtEvent;

  Motorcycle copyWith({
    String? brand, String? model, int? year, int? engineCc, 
    int? weightKg, int? currentOdometer, bool? isDefault,
    List<MaintenanceEvent>? oilHistory,
    List<MaintenanceEvent>? chainHistory,
    List<MaintenanceEvent>? tiresHistory,
  }) {
    return Motorcycle(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      engineCc: engineCc ?? this.engineCc,
      weightKg: weightKg ?? this.weightKg,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      isDefault: isDefault ?? this.isDefault,
      oilHistory: oilHistory ?? this.oilHistory,
      chainHistory: chainHistory ?? this.chainHistory,
      tiresHistory: tiresHistory ?? this.tiresHistory,
    );
  }
}