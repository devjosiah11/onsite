import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/LecturerController.dart';
import '../../../models/session_model.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/otp_service.dart';

class LecturerSessionsScreen extends StatelessWidget {
  const LecturerSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LecturerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Session History',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: controller.fetchAll,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.sessions.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }

        if (controller.sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No sessions found', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: controller.sessions.length,
          itemBuilder: (context, index) {
            final session = controller.sessions[index];
            return _buildHistoryCard(context, session, controller);
          },
        );
      }),
    );
  }

  Widget _buildHistoryCard(BuildContext context, LecturerSessionModel session, LecturerController controller) {
    final bool isLive = session.isLive;
    final pctVal = double.tryParse(session.pct.toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isLive ? AppColors.errorRed : AppColors.successGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLive ? 'LIVE' : 'CLOSED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isLive ? AppColors.errorRed : AppColors.successGreen,
                  ),
                ),
              ),
              Text(
                session.time,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.course,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${session.present} / ${session.total} Present',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              Row(
                children: [
                  if (isLive)
                    TextButton.icon(
                      onPressed: () => _showAttendanceQRDialog(session),
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('QR'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Get.toNamed('/session-detail', arguments: session.id),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttendanceQRDialog(LecturerSessionModel session) {
    final secret = session.otpSecret;
    if (secret == null) {
      Get.snackbar('Error', 'OTP Secret not found for this session.');
      return;
    }

    String currentOtp = OTPService.generateTOTP(secret);
    Timer? qrTimer;

    Get.dialog(
      StatefulBuilder(builder: (context, setDialogState) {
        qrTimer ??= Timer.periodic(const Duration(seconds: 30), (timer) {
          setDialogState(() {
            currentOtp = OTPService.generateTOTP(secret);
          });
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Student Scan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                Text('Show this to your students', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: secret,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 24),
                Text('OR ENTER CODE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(currentOtp, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryBlue, letterSpacing: 4)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      }),
    ).then((_) => qrTimer?.cancel());
  }
}
