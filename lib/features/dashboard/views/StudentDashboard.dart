import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/session_model.dart';
import '../controllers/DashboardController.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchAll,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Header ──────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hi, ${controller.userName} 👋',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'STUDENT',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Text(
                        controller.userName.isNotEmpty
                            ? controller.userName[0].toUpperCase()
                            : 'S',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Loading / Error ──────────────────────────────────────────
                if (controller.isLoading.value)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBlue),
                    ),
                  )
                else if (controller.errorMessage.value.isNotEmpty)
                  _errorBanner(controller.errorMessage.value,
                      onRetry: controller.fetchAll)
                else ...[

                  // ── Today's Classes card ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Classes",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                color: Colors.white, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (controller.todaySessions.isEmpty)
                          Text(
                            'No classes scheduled for today.',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 14),
                          )
                        else
                          ...controller.todaySessions.map(
                              (s) => _buildClassItem(s, controller)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Mark Attendance card ──────────────────────────────────
                  _MarkAttendanceCard(controller: controller),

                  const SizedBox(height: 24),

                  // ── Stats row ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.trending_up,
                          value:
                              '${controller.overallAttendance.toStringAsFixed(1)}%',
                          label: 'Overall Attendance',
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          iconColor: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.school_outlined,
                          value:
                              '${controller.attendanceStats.length}',
                          label: 'Enrolled Courses',
                          color: AppColors.softCyan.withOpacity(0.3),
                          iconColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 100),
              ],
            )),
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(String msg, {required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.errorRed, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: GoogleFonts.inter(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassItem(
      StudentSessionModel s, DashboardController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(c.sessionColor(s)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.courseLabel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      c.sessionTimeLabel(s),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  c.sessionStatusLabel(s),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 12),
            child:
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkAttendanceCard extends StatelessWidget {
  final DashboardController controller;
  const _MarkAttendanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sessions = controller.todaySessions;
      if (sessions.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark Attendance',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...sessions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionSignInCard(session: s),
              )),
        ],
      );
    });
  }
}

class _SessionSignInCard extends StatelessWidget {
  final StudentSessionModel session;
  const _SessionSignInCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final canSign    = session.canSignIn;
    final attended   = session.alreadySigned;
    final buttonColor  = canSign ? null : Colors.grey.shade200;
    final textColor    = canSign ? Colors.white : Colors.grey.shade400;
    final iconColor    = canSign ? Colors.white : Colors.grey.shade400;
    final shadowColor  = canSign ? AppColors.secondaryBlue.withOpacity(0.4) : Colors.transparent;

    String buttonLabel;
    IconData buttonIcon;
    if (attended) {
      buttonLabel = 'ATTENDED';
      buttonIcon  = Icons.check_circle_outline;
    } else if (canSign) {
      buttonLabel = 'TAP TO SIGN IN';
      buttonIcon  = Icons.fingerprint;
    } else {
      buttonLabel = 'WINDOW CLOSED';
      buttonIcon  = Icons.lock_clock;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course + time row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.class_outlined,
                    color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.courseLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${DateFormat('hh:mm a').format(session.startTime)} — closes ${DateFormat('hh:mm a').format(session.attendanceWindowClosesAt)}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Geofence chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar, color: AppColors.primaryBlue, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Within ${session.geofenceRadiusM}m of classroom',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Sign-in button — active or greyed out
          GestureDetector(
            onTap: canSign
                ? () => Get.toNamed('/verify-location', arguments: session)
                : null,
            child: Container(
              height: 52,
              decoration: canSign ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ) : BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    buttonLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
