import 'dart:convert';
import '../core/config/app_config.dart';
import 'base_service.dart';

class AttendanceService extends BaseService {
  Future<Map<String, dynamic>> signIn({
    required String sessionId,
    required double gpsLat,
    required double gpsLng,
    required double gpsAccuracyM,
    String? deviceId,
    String? qrToken,
    String? otpCode,
    String signInMethod = 'PASSWORD',
  }) async {
    final payload = <String, dynamic>{
      'sessionId': sessionId,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'gpsAccuracyM': gpsAccuracyM,
      'signInMethod': signInMethod,
    };
    if (deviceId != null) payload['deviceId'] = deviceId;
    if (qrToken != null) payload['qrToken'] = qrToken;
    if (otpCode != null) payload['otpCode'] = otpCode;

    final raw =
        await post(AppConfig.baseUrl, AppConfig.attendanceSignIn, payload);
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHistory() async {
    final raw =
        await get(AppConfig.baseUrl, AppConfig.studentAttendanceHistory);
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }
}
