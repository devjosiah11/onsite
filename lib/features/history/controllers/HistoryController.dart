import 'package:get/get.dart';
import '../../../models/attendance_model.dart';
import '../../../services/attendance_service.dart';

class HistoryController extends GetxController {
  final _service = AttendanceService();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var logs = <AttendanceLogModel>[].obs;
  var stats = <AttendanceStatModel>[].obs;

  // ── Computed ──────────────────────────────────────────────────────────────
  int get totalPresent => logs.where((l) => l.isPresent).length;
  int get totalAbsent => logs.where((l) => l.isAbsent).length;
  int get totalExcused => logs.where((l) => l.isExcused).length;

  double get overallRate {
    if (logs.isEmpty) return 0.0;
    return (totalPresent / logs.length) * 100;
  }

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getHistory();
      final data = response['data'] as Map<String, dynamic>;

      logs.value = (data['logs'] as List<dynamic>)
          .map((j) => AttendanceLogModel.fromJson(
              Map<String, dynamic>.from(j as Map)))
          .toList();

      stats.value = (data['stats'] as List<dynamic>)
          .map((j) => AttendanceStatModel.fromJson(
              Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (_) {
      errorMessage.value = 'Failed to load attendance history.';
    } finally {
      isLoading.value = false;
    }
  }
}
