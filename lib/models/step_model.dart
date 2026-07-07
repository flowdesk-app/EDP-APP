enum StepStatus { pending, inProgress, completed }

StepStatus stepStatusFromString(String s) {
  switch (s) {
    case 'in_progress':
      return StepStatus.inProgress;
    default:
      return StepStatus.pending;
  }
}

String stepStatusToString(StepStatus s) {
  switch (s) {
    case StepStatus.inProgress:
      return 'in_progress';
    default:
      return 'pending';
  }
}

String stepStatusLabel(StepStatus s) {
  switch (s) {
    case StepStatus.inProgress:
      return 'In Progress';
    default:
      return 'Pending';
  }
}

class StepModel {
  final int stepNo;
  final String process;
  final String supplierId;
  final DateTime deadline;
  StepStatus status;
  final int completedQuantity;

  StepModel({
    required this.stepNo,
    required this.process,
    required this.supplierId,
    required this.deadline,
    this.status = StepStatus.pending,
    this.completedQuantity = 0,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) => StepModel(
    stepNo: json['stepNo'] as int,
    process: json['process'] as String,
    supplierId: json['supplierId'] as String,
    deadline: DateTime.parse(json['deadline'] as String),
    status: stepStatusFromString(json['status'] as String),
    completedQuantity: json['completedQuantity'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'stepNo': stepNo,
    'process': process,
    'supplierId': supplierId,
    'deadline': deadline.toIso8601String(),
    'status': stepStatusToString(status),
    'completedQuantity': completedQuantity,
  };
}
