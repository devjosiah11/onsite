import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/session_model.dart';
import '../../../services/session_service.dart';

class LecturerController extends GetxController {
  final _sessionService = SessionService();
  final _storage = GetStorage();

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  var sessions = <LecturerSessionModel>[].obs;
  var courses = <Map<String, dynamic>>[].obs;
  var totalEnrolled = 0.obs;

  // ── User info ─────────────────────────────────────────────────────────────
  String get lecturerName {
    final raw = _storage.read('user');
    if (raw is Map) {
      return raw['fullName'] as String? ?? raw['full_name'] as String? ?? 'Lecturer';
    }
    return 'Lecturer';
  }

  // ── Derived ───────────────────────────────────────────────────────────────
  List<LecturerSessionModel> get todaySessions {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final filtered = sessions.where((s) => s.date == todayStr).toList();
    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));
    return filtered;
  }

  int get liveCount => todaySessions.where((s) => s.isLive).length;

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
        _sessionService.getLecturerSessions(limit: 50),
        _sessionService.getCourses(),
      ]);

      final sessionsData = results[0] as Map<String, dynamic>;
      final sessionsList = (sessionsData['data'] as List<dynamic>)
          .map((j) => LecturerSessionModel.fromJson(
              Map<String, dynamic>.from(j as Map)))
          .toList();
      
      sessionsList.sort((a, b) => b.startTime.compareTo(a.startTime));
      sessions.value = sessionsList;

      courses.value = results[1] as List<Map<String, dynamic>>;

      // Sum enrolled students across all courses this lecturer teaches
      totalEnrolled.value = courses.fold<int>(
          0, (sum, c) => sum + (c['enrolledCount'] as int? ?? 0));
    } catch (_) {
      errorMessage.value = 'Could not load data. Pull down to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> closeSession(String sessionId) async {
    try {
      await _sessionService.closeSession(sessionId);
      await fetchAll();
    } catch (_) {
      errorMessage.value = 'Failed to close session.';
    }
  }

  Future<void> createSession(String courseId, int windowMinutes, {DateTime? startTime}) async {
    try {
      isLoading.value = true;
      final time = startTime ?? DateTime.now();
      await _sessionService.createSession(courseId, time,
          attendanceWindowMinutes: windowMinutes);
      await fetchAll();
    } catch (e) {
      errorMessage.value = 'Failed to open session: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCourseLocationManual(String courseId, double lat, double lng) async {
    try {
      isLoading.value = true;
      await _sessionService.updateCourseLocation(courseId, lat, lng);
      Get.snackbar('Success', 'Course location updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCourseLocationGPS(String courseId) async {
    try {
      isLoading.value = true;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }
      
      Position position = await Geolocator.getCurrentPosition();
      await _sessionService.updateCourseLocation(courseId, position.latitude, position.longitude);
      Get.snackbar('Success', 'Course location updated via GPS');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update location: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
