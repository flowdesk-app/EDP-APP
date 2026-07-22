class JobModel {
  final String jobId;
  final String? partNumber;
  final String? partDescription;
  final int? quantity;
  final int numberOfBins;
  final int numberOfBoxes;
  final String? logisticsName;
  final int? deliveredQuantity;
  final int? returnedQuantity;
  final String? destinationType;
  final String? destinationName;
  final String? processType;
  final String? vehicleNumber;
  final String? driverName;
  final String? driverMobile;
  final String status;
  final String currentLocation;
  final String? supplier;
  final List<String> supplierChain;
  final DateTime? expectedReturnDate;
  final DateTime createdDate;
  final String? id;
  final String? initialDestinationName;
  final DateTime? dispatchDate;
  final String? remarks;
  final List<String> attachments;
  final List<dynamic> statusHistory;
  final List<dynamic> supplierMovements;

  // New Fields
  final String? jobType;
  final String? customerName;
  final String? wheelSize;
  final String? diamondPowderGritSize;
  final String? assignedWorker;
  final DateTime? deliveryDate;
  final DateTime? customerOrderDate;
  final DateTime? customerSentDate;
  final DateTime? receivedDate;
  final bool? negotiationDone;
  final String? returnableGatePassNumber;
  final DateTime? returnableGatePassDate;
  
  final DateTime? extractionDate;
  final DateTime? expectedExtractionDate;
  final DateTime? extractionCompletedDate;
  final DateTime? productionDate;
  final DateTime? expectedProductionDate;

  final bool? purchaseOrderReceived;
  final String? purchaseOrderNumber;
  final DateTime? purchaseOrderDate;
  final bool poNotGiven;
  
  final String? inspectionReportNumber;
  final String? invoiceNumber;

  final bool sentToSpare;
  final String? usedSpareId;

  final String? edpPurchaseOrderNumber;
  final DateTime? edpPurchaseOrderDate;

  final String? supplierPurchaseOrderNumber;
  final DateTime? supplierPurchaseOrderDate;
  final int? forwardQuantity;
  final String? deliveryChalanNumber;
  final DateTime? deliveryChalanDate;

  JobModel({
    this.id,
    required this.jobId,
    this.partNumber,
    this.partDescription,
    this.quantity,
    this.numberOfBins = 0,
    this.numberOfBoxes = 0,
    this.logisticsName,
    this.deliveredQuantity,
    this.returnedQuantity,
    this.destinationType,
    this.destinationName,
    this.initialDestinationName,
    this.processType,
    this.vehicleNumber,
    this.driverName,
    this.driverMobile,
    this.dispatchDate,
    required this.status,
    this.currentLocation = '',
    this.remarks,
    this.supplier,
    this.supplierChain = const [],
    this.expectedReturnDate,
    this.attachments = const [],
    this.statusHistory = const [],
    this.supplierMovements = const [],
    required this.createdDate,
    this.jobType,
    this.customerName,
    this.wheelSize,
    this.diamondPowderGritSize,
    this.assignedWorker,
    this.deliveryDate,
    this.customerOrderDate,
    this.customerSentDate,
    this.receivedDate,
    this.negotiationDone,
    this.returnableGatePassNumber,
    this.returnableGatePassDate,
    this.extractionDate,
    this.expectedExtractionDate,
    this.extractionCompletedDate,
    this.productionDate,
    this.expectedProductionDate,
    this.purchaseOrderReceived,
    this.purchaseOrderNumber,
    this.purchaseOrderDate,
    this.poNotGiven = false,
    this.inspectionReportNumber,
    this.invoiceNumber,
    this.sentToSpare = false,
    this.usedSpareId,
    this.edpPurchaseOrderNumber,
    this.edpPurchaseOrderDate,
    this.supplierPurchaseOrderNumber,
    this.supplierPurchaseOrderDate,
    this.forwardQuantity,
    this.deliveryChalanNumber,
    this.deliveryChalanDate,
  });

  JobModel copyWith({
    String? id,
    String? jobId,
    String? partNumber,
    String? partDescription,
    int? quantity,
    int? numberOfBins,
    int? numberOfBoxes,
    String? logisticsName,
    int? deliveredQuantity,
    int? returnedQuantity,
    String? destinationType,
    String? destinationName,
    String? processType,
    String? vehicleNumber,
    String? driverName,
    String? driverMobile,
    String? status,
    String? currentLocation,
    String? supplier,
    List<String>? supplierChain,
    DateTime? expectedReturnDate,
    DateTime? createdDate,
    String? jobType,
    String? customerName,
    String? wheelSize,
    String? diamondPowderGritSize,
    String? assignedWorker,
    DateTime? deliveryDate,
    DateTime? customerOrderDate,
    DateTime? customerSentDate,
    DateTime? receivedDate,
    bool? negotiationDone,
    String? returnableGatePassNumber,
    DateTime? returnableGatePassDate,
    DateTime? extractionDate,
    DateTime? expectedExtractionDate,
    DateTime? extractionCompletedDate,
    DateTime? productionDate,
    DateTime? expectedProductionDate,
    bool? purchaseOrderReceived,
    String? purchaseOrderNumber,
    DateTime? purchaseOrderDate,
    bool? poNotGiven,
    String? inspectionReportNumber,
    String? initialDestinationName,
    DateTime? dispatchDate,
    String? remarks,
    List<String>? attachments,
    List<dynamic>? statusHistory,
    List<dynamic>? supplierMovements,
    String? invoiceNumber,
    bool? sentToSpare,
    String? usedSpareId,
    String? edpPurchaseOrderNumber,
    DateTime? edpPurchaseOrderDate,
    String? supplierPurchaseOrderNumber,
    DateTime? supplierPurchaseOrderDate,
    int? forwardQuantity,
    String? deliveryChalanNumber,
    DateTime? deliveryChalanDate,
  }) {
    return JobModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      partNumber: partNumber ?? this.partNumber,
      partDescription: partDescription ?? this.partDescription,
      quantity: quantity ?? this.quantity,
      numberOfBins: numberOfBins ?? this.numberOfBins,
      numberOfBoxes: numberOfBoxes ?? this.numberOfBoxes,
      logisticsName: logisticsName ?? this.logisticsName,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      destinationType: destinationType ?? this.destinationType,
      destinationName: destinationName ?? this.destinationName,
      initialDestinationName: initialDestinationName ?? this.initialDestinationName,
      processType: processType ?? this.processType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverMobile: driverMobile ?? this.driverMobile,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      remarks: remarks ?? this.remarks,
      supplier: supplier ?? this.supplier,
      supplierChain: supplierChain ?? this.supplierChain,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      attachments: attachments ?? this.attachments,
      statusHistory: statusHistory ?? this.statusHistory,
      supplierMovements: supplierMovements ?? this.supplierMovements,
      createdDate: createdDate ?? this.createdDate,
      jobType: jobType ?? this.jobType,
      customerName: customerName ?? this.customerName,
      wheelSize: wheelSize ?? this.wheelSize,
      diamondPowderGritSize: diamondPowderGritSize ?? this.diamondPowderGritSize,
      assignedWorker: assignedWorker ?? this.assignedWorker,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      customerOrderDate: customerOrderDate ?? this.customerOrderDate,
      customerSentDate: customerSentDate ?? this.customerSentDate,
      receivedDate: receivedDate ?? this.receivedDate,
      negotiationDone: negotiationDone ?? this.negotiationDone,
      returnableGatePassNumber: returnableGatePassNumber ?? this.returnableGatePassNumber,
      returnableGatePassDate: returnableGatePassDate ?? this.returnableGatePassDate,
      extractionDate: extractionDate ?? this.extractionDate,
      expectedExtractionDate: expectedExtractionDate ?? this.expectedExtractionDate,
      extractionCompletedDate: extractionCompletedDate ?? this.extractionCompletedDate,
      productionDate: productionDate ?? this.productionDate,
      expectedProductionDate: expectedProductionDate ?? this.expectedProductionDate,
      purchaseOrderReceived: purchaseOrderReceived ?? this.purchaseOrderReceived,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      purchaseOrderDate: purchaseOrderDate ?? this.purchaseOrderDate,
      poNotGiven: poNotGiven ?? this.poNotGiven,
      inspectionReportNumber: inspectionReportNumber ?? this.inspectionReportNumber,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      sentToSpare: sentToSpare ?? this.sentToSpare,
      usedSpareId: usedSpareId ?? this.usedSpareId,
      edpPurchaseOrderNumber: edpPurchaseOrderNumber ?? this.edpPurchaseOrderNumber,
      edpPurchaseOrderDate: edpPurchaseOrderDate ?? this.edpPurchaseOrderDate,
      supplierPurchaseOrderNumber: supplierPurchaseOrderNumber ?? this.supplierPurchaseOrderNumber,
      supplierPurchaseOrderDate: supplierPurchaseOrderDate ?? this.supplierPurchaseOrderDate,
      forwardQuantity: forwardQuantity ?? this.forwardQuantity,
      deliveryChalanNumber: deliveryChalanNumber ?? this.deliveryChalanNumber,
      deliveryChalanDate: deliveryChalanDate ?? this.deliveryChalanDate,
    );
  }

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
    id: json['_id'] as String?,
    jobId: json['jobId'] ?? '',
    partNumber: json['partNumber'],
    partDescription: json['partDescription'],
    quantity: json['quantity'],
    numberOfBins: json['numberOfBins'] ?? 0,
    numberOfBoxes: json['numberOfBoxes'] ?? 0,
    logisticsName: json['logisticsName'],
    deliveredQuantity: json['deliveredQuantity'],
    returnedQuantity: json['returnedQuantity'],
    destinationType: json['destinationType'],
    destinationName: json['destinationName'],
    initialDestinationName: json['initialDestinationName'],
    processType: json['processType'],
    vehicleNumber: json['vehicleNumber'],
    driverName: json['driverName'],
    driverMobile: json['driverMobile'],
    dispatchDate: json['dispatchDate'] != null ? DateTime.parse(json['dispatchDate']) : null,
    status: json['status'] ?? 'Created',
    currentLocation: json['currentLocation'] ?? '',
    remarks: json['remarks'],
    supplier: json['supplier'],
    supplierChain: (json['supplierChain'] as List?)?.map((e) => e.toString()).toList() ?? [],
    expectedReturnDate: json['expectedReturnDate'] != null ? DateTime.parse(json['expectedReturnDate']) : null,
    attachments: (json['attachments'] as List?)?.map((e) => e.toString()).toList() ?? [],
    statusHistory: (json['statusHistory'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    supplierMovements: (json['supplierMovements'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    createdDate: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    jobType: json['jobType'],
    customerName: json['customerName'],
    wheelSize: json['wheelSize'],
    diamondPowderGritSize: json['diamondPowderGritSize'],
    assignedWorker: json['assignedWorker'],
    deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
    customerOrderDate: json['customerOrderDate'] != null ? DateTime.parse(json['customerOrderDate']) : null,
    customerSentDate: json['customerSentDate'] != null ? DateTime.parse(json['customerSentDate']) : null,
    receivedDate: json['receivedDate'] != null ? DateTime.parse(json['receivedDate']) : null,
    negotiationDone: json['negotiationDone'],
    returnableGatePassNumber: json['returnableGatePassNumber'],
    returnableGatePassDate: json['returnableGatePassDate'] != null ? DateTime.parse(json['returnableGatePassDate']) : null,
    extractionDate: json['extractionDate'] != null ? DateTime.parse(json['extractionDate']) : null,
    expectedExtractionDate: json['expectedExtractionDate'] != null ? DateTime.parse(json['expectedExtractionDate']) : null,
    extractionCompletedDate: json['extractionCompletedDate'] != null ? DateTime.parse(json['extractionCompletedDate']) : null,
    productionDate: json['productionDate'] != null ? DateTime.parse(json['productionDate']) : null,
    expectedProductionDate: json['expectedProductionDate'] != null ? DateTime.parse(json['expectedProductionDate']) : null,
    purchaseOrderReceived: json['purchaseOrderReceived'],
    purchaseOrderNumber: json['purchaseOrderNumber'],
    purchaseOrderDate: json['purchaseOrderDate'] != null ? DateTime.parse(json['purchaseOrderDate']) : null,
    poNotGiven: json['poNotGiven'] ?? false,
    inspectionReportNumber: json['inspectionReportNumber'],
    invoiceNumber: json['invoiceNumber'],
    sentToSpare: json['sentToSpare'] ?? false,
    usedSpareId: json['usedSpareId'],
    edpPurchaseOrderNumber: json['edpPurchaseOrderNumber'],
    edpPurchaseOrderDate: json['edpPurchaseOrderDate'] != null ? DateTime.parse(json['edpPurchaseOrderDate']) : null,
    supplierPurchaseOrderNumber: json['supplierPurchaseOrderNumber'],
    supplierPurchaseOrderDate: json['supplierPurchaseOrderDate'] != null ? DateTime.parse(json['supplierPurchaseOrderDate']) : null,
    forwardQuantity: json['forwardQuantity'],
    deliveryChalanNumber: json['deliveryChalanNumber'],
    deliveryChalanDate: json['deliveryChalanDate'] != null ? DateTime.parse(json['deliveryChalanDate']) : null,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'jobId': jobId,
    'partNumber': partNumber,
    'partDescription': partDescription,
    'quantity': quantity,
    'numberOfBins': numberOfBins,
    'numberOfBoxes': numberOfBoxes,
    'logisticsName': logisticsName,
    'deliveredQuantity': deliveredQuantity,
    'returnedQuantity': returnedQuantity,
    'destinationType': destinationType,
    'destinationName': destinationName,
    'initialDestinationName': initialDestinationName,
    'processType': processType,
    'vehicleNumber': vehicleNumber,
    'driverName': driverName,
    'driverMobile': driverMobile,
    'dispatchDate': dispatchDate?.toIso8601String(),
    'status': status,
    'currentLocation': currentLocation,
    'remarks': remarks,
    'supplier': supplier,
    'supplierChain': supplierChain,
    'expectedReturnDate': expectedReturnDate?.toIso8601String(),
    'attachments': attachments,
    'statusHistory': statusHistory,
    'supplierMovements': supplierMovements,
    'createdAt': createdDate.toIso8601String(),
    'jobType': jobType,
    'customerName': customerName,
    'wheelSize': wheelSize,
    'diamondPowderGritSize': diamondPowderGritSize,
    'assignedWorker': assignedWorker,
    'deliveryDate': deliveryDate?.toIso8601String(),
    'customerOrderDate': customerOrderDate?.toIso8601String(),
    'customerSentDate': customerSentDate?.toIso8601String(),
    'receivedDate': receivedDate?.toIso8601String(),
    'negotiationDone': negotiationDone,
    'returnableGatePassNumber': returnableGatePassNumber,
    'returnableGatePassDate': returnableGatePassDate?.toIso8601String(),
    'extractionDate': extractionDate?.toIso8601String(),
    'expectedExtractionDate': expectedExtractionDate?.toIso8601String(),
    'extractionCompletedDate': extractionCompletedDate?.toIso8601String(),
    'productionDate': productionDate?.toIso8601String(),
    'expectedProductionDate': expectedProductionDate?.toIso8601String(),
    'purchaseOrderReceived': purchaseOrderReceived,
    'purchaseOrderNumber': purchaseOrderNumber,
    'purchaseOrderDate': purchaseOrderDate?.toIso8601String(),
    'poNotGiven': poNotGiven,
    'inspectionReportNumber': inspectionReportNumber,
    'invoiceNumber': invoiceNumber,
    'sentToSpare': sentToSpare,
    'usedSpareId': usedSpareId,
    'edpPurchaseOrderNumber': edpPurchaseOrderNumber,
    'edpPurchaseOrderDate': edpPurchaseOrderDate?.toIso8601String(),
    'supplierPurchaseOrderNumber': supplierPurchaseOrderNumber,
    'supplierPurchaseOrderDate': supplierPurchaseOrderDate?.toIso8601String(),
    'forwardQuantity': forwardQuantity,
    'deliveryChalanNumber': deliveryChalanNumber,
    'deliveryChalanDate': deliveryChalanDate?.toIso8601String(),
  };
}
