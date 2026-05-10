/// A single attendance log entry (from /api/student/attendance/history)
class AttendanceLogModel {
  final String id;
  final String status; // PRESENT | ABSENT | EXCUSED
  final DateTime? signedInAt;
  final String? signInMethod; // BIOMETRIC | PASSWORD
  final bool isFlagged;
  final String courseCode;
  final String courseName;
  final DateTime sessionDate;

  const AttendanceLogModel({
    required this.id,
    required this.status,
    required this.courseCode,
    required this.courseName,
    required this.sessionDate,
    this.signedInAt,
    this.signInMethod,
    this.isFlagged = false,
  });

  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
  bool get isExcused => status == 'EXCUSED';

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLogModel(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'ABSENT',
      courseCode: json['courseCode'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      sessionDate: DateTime.parse(json['sessionDate'].toString()).toLocal(),
      signedInAt: json['signedInAt'] != null
          ? DateTime.parse(json['signedInAt'].toString()).toLocal()
          : null,
      signInMethod: json['signInMethod'] as String?,
      isFlagged: json['isFlagged'] as bool? ?? false,
    );
  }
}

/// Per-course attendance statistics
class AttendanceStatModel {
  final String courseId;
  final String courseCode;
  final String courseName;
  final int totalSessions;
  final int presentCount;
  final int absentCount;

  const AttendanceStatModel({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
  });

  double get attendancePct =>
      totalSessions > 0 ? (presentCount / totalSessions) * 100 : 0.0;

  factory AttendanceStatModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatModel(
      courseId: json['courseId'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      totalSessions: json['totalSessions'] as int? ?? 0,
      presentCount: json['presentCount'] as int? ?? 0,
      absentCount: json['absentCount'] as int? ?? 0,
    );
  }
}
