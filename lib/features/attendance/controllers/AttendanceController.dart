import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../models/session_model.dart';
import '../../../services/attendance_service.dart';
import '../../../services/app_exceptions.dart';
import '../../../services/biometric_service.dart';

enum AttendanceStatus { idle, locating, ready, submitting, success, error }

class AttendanceController extends GetxController {
  final _attendanceService = AttendanceService();

  var status = AttendanceStatus.idle.obs;
  var currentLat = 0.0.obs;
  var currentLng = 0.0.obs;
  var currentAccuracy = 0.0.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;
  
  var qrToken = ''.obs;
  var otpCode = ''.obs;
  
  final _biometricService = BiometricService();

  StudentSessionModel? session;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is StudentSessionModel) {
      session = args;
    }
    _acquireLocation();
  }

  Future<void> _acquireLocation() async {
    status.value = AttendanceStatus.locating;
    errorMessage.value = '';

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable GPS and try again.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setError(
            'Location permission denied. Please allow it in app settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      currentLat.value = position.latitude;
      currentLng.value = position.longitude;
      currentAccuracy.value = position.accuracy;

      if (position.isMocked) {
        _setError('Mock location detected! Please disable fake GPS apps.');
        return;
      }

      status.value = AttendanceStatus.ready;
    } catch (_) {
      _setError('Failed to get location. Please check GPS and try again.');
    }
  }

  Future<void> submitAttendance() async {
    if (session == null) {
      _setError('No session selected.');
      return;
    }
    if (status.value != AttendanceStatus.ready) return;

    try {
      status.value = AttendanceStatus.submitting;

      // 1. Biometric Check
      final canBio = await _biometricService.canAuthenticate();
      String method = 'PASSWORD';
      if (canBio) {
        final success = await _biometricService.authenticate();
        if (!success) {
          _setError('Biometric authentication failed or canceled.');
          return;
        }
        method = 'BIOMETRIC';
      }

      final deviceId = await _getDeviceId();

      await _attendanceService.signIn(
        sessionId: session!.id,
        gpsLat: currentLat.value,
        gpsLng: currentLng.value,
        gpsAccuracyM: currentAccuracy.value,
        deviceId: deviceId,
        qrToken: qrToken.value.isNotEmpty ? qrToken.value : null,
        otpCode: otpCode.value.isNotEmpty ? otpCode.value : null,
        signInMethod: method,
      );

      successMessage.value = 'Attendance marked successfully! 🎉';
      status.value = AttendanceStatus.success;

      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed('/nav');
    } on UnAuthorizedException catch (e) {
      _parseAndSetError(e.message, fallback: 'Not authorised for this session.');
    } on BadRequestException catch (e) {
      _parseAndSetError(e.message,
          fallback: 'Could not mark attendance. You may have already signed in.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  void retryLocation() {
    errorMessage.value = '';
    _acquireLocation();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _setError(String msg) {
    errorMessage.value = msg;
    status.value = AttendanceStatus.error;
  }

  void _parseAndSetError(String? rawBody, {required String fallback}) {
    try {
      final body = jsonDecode(rawBody ?? '{}') as Map<String, dynamic>;
      final error = body['error'] as String?;
      if (error == 'OUTSIDE_GEOFENCE') {
        final dist = body['distanceM'];
        _setError(
            'You are too far from the classroom (${dist?.toStringAsFixed(0) ?? '?'} m away). Move closer and try again.');
      } else if (error == 'DEVICE_MISMATCH') {
        _setError('This device is not registered for your account.');
      } else if (error == 'DUPLICATE') {
        _setError('You have already signed in to this session.');
      } else {
        _setError(body['message'] as String? ?? fallback);
      }
    } catch (_) {
      _setError(fallback);
    }
  }

  Future<String?> _getDeviceId() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.identifierForVendor;
      }
    } catch (_) {}
    return null;
  }
}
