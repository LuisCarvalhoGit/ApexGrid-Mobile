class Motorcycle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int engineCc;
  final int weightKg; 
  final bool isDefault; // A mota que está a ser gravada no Cockpit

  // Métricas de Manutenção (Pit Stop)
  final int currentOdometer;
  final int lastOilChangeKm;
  final int lastChainLubeKm;
  final int lastTiresChangeKm;

  Motorcycle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.engineCc,
    required this.weightKg,
    this.isDefault = false,
    this.currentOdometer = 0,
    this.lastOilChangeKm = 0,
    this.lastChainLubeKm = 0,
    this.lastTiresChangeKm = 0,
  });

  Motorcycle copyWith({
    String? id, String? brand, String? model, int? year,
    int? engineCc, int? weightKg, bool? isDefault,
    int? currentOdometer, int? lastOilChangeKm,
    int? lastChainLubeKm, int? lastTiresChangeKm,
  }) {
    return Motorcycle(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      engineCc: engineCc ?? this.engineCc,
      weightKg: weightKg ?? this.weightKg,
      isDefault: isDefault ?? this.isDefault,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      lastOilChangeKm: lastOilChangeKm ?? this.lastOilChangeKm,
      lastChainLubeKm: lastChainLubeKm ?? this.lastChainLubeKm,
      lastTiresChangeKm: lastTiresChangeKm ?? this.lastTiresChangeKm,
    );
  }
}