import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../features/dashboard/views/StudentDashboard.dart';
import '../features/history/views/HistoryScreen.dart';
import '../features/profile/views/ProfileScreen.dart';
import 'NavigationController.dart';

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController controller = Get.put(NavigationController());

    final List<Widget> screens = [
      const StudentDashboard(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: screens,
      )),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  controller: controller,
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'HOME',
                ),
                _buildNavItem(
                  controller: controller,
                  index: 1,
                  icon: Icons.history_rounded,
                  label: 'HISTORY',
                ),
                _buildNavItem(
                  controller: controller,
                  index: 2,
                  icon: Icons.person_rounded,
                  label: 'PROFILE',
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildNavItem({
    required NavigationController controller,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = controller.selectedIndex.value == index;
    
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryBlue : AppColors.textSecondary.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.primaryBlue : AppColors.textSecondary.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

