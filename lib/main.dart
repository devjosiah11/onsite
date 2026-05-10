import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/LoginScreen.dart';
import 'features/attendance/views/VerificationScreen.dart';
import 'features/profile/views/ProfileScreen.dart';
import 'features/lecturer_dashboard/views/LecturerSessionDetailScreen.dart';
import 'navigation/AppNavigator.dart';
import 'navigation/LecturerNavigator.dart';

String _startRoute = '/login';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final storage = GetStorage();
  final token = storage.read<String>('access_token');
  final role  = storage.read<String>('user_role') ?? '';
  if (token != null && token.isNotEmpty) {
    if (role == 'STUDENT') _startRoute = '/nav';
    else if (role == 'LECTURER') _startRoute = '/lecturer-dashboard';
  }
  runApp(const AttendSureApp());
}

class AttendSureApp extends StatelessWidget {
  const AttendSureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UniAttend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: _startRoute,
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/nav', page: () => const AppNavigator()),
        GetPage(name: '/verify-location', page: () => const VerificationScreen()),
        GetPage(name: '/lecturer-dashboard', page: () => const LecturerNavigator()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/session-detail', page: () => const LecturerSessionDetailScreen()),
      ],
    );
  }
}
