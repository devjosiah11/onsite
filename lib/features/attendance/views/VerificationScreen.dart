import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/AttendanceController.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.put(AttendanceController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'UniAttend',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      body: Obx(() => _buildBody(context, controller)),
    );
  }

  Widget _buildBody(BuildContext context, AttendanceController c) {
    switch (c.status.value) {
      case AttendanceStatus.success:
        return _SuccessView(message: c.successMessage.value);

      case AttendanceStatus.error:
        return _ErrorView(
          message: c.errorMessage.value,
          onRetry: c.retryLocation,
        );

      default:
        return _MainView(controller: c);
    }
  }
}

// ── Main view (locating → ready → submitting) ─────────────────────────────────

class _MainView extends StatelessWidget {
  final AttendanceController controller;
  const _MainView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.status.value;
      final isLocating = status == AttendanceStatus.locating;
      final isReady = status == AttendanceStatus.ready;
      final isSubmitting = status == AttendanceStatus.submitting;
      final session = controller.session;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Radar rings
              Stack(
                alignment: Alignment.center,
                children: [
                  _RadarCircle(280, isLocating ? 0.03 : 0.06),
                  _RadarCircle(220, isLocating ? 0.06 : 0.1),
                  _RadarCircle(160, isLocating ? 0.09 : 0.15),
                  _RadarCircle(100, isLocating ? 0.12 : 0.22),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isReady
                            ? AppColors.successGreen
                            : AppColors.lightCyan,
                        width: 3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (isLocating || isSubmitting)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                          color: AppColors.primaryBlue, strokeWidth: 3),
                    )
                  else
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: isReady
                          ? AppColors.successGreen
                          : AppColors.primaryBlue,
                    ),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                isLocating
                    ? 'Acquiring GPS...'
                    : isSubmitting
                        ? 'Marking attendance...'
                        : 'Location confirmed',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session != null
                    ? 'Must be within ${session.geofenceRadiusM}m of classroom'
                    : 'Verifying your position...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Live coordinates chip
              if (isReady)
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primaryBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${controller.currentLat.value.toStringAsFixed(5)}  ·  '
                        'Lng: ${controller.currentLng.value.toStringAsFixed(5)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              if (isReady)
                Text(
                  'Accuracy: ±${controller.currentAccuracy.value.toStringAsFixed(1)}m',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),

              const SizedBox(height: 32),

              const SizedBox(height: 24),

              // QR & OTP Input
              if (isReady) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          onChanged: (v) => controller.otpCode.value = v,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4),
                          decoration: const InputDecoration(
                            hintText: '000000',
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => _openScanner(context, controller),
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          label: const Text('SCAN',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan the QR code on the lecturer\'s screen or enter the 6-digit code.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 32),

              // CTA button
              if (isReady)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    label: Text(
                      'CONFIRM ATTENDANCE',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: controller.submitAttendance,
                  ),
                ),

              if (isSubmitting)
                const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _openScanner(BuildContext context, AttendanceController controller) {
    Get.to(() => Scaffold(
          appBar: AppBar(title: const Text('Scan Attendance QR')),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.qrToken.value = barcode.rawValue!;
                  Get.back();
                  Get.snackbar('Success', 'QR Code scanned successfully!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white);
                  break;
                }
              }
            },
          ),
        ));
  }
}

// ── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String message;
  const _SuccessView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Attendance Marked!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off,
                  color: AppColors.errorRed, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Verification Failed',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radar ring helper ─────────────────────────────────────────────────────────

class _RadarCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _RadarCircle(this.size, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(opacity),
          width: 1,
        ),
      ),
    );
  }
}
