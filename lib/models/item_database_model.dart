class ItemDatabaseModel {
  final String itemId;
  final String itemName;
  final String? sku;
  final String? description;
  final String? rate;
  final String? productType;
  final String? status;
  final String? unitName;
  final String? vendor;
  final String? itemType;

  ItemDatabaseModel({
    required this.itemId,
    required this.itemName,
    this.sku,
    this.description,
    this.rate,
    this.productType,
    this.status,
    this.unitName,
    this.vendor,
    this.itemType,
  });

  factory ItemDatabaseModel.fromJson(Map<String, dynamic> json) {
    return ItemDatabaseModel(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      sku: json['sku'],
      description: json['description'],
      rate: json['rate'],
      productType: json['productType'],
      status: json['status'],
      unitName: json['unitName'],
      vendor: json['vendor'],
      itemType: json['itemType'],
    );
  }
}
