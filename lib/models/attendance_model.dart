class AttendanceModel {
  final String id;
  final String? employeeId;
  final String employeeEmail;
  final String employeeName;
  final String? role;
  final String? department;
  final String date;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final int totalDurationMinutes;
  final double regularHours;
  final double overtimeHours;
  final String status;
  final String scanMethod;
  final String? notes;

  AttendanceModel({
    required this.id,
    this.employeeId,
    required this.employeeEmail,
    required this.employeeName,
    this.role,
    this.department,
    required this.date,
    this.clockInTime,
    this.clockOutTime,
    required this.totalDurationMinutes,
    required this.regularHours,
    required this.overtimeHours,
    required this.status,
    required this.scanMethod,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return AttendanceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString(),
      employeeEmail: json['employeeEmail']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      role: json['role']?.toString(),
      department: json['department']?.toString(),
      date: json['date']?.toString() ?? '',
      clockInTime: parseDate(json['clockInTime']),
      clockOutTime: parseDate(json['clockOutTime']),
      totalDurationMinutes: (json['totalDurationMinutes'] as num?)?.toInt() ?? 0,
      regularHours: parseDouble(json['regularHours']),
      overtimeHours: parseDouble(json['overtimeHours']),
      status: json['status']?.toString() ?? 'Clocked In',
      scanMethod: json['scanMethod']?.toString() ?? 'face_recognition',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'employeeEmail': employeeEmail,
    'employeeName': employeeName,
    'role': role,
    'department': department,
    'date': date,
    'clockInTime': clockInTime?.toUtc().toIso8601String(),
    'clockOutTime': clockOutTime?.toUtc().toIso8601String(),
    'totalDurationMinutes': totalDurationMinutes,
    'regularHours': regularHours,
    'overtimeHours': overtimeHours,
    'status': status,
    'scanMethod': scanMethod,
    'notes': notes,
  };
}

class EnrolledEmployeeModel {
  final String id;
  final String email;
  final String name;
  final String department;
  final String role;
  final bool isFaceEnrolled;
  final List<double> faceEmbeddings;
  final String? facePhotoUrl;
  final DateTime? lastEnrolledAt;

  EnrolledEmployeeModel({
    required this.id,
    required this.email,
    required this.name,
    required this.department,
    required this.role,
    required this.isFaceEnrolled,
    required this.faceEmbeddings,
    this.facePhotoUrl,
    this.lastEnrolledAt,
  });

  factory EnrolledEmployeeModel.fromJson(Map<String, dynamic> json) {
    List<double> embeddings = [];
    if (json['faceEmbeddings'] != null && json['faceEmbeddings'] is List) {
      embeddings = (json['faceEmbeddings'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    DateTime? enrolledAt;
    if (json['lastEnrolledAt'] != null) {
      try {
        enrolledAt = DateTime.parse(json['lastEnrolledAt'].toString()).toLocal();
      } catch (_) {}
    }

    return EnrolledEmployeeModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['email']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Production',
      role: json['role']?.toString() ?? 'employee',
      isFaceEnrolled: json['isFaceEnrolled'] == true,
      faceEmbeddings: embeddings,
      facePhotoUrl: json['facePhotoUrl']?.toString(),
      lastEnrolledAt: enrolledAt,
    );
  }
}

class MonthlyAttendanceSummary {
  final String employeeEmail;
  final String employeeName;
  final String? role;
  final String? department;
  final int daysWorked;
  final double totalRegularHours;
  final double totalOvertimeHours;
  final double totalHours;

  MonthlyAttendanceSummary({
    required this.employeeEmail,
    required this.employeeName,
    this.role,
    this.department,
    required this.daysWorked,
    required this.totalRegularHours,
    required this.totalOvertimeHours,
    required this.totalHours,
  });

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return MonthlyAttendanceSummary(
      employeeEmail: json['employeeEmail']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      role: json['role']?.toString(),
      department: json['department']?.toString(),
      daysWorked: (json['daysWorked'] as num?)?.toInt() ?? 0,
      totalRegularHours: parseDouble(json['totalRegularHours']),
      totalOvertimeHours: parseDouble(json['totalOvertimeHours']),
      totalHours: parseDouble(json['totalHours']),
    );
  }
}
