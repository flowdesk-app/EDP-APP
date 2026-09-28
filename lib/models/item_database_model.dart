class ItemDatabaseModel {
  final String itemId;
  final String itemName;
  final String? sku;
  final String? description;
  final String? rate;
  final String? productType;
  final String? status;
  final String? unitName;
  final String? usageUnit;
  final String? vendor;
  final String? itemType;
  final String? hsnSac;
  final String? taxable;
  final String? intraStateTaxRate;
  final String? interStateTaxRate;

  ItemDatabaseModel({
    required this.itemId,
    required this.itemName,
    this.sku,
    this.description,
    this.rate,
    this.productType,
    this.status,
    this.unitName,
    this.usageUnit,
    this.vendor,
    this.itemType,
    this.hsnSac,
    this.taxable,
    this.intraStateTaxRate,
    this.interStateTaxRate,
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
      usageUnit: json['usageUnit'],
      vendor: json['vendor'],
      itemType: json['itemType'],
      hsnSac: json['hsnSac'],
      taxable: json['taxable'],
      intraStateTaxRate: json['intraStateTaxRate'],
      interStateTaxRate: json['interStateTaxRate'],
    );
  }
}
