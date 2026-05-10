/// Student-facing session (from GET /api/student/sessions/today)
class StudentSessionModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String lecturerName;
  final DateTime startTime;
  final DateTime attendanceWindowClosesAt;
  final String status; // OPEN | CLOSED
  final String myStatus; // PRESENT | ABSENT | NOT_SIGNED
  final double? classroomGpsLat;
  final double? classroomGpsLng;
  final int geofenceRadiusM;

  const StudentSessionModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.lecturerName,
    required this.startTime,
    required this.attendanceWindowClosesAt,
    required this.status,
    required this.myStatus,
    this.classroomGpsLat,
    this.classroomGpsLng,
    this.geofenceRadiusM = 30,
  });

  bool get isOpen => status == 'OPEN';
  bool get alreadySigned => myStatus == 'PRESENT' || myStatus == 'EXCUSED';
  bool get canSignIn =>
      isOpen &&
      myStatus == 'NOT_SIGNED' &&
      DateTime.now().toUtc().isBefore(attendanceWindowClosesAt);

  String get courseLabel => '$courseCode — $courseName';

  factory StudentSessionModel.fromJson(Map<String, dynamic> json) {
    return StudentSessionModel(
      id: json['id'] as String,
      courseCode: json['courseCode'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      lecturerName: json['lecturerName'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'].toString()).toLocal(),
      attendanceWindowClosesAt:
          DateTime.parse(json['attendanceWindowClosesAt'].toString()).toLocal(),
      status: json['status'] as String? ?? 'CLOSED',
      myStatus: json['myStatus'] as String? ?? 'NOT_SIGNED',
      classroomGpsLat: json['classroomGpsLat'] != null
          ? double.tryParse(json['classroomGpsLat'].toString())
          : null,
      classroomGpsLng: json['classroomGpsLng'] != null
          ? double.tryParse(json['classroomGpsLng'].toString())
          : null,
      geofenceRadiusM:
          int.tryParse(json['geofenceRadiusM']?.toString() ?? '30') ?? 30,
    );
  }
}

/// Lecturer-facing session (from GET /api/sessions)
class LecturerSessionModel {
  final String id;
  final String course; // "CODE — Name"
  final String lecturer;
  final String date; // "YYYY-MM-DD" in LOCAL time
  final String time; // "09:00 AM — 10:00 AM" in LOCAL time
  final DateTime startTime;
  final int present;
  final int absent;
  final dynamic pct;
  final String status; // "open" | "closed"
  final String? otpSecret;

  const LecturerSessionModel({
    required this.id,
    required this.course,
    required this.lecturer,
    required this.date,
    required this.time,
    required this.startTime,
    required this.present,
    required this.absent,
    required this.pct,
    required this.status,
    this.otpSecret,
  });

  bool get isLive => status == 'open';
  int get total => present + absent;

  factory LecturerSessionModel.fromJson(Map<String, dynamic> json) {
    // Parse ISO timestamps → local (EAT) time
    final startIso = json['startTimeIso'] as String?;
    final endIso   = json['endTimeIso']   as String?;

    final startLocal = startIso != null
        ? DateTime.parse(startIso).toLocal()
        : DateTime.now();
    final endLocal = endIso != null ? DateTime.parse(endIso).toLocal() : null;

    String _fmt(DateTime d) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $p';
    }

    final timeStr = endLocal != null
        ? '${_fmt(startLocal)} — ${_fmt(endLocal)}'
        : _fmt(startLocal);

    final dateStr =
        '${startLocal.year}-${startLocal.month.toString().padLeft(2, '0')}-${startLocal.day.toString().padLeft(2, '0')}';

    return LecturerSessionModel(
      id: json['id'] as String,
      course: json['course'] as String? ?? '',
      lecturer: json['lecturer'] as String? ?? '',
      date: dateStr,
      time: timeStr,
      startTime: startLocal,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      pct: json['pct'] ?? 0,
      status: json['status'] as String? ?? 'closed',
      otpSecret: json['otpSecret'] as String?,
    );
  }
}
