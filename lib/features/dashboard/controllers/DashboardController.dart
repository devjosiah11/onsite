import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import '../../../models/session_model.dart';
import '../../../models/attendance_model.dart';
import '../../../services/session_service.dart';
import '../../../services/attendance_service.dart';

class DashboardController extends GetxController {
  final _sessionService = SessionService();
  final _attendanceService = AttendanceService();
  final _storage = GetStorage();

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  var todaySessions = <StudentSessionModel>[].obs;
  var attendanceStats = <AttendanceStatModel>[].obs;

  // ── Computed user info from stored login ──────────────────────────────────
  String get userName {
    final raw = _storage.read<Map>('user');
    if (raw != null) {
      final full = raw['fullName'] as String? ?? raw['full_name'] as String? ?? 'Student';
      return full.split(' ').first;
    }
    return 'Student';
  }

  String get userFullName {
    final raw = _storage.read<Map>('user');
    return raw?['fullName'] as String? ?? raw?['full_name'] as String? ?? 'Student';
  }

  // ── Computed stats ────────────────────────────────────────────────────────
  double get overallAttendance {
    if (attendanceStats.isEmpty) return 0.0;
    final total = attendanceStats.fold<int>(0, (s, e) => s + e.totalSessions);
    if (total == 0) return 0.0;
    final present = attendanceStats.fold<int>(0, (s, e) => s + e.presentCount);
    return (present / total) * 100;
  }

  /// Returns the first session the student can still sign into.
  StudentSessionModel? get activeSession {
    try {
      return todaySessions.firstWhere((s) => s.canSignIn);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final results = await Future.wait([
        _sessionService.getStudentSessionsToday(),
        _attendanceService.getHistory(),
      ]);

      todaySessions.value = results[0] as List<StudentSessionModel>;

      final historyData =
          (results[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      attendanceStats.value = (historyData['stats'] as List<dynamic>)
          .map((j) => AttendanceStatModel.fromJson(
              Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) {
      errorMessage.value = 'Could not load dashboard. Pull down to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Human-readable session time string.
  String sessionTimeLabel(StudentSessionModel s) {
    final fmt = DateFormat('hh:mm a');
    return fmt.format(s.startTime);
  }

  /// Status label shown per class item.
  String sessionStatusLabel(StudentSessionModel s) {
    if (s.alreadySigned) return 'ATTENDED';
    if (s.canSignIn) return 'OPEN';
    if (s.isOpen) return 'CLOSING';
    return 'CLOSED';
  }

  /// Color per session status (as int for use in Color()).
  int sessionColor(StudentSessionModel s) {
    if (s.alreadySigned) return 0xFF4CAF50;
    if (s.canSignIn) return 0xFF1E88E5;
    if (s.isOpen) return 0xFFFFA000;
    return 0xFF9E9E9E;
  }
}
