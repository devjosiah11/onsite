import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/app_exceptions.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var errorMessage = ''.obs;

  final _authService = AuthService();
  final _storage = GetStorage();

  var currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    final raw = _storage.read<Map>('user');
    if (raw != null) {
      currentUser.value =
          UserModel.fromJson(Map<String, dynamic>.from(raw));
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Please enter your email and password';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('[LOGIN] Attempting login for: ${email.trim()}');
      print('[LOGIN] Password length: ${password.length}');

      final response = await _authService.login(email.trim(), password);
      print('[LOGIN] Raw response: $response');

      final data = response['data'] as Map<String, dynamic>;
      print('[LOGIN] data keys: ${data.keys.toList()}');

      // Persist token
      final token = data['token'] as String;
      print('[LOGIN] Token (first 20 chars): ${token.substring(0, token.length.clamp(0, 20))}...');
      await _storage.write('access_token', token);

      // Persist user
      final userMap = Map<String, dynamic>.from(data['user'] as Map);
      print('[LOGIN] User map: $userMap');
      await _storage.write('user', userMap);
      await _storage.write('user_role', (userMap['role'] as String?) ?? '');
      print('[LOGIN] Stored role: ${userMap['role']}');

      final user = UserModel.fromJson(userMap);
      currentUser.value = user;
      print('[LOGIN] isStudent=${user.isStudent} isLecturer=${user.isLecturer}');

      // Route by role
      if (user.isStudent) {
        Get.offAllNamed('/nav');
      } else if (user.isLecturer) {
        Get.offAllNamed('/lecturer-dashboard');
      } else {
        errorMessage.value = 'Admin accounts are managed via the web portal';
      }
    } on UnAuthorizedException catch (e) {
      print('[LOGIN] UnAuthorizedException: ${e.message}');
      try {
        final body = jsonDecode(e.message ?? '{}') as Map<String, dynamic>;
        errorMessage.value = body['message'] as String? ??
            'Invalid email or password';
      } catch (_) {
        errorMessage.value = 'Invalid email or password';
      }
    } on BadRequestException catch (e) {
      print('[LOGIN] BadRequestException: ${e.message}');
      try {
        final body = jsonDecode(e.message ?? '{}') as Map<String, dynamic>;
        errorMessage.value =
            body['message'] as String? ?? 'Request error';
      } catch (_) {
        errorMessage.value = 'Request error. Please try again.';
      }
    } on FetchDataException catch (e) {
      print('[LOGIN] FetchDataException: ${e.message}');
      errorMessage.value = 'Server error: ${e.message}';
    } on ApiNotRespondingException catch (e) {
      print('[LOGIN] ApiNotRespondingException: ${e.message}');
      errorMessage.value = 'Request timed out. Check your internet connection.';
    } catch (e, st) {
      print('[LOGIN] Unknown error: $e');
      print('[LOGIN] Stack: $st');
      errorMessage.value = 'Connection failed (${e.runtimeType}): ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _storage.remove('access_token');
    await _storage.remove('user');
    await _storage.remove('user_role');
    currentUser.value = null;
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    super.onClose();
  }
}
