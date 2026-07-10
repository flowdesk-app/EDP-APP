class NotificationModel {
  final String id;
  final String message;
  final String type;
  final bool read;
  final String? jobId;
  final String? alertKey;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.read,
    this.jobId,
    this.alertKey,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      read: json['read'] ?? false,
      jobId: json['jobId'],
      alertKey: json['alertKey'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
