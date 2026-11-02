class EstimateModel {
  final String? id;
  final String calculationNo;
  final DateTime date;
  final String? jobId;
  final String customerName;
  final String? itemDescription;
  final String? drawingNo;
  final String type; // 'N' (New), 'R' (Recoating), 'C' (Coating)
  final String? calculationsNotes;

  // Diamond Calculation
  final double effectiveCoatingArea;
  final String? gritSize;
  final double factor;
  final double diamondRequirement; // in carats
  final double diamondRate; // ₹ / carat
  final double diamondCost;

  // Operational Direct Costs
  final double blankCost;
  final double grindingCost;
  final double extractionCost;
  final double balancingCost;
  final double transportationCost;

  // Margin & Totals
  final double directCostSum;
  final double marginPercentage;
  final double subTotalInclMargin;
  final double processCost;
  final double totalCost;

  // Discount & Final QTN
  final double discountProvisionPercentage;
  final double provisionForDiscount;
  final double discountPercentage;
  final double qtnPrice;
  final String? minOrderQty;
  final String? delivery;
  final String? qtnNoAndDate;
  final bool isAutoEstimated;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  EstimateModel({
    this.id,
    required this.calculationNo,
    required this.date,
    this.jobId,
    required this.customerName,
    this.itemDescription,
    this.drawingNo,
    this.type = 'N',
    this.calculationsNotes,
    this.effectiveCoatingArea = 0.0,
    this.gritSize,
    this.factor = 0.30,
    this.diamondRequirement = 0.0,
    this.diamondRate = 25.0,
    this.diamondCost = 0.0,
    this.blankCost = 0.0,
    this.grindingCost = 0.0,
    this.extractionCost = 0.0,
    this.balancingCost = 0.0,
    this.transportationCost = 0.0,
    this.directCostSum = 0.0,
    this.marginPercentage = 25.0,
    this.subTotalInclMargin = 0.0,
    this.processCost = 0.0,
    this.totalCost = 0.0,
    this.discountProvisionPercentage = 15.0,
    this.provisionForDiscount = 0.0,
    this.discountPercentage = 10.0,
    this.qtnPrice = 0.0,
    this.minOrderQty,
    this.delivery,
    this.qtnNoAndDate,
    this.isAutoEstimated = false,
    this.createdAt,
    this.updatedAt,
  });

  factory EstimateModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parseNum(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return EstimateModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      calculationNo: json['calculationNo']?.toString() ?? '',
      date: parseDt(json['date']),
      jobId: json['jobId']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      itemDescription: json['itemDescription']?.toString(),
      drawingNo: json['drawingNo']?.toString(),
      type: json['type']?.toString() ?? 'N',
      calculationsNotes: json['calculationsNotes']?.toString(),
      effectiveCoatingArea: parseNum(json['effectiveCoatingArea']),
      gritSize: json['gritSize']?.toString(),
      factor: parseNum(json['factor']),
      diamondRequirement: parseNum(json['diamondRequirement']),
      diamondRate: parseNum(json['diamondRate']) == 0.0 ? 25.0 : parseNum(json['diamondRate']),
      diamondCost: parseNum(json['diamondCost']),
      blankCost: parseNum(json['blankCost']),
      grindingCost: parseNum(json['grindingCost']),
      extractionCost: parseNum(json['extractionCost']),
      balancingCost: parseNum(json['balancingCost']),
      transportationCost: parseNum(json['transportationCost']),
      directCostSum: parseNum(json['directCostSum']),
      marginPercentage: parseNum(json['marginPercentage']) == 0.0 ? 25.0 : parseNum(json['marginPercentage']),
      subTotalInclMargin: parseNum(json['subTotalInclMargin']),
      processCost: parseNum(json['processCost']),
      totalCost: parseNum(json['totalCost']),
      discountProvisionPercentage: parseNum(json['discountProvisionPercentage']) == 0.0 ? 15.0 : parseNum(json['discountProvisionPercentage']),
      provisionForDiscount: parseNum(json['provisionForDiscount']),
      discountPercentage: parseNum(json['discountPercentage']),
      qtnPrice: parseNum(json['qtnPrice']),
      minOrderQty: json['minOrderQty']?.toString(),
      delivery: json['delivery']?.toString(),
      qtnNoAndDate: json['qtnNoAndDate']?.toString(),
      isAutoEstimated: json['isAutoEstimated'] == true,
      createdAt: json['createdAt'] != null ? parseDt(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseDt(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'calculationNo': calculationNo,
      'date': date.toIso8601String(),
      if (jobId != null) 'jobId': jobId,
      'customerName': customerName,
      'itemDescription': itemDescription,
      'drawingNo': drawingNo,
      'type': type,
      'calculationsNotes': calculationsNotes,
      'effectiveCoatingArea': effectiveCoatingArea,
      'gritSize': gritSize,
      'factor': factor,
      'diamondRequirement': diamondRequirement,
      'diamondRate': diamondRate,
      'diamondCost': diamondCost,
      'blankCost': blankCost,
      'grindingCost': grindingCost,
      'extractionCost': extractionCost,
      'balancingCost': balancingCost,
      'transportationCost': transportationCost,
      'directCostSum': directCostSum,
      'marginPercentage': marginPercentage,
      'subTotalInclMargin': subTotalInclMargin,
      'processCost': processCost,
      'totalCost': totalCost,
      'discountProvisionPercentage': discountProvisionPercentage,
      'provisionForDiscount': provisionForDiscount,
      'discountPercentage': discountPercentage,
      'qtnPrice': qtnPrice,
      'minOrderQty': minOrderQty,
      'delivery': delivery,
      'qtnNoAndDate': qtnNoAndDate,
      'isAutoEstimated': isAutoEstimated,
    };
  }

  EstimateModel copyWith({
    String? id,
    String? calculationNo,
    DateTime? date,
    String? jobId,
    String? customerName,
    String? itemDescription,
    String? drawingNo,
    String? type,
    String? calculationsNotes,
    double? effectiveCoatingArea,
    String? gritSize,
    double? factor,
    double? diamondRequirement,
    double? diamondRate,
    double? diamondCost,
    double? blankCost,
    double? grindingCost,
    double? extractionCost,
    double? balancingCost,
    double? transportationCost,
    double? directCostSum,
    double? marginPercentage,
    double? subTotalInclMargin,
    double? processCost,
    double? totalCost,
    double? discountProvisionPercentage,
    double? provisionForDiscount,
    double? discountPercentage,
    double? qtnPrice,
    String? minOrderQty,
    String? delivery,
    String? qtnNoAndDate,
    bool? isAutoEstimated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EstimateModel(
      id: id ?? this.id,
      calculationNo: calculationNo ?? this.calculationNo,
      date: date ?? this.date,
      jobId: jobId ?? this.jobId,
      customerName: customerName ?? this.customerName,
      itemDescription: itemDescription ?? this.itemDescription,
      drawingNo: drawingNo ?? this.drawingNo,
      type: type ?? this.type,
      calculationsNotes: calculationsNotes ?? this.calculationsNotes,
      effectiveCoatingArea: effectiveCoatingArea ?? this.effectiveCoatingArea,
      gritSize: gritSize ?? this.gritSize,
      factor: factor ?? this.factor,
      diamondRequirement: diamondRequirement ?? this.diamondRequirement,
      diamondRate: diamondRate ?? this.diamondRate,
      diamondCost: diamondCost ?? this.diamondCost,
      blankCost: blankCost ?? this.blankCost,
      grindingCost: grindingCost ?? this.grindingCost,
      extractionCost: extractionCost ?? this.extractionCost,
      balancingCost: balancingCost ?? this.balancingCost,
      transportationCost: transportationCost ?? this.transportationCost,
      directCostSum: directCostSum ?? this.directCostSum,
      marginPercentage: marginPercentage ?? this.marginPercentage,
      subTotalInclMargin: subTotalInclMargin ?? this.subTotalInclMargin,
      processCost: processCost ?? this.processCost,
      totalCost: totalCost ?? this.totalCost,
      discountProvisionPercentage: discountProvisionPercentage ?? this.discountProvisionPercentage,
      provisionForDiscount: provisionForDiscount ?? this.provisionForDiscount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      qtnPrice: qtnPrice ?? this.qtnPrice,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      delivery: delivery ?? this.delivery,
      qtnNoAndDate: qtnNoAndDate ?? this.qtnNoAndDate,
      isAutoEstimated: isAutoEstimated ?? this.isAutoEstimated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
