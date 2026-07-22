class RawMaterialModel {
  final String? id;
  final String name;
  final double availableQuantity;
  final String availableUnit;
  final double minimumQuantity;
  final String minimumUnit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RawMaterialModel({
    this.id,
    required this.name,
    required this.availableQuantity,
    required this.availableUnit,
    required this.minimumQuantity,
    required this.minimumUnit,
    this.createdAt,
    this.updatedAt,
  });

  factory RawMaterialModel.fromJson(Map<String, dynamic> json) {
    return RawMaterialModel(
      id: json['_id'],
      name: json['name'] ?? '',
      availableQuantity: (json['availableQuantity'] ?? 0).toDouble(),
      availableUnit: json['availableUnit'] ?? 'Kg',
      minimumQuantity: (json['minimumQuantity'] ?? 0).toDouble(),
      minimumUnit: json['minimumUnit'] ?? 'Kg',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'availableQuantity': availableQuantity,
      'availableUnit': availableUnit,
      'minimumQuantity': minimumQuantity,
      'minimumUnit': minimumUnit,
    };
  }
}
