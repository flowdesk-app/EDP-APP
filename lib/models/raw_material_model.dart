class RawMaterialModel {
  final String? id;
  final String name;
  final double availableQuantity;
  final String availableUnit;
  final double? minimumQuantity;
  final String? minimumUnit;
  final String? gritSize;

  RawMaterialModel({
    this.id,
    required this.name,
    required this.availableQuantity,
    required this.availableUnit,
    this.minimumQuantity,
    this.minimumUnit,
    this.gritSize,
  });

  factory RawMaterialModel.fromJson(Map<String, dynamic> json) {
    return RawMaterialModel(
      id: json['_id'],
      name: json['name'] ?? '',
      availableQuantity: (json['availableQuantity'] ?? 0).toDouble(),
      availableUnit: json['availableUnit'] ?? 'Kg',
      minimumQuantity: json['minimumQuantity'] != null ? json['minimumQuantity'].toDouble() : null,
      minimumUnit: json['minimumUnit'],
      gritSize: json['gritSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'availableQuantity': availableQuantity,
      'availableUnit': availableUnit,
      if (minimumQuantity != null) 'minimumQuantity': minimumQuantity,
      if (minimumUnit != null) 'minimumUnit': minimumUnit,
      if (gritSize != null) 'gritSize': gritSize,
    };
  }
}
