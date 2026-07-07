class NotificationModel {
  final String id;
  final String message;
  final DateTime timestamp;
  final String type; // 'completed' | 'delayed'
  final bool read;

  NotificationModel({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.type,
    this.read = false,
  });
}
