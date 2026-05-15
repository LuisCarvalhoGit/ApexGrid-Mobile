class Motorcycle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String category; // ex: Sport-Touring, Naked, Superbike
  final String currentTires; // Vital para o grip nos segmentos
  final double totalDistanceKmh; // Odómetro da app

  Motorcycle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.category,
    required this.currentTires,
    this.totalDistanceKmh = 0.0,
  });

  Motorcycle copyWith({
    String? brand, String? model, int? year, 
    String? category, String? currentTires, double? totalDistanceKmh,
  }) {
    return Motorcycle(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      category: category ?? this.category,
      currentTires: currentTires ?? this.currentTires,
      totalDistanceKmh: totalDistanceKmh ?? this.totalDistanceKmh,
    );
  }
}