class SupplierModel {
  final String supplierId;
  final String supplierName;

  SupplierModel({required this.supplierId, required this.supplierName});

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
    supplierId: json['supplierId'] as String,
    supplierName: json['supplierName'] as String,
  );

  Map<String, dynamic> toJson() => {
    'supplierId': supplierId,
    'supplierName': supplierName,
  };
}
