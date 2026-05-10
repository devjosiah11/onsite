/// Single place to configure the backend URL.
///
/// Local development:
///   Android emulator  → http://10.0.2.2:5000
///   iOS simulator     → http://localhost:5000
///   Physical device   → http://<your-machine-LAN-IP>:5000
///
/// To switch to the hosted version, change [baseUrl] only here.
class AppConfig {
  static const String baseUrl = 'https://attendtrack-admin-production.up.railway.app';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String changePassword = '/api/auth/change-password';

  // ── Student (role=STUDENT protected) ──────────────────────────────────────
  static const String studentSessionsToday = '/api/student/sessions/today';
  static const String studentAttendanceHistory = '/api/student/attendance/history';

  // ── Attendance sign-in (role=STUDENT) ────────────────────────────────────
  static const String attendanceSignIn = '/api/attendance/sign-in';

  // ── Lecturer / Admin (role=LECTURER | ADMIN) ──────────────────────────────
  static const String sessions = '/api/sessions';
  static const String courses = '/api/courses';
  static const String updateCourseLocation = '/api/courses/{id}/location';
}
