class LeadModel {
  final String id;
  final String customerName;
  final String wheelSize;
  final String diamondPowderGritSize;
  final String assignedWorker;
  final bool quotationGiven;
  final bool negotiationDone;
  final String outcome;
  final String status;
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.customerName,
    required this.wheelSize,
    required this.diamondPowderGritSize,
    required this.assignedWorker,
    required this.quotationGiven,
    required this.negotiationDone,
    required this.outcome,
    required this.status,
    required this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) => LeadModel(
    id: json['_id'] ?? '',
    customerName: json['customerName'] ?? '',
    wheelSize: json['wheelSize'] ?? '',
    diamondPowderGritSize: json['diamondPowderGritSize'] ?? '',
    assignedWorker: json['assignedWorker'] ?? '',
    quotationGiven: json['quotationGiven'] ?? false,
    negotiationDone: json['negotiationDone'] ?? false,
    outcome: json['outcome'] ?? 'Pending',
    status: json['status'] ?? 'Quotation Pending',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'customerName': customerName,
    'wheelSize': wheelSize,
    'diamondPowderGritSize': diamondPowderGritSize,
    'assignedWorker': assignedWorker,
    'quotationGiven': quotationGiven,
    'negotiationDone': negotiationDone,
    'outcome': outcome,
    'status': status,
  };
}
