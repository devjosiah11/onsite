import 'dart:convert';
import '../core/config/app_config.dart';
import 'base_service.dart';

class AuthService extends BaseService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final raw = await post(AppConfig.baseUrl, AppConfig.login, {
      'email': email,
      'password': password,
    });
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await post(AppConfig.baseUrl, AppConfig.logout, {});
  }

  Future<Map<String, dynamic>> me() async {
    final raw = await get(AppConfig.baseUrl, AppConfig.me);
    return jsonDecode(raw as String) as Map<String, dynamic>;
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await post(AppConfig.baseUrl, AppConfig.changePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
