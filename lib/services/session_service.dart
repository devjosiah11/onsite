import 'dart:convert';
import '../core/config/app_config.dart';
import '../models/session_model.dart';
import 'base_service.dart';

class SessionService extends BaseService {
  // ── Student ───────────────────────────────────────────────────────────────

  Future<List<StudentSessionModel>> getStudentSessionsToday() async {
    final raw = await get(AppConfig.baseUrl, AppConfig.studentSessionsToday);
    final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
    final list = decoded['data'] as List<dynamic>;
    return list
        .map((j) => StudentSessionModel.fromJson(
            Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  // ── Lecturer / Admin ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getLecturerSessions({
    int page = 1,
    int limit = 30,
  }) async {
    final raw = await get(
      AppConfig.baseUrl,
      AppConfig.sessions,
      filters: {'page': page, 'limit': limit},
    );
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessionById(String sessionId) async {
    final raw =
        await get(AppConfig.baseUrl, '${AppConfig.sessions}/$sessionId');
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSession(
    String courseId,
    DateTime startTime, {
    int attendanceWindowMinutes = 15,
  }) async {
    final raw = await post(AppConfig.baseUrl, AppConfig.sessions, {
      'courseId': courseId,
      'startTime': startTime.toUtc().toIso8601String(),
      'attendanceWindowMinutes': attendanceWindowMinutes,
    });
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCourseLocation(
    String courseId,
    double lat,
    double lng, {
    double? radius,
  }) async {
    final url = AppConfig.updateCourseLocation.replaceFirst('{id}', courseId);
    final raw = await put(AppConfig.baseUrl, url, {
      'classroomGpsLat': lat,
      'classroomGpsLng': lng,
      if (radius != null) 'geofenceRadiusM': radius,
    });
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> closeSession(String sessionId) async {
    final raw = await patch(
        AppConfig.baseUrl, '${AppConfig.sessions}/$sessionId/close', {});
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final raw = await get(AppConfig.baseUrl, AppConfig.courses);
    final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(
        (decoded['data'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)));
  }
}
