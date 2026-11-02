class DeliveryChallanItem {
  final int itemNumber;
  final String? jobId;
  final String description;
  final int quantity;
  final String unit;
  final double approxValue;

  DeliveryChallanItem({
    required this.itemNumber,
    this.jobId,
    required this.description,
    this.quantity = 1,
    this.unit = 'No(s)',
    this.approxValue = 1.00,
  });

  factory DeliveryChallanItem.fromJson(Map<String, dynamic> json) {
    return DeliveryChallanItem(
      itemNumber: json['itemNumber'] is int
          ? json['itemNumber']
          : int.tryParse(json['itemNumber']?.toString() ?? '1') ?? 1,
      jobId: json['jobId']?.toString(),
      description: json['description']?.toString() ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unit: json['unit']?.toString() ?? 'No(s)',
      approxValue: (json['approxValue'] as num?)?.toDouble() ?? 1.00,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemNumber': itemNumber,
      'jobId': jobId,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'approxValue': approxValue,
    };
  }

  DeliveryChallanItem copyWith({
    int? itemNumber,
    String? jobId,
    String? description,
    int? quantity,
    String? unit,
    double? approxValue,
  }) {
    return DeliveryChallanItem(
      itemNumber: itemNumber ?? this.itemNumber,
      jobId: jobId ?? this.jobId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      approxValue: approxValue ?? this.approxValue,
    );
  }
}

class DeliveryChallanModel {
  final String? id;
  final String dcNumber;
  final DateTime date;
  final String supplierName;
  final String supplierAddress;
  final String? supplierGstin;
  final String placeOfSupply;
  final String? reference;
  final String challanType;
  final List<DeliveryChallanItem> items;
  final String authorizedSignatoryFor;
  final List<String> jobIds;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeliveryChallanModel({
    this.id,
    required this.dcNumber,
    required this.date,
    required this.supplierName,
    this.supplierAddress = '',
    this.supplierGstin,
    this.placeOfSupply = 'Tamil Nadu (33)',
    this.reference,
    this.challanType = 'Job Work',
    required this.items,
    this.authorizedSignatoryFor = 'Exclusive Diamond Products',
    this.jobIds = const [],
    this.status = 'Active',
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryChallanModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawItems = json['items'];
    List<DeliveryChallanItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => DeliveryChallanItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    final rawJobIds = json['jobIds'];
    List<String> parsedJobIds = [];
    if (rawJobIds is List) {
      parsedJobIds = rawJobIds.map((j) => j.toString()).toList();
    }

    return DeliveryChallanModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      dcNumber: json['dcNumber']?.toString() ?? '',
      date: parseDt(json['date']),
      supplierName: json['supplierName']?.toString() ?? '',
      supplierAddress: json['supplierAddress']?.toString() ?? '',
      supplierGstin: json['supplierGstin']?.toString(),
      placeOfSupply: json['placeOfSupply']?.toString() ?? 'Tamil Nadu (33)',
      reference: json['reference']?.toString(),
      challanType: json['challanType']?.toString() ?? 'Job Work',
      items: parsedItems,
      authorizedSignatoryFor:
          json['authorizedSignatoryFor']?.toString() ?? 'Exclusive Diamond Products',
      jobIds: parsedJobIds,
      status: json['status']?.toString() ?? 'Active',
      createdAt: json['createdAt'] != null ? parseDt(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseDt(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'dcNumber': dcNumber,
      'date': date.toIso8601String(),
      'supplierName': supplierName,
      'supplierAddress': supplierAddress,
      'supplierGstin': supplierGstin,
      'placeOfSupply': placeOfSupply,
      'reference': reference,
      'challanType': challanType,
      'items': items.map((i) => i.toJson()).toList(),
      'authorizedSignatoryFor': authorizedSignatoryFor,
      'jobIds': jobIds,
      'status': status,
    };
  }

  DeliveryChallanModel copyWith({
    String? id,
    String? dcNumber,
    DateTime? date,
    String? supplierName,
    String? supplierAddress,
    String? supplierGstin,
    String? placeOfSupply,
    String? reference,
    String? challanType,
    List<DeliveryChallanItem>? items,
    String? authorizedSignatoryFor,
    List<String>? jobIds,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryChallanModel(
      id: id ?? this.id,
      dcNumber: dcNumber ?? this.dcNumber,
      date: date ?? this.date,
      supplierName: supplierName ?? this.supplierName,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      supplierGstin: supplierGstin ?? this.supplierGstin,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      reference: reference ?? this.reference,
      challanType: challanType ?? this.challanType,
      items: items ?? this.items,
      authorizedSignatoryFor: authorizedSignatoryFor ?? this.authorizedSignatoryFor,
      jobIds: jobIds ?? this.jobIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
