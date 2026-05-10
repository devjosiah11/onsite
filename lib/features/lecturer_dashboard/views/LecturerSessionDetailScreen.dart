import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/session_service.dart';
import '../../../services/otp_service.dart';
import '../controllers/LecturerController.dart';

class LecturerSessionDetailScreen extends StatefulWidget {
  const LecturerSessionDetailScreen({super.key});

  @override
  State<LecturerSessionDetailScreen> createState() =>
      _LecturerSessionDetailScreenState();
}

class _LecturerSessionDetailScreenState
    extends State<LecturerSessionDetailScreen> {
  final _service = SessionService();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String _error = '';
  
  Timer? _qrTimer;
  String _currentOtp = '';

  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = Get.arguments as String;
    _load();
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final raw = await _service.getSessionById(_sessionId);
      setState(() => _detail = raw['data'] as Map<String, dynamic>?);
    } catch (e) {
      setState(() => _error = 'Could not load session. Pull down to retry.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _closeSession() async {
    final confirmed = await Get.defaultDialog<bool>(
      title: 'Close Session',
      titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      middleText:
          'Absent students will be marked automatically. This cannot be undone.',
      middleTextStyle:
          GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
      textCancel: 'Cancel',
      textConfirm: 'Close Session',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.errorRed,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );
    if (confirmed != true) return;

    try {
      await _service.closeSession(_sessionId);
      // Refresh parent controller if it's registered
      if (Get.isRegistered<LecturerController>()) {
        Get.find<LecturerController>().fetchAll();
      }
      await _load();
    } catch (_) {
      Get.snackbar('Error', 'Could not close session. Try again.',
          backgroundColor: AppColors.errorRed, colorText: Colors.white);
    }
  }

  void _showAttendanceQR() {
    final secret = _detail?['otpSecret'] as String?;
    if (secret == null) {
      Get.snackbar('Error', 'OTP Secret not found for this session.');
      return;
    }

    _currentOtp = OTPService.generateTOTP(secret);
    
    _qrTimer?.cancel();
    _qrTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _currentOtp = OTPService.generateTOTP(secret);
        });
      }
    });

    Get.dialog(
      StatefulBuilder(builder: (context, setDialogState) {
        // We need to trigger dialog rebuild when _currentOtp changes in the parent timer
        // but since we are using a separate timer, let's just make it simple
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Student Scan',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Show this to your students',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: secret, // Send the secret as the QR payload
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'OR ENTER CODE',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentOtp,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _qrTimer?.cancel();
                  Get.back();
                },
                child: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        );
      }),
    ).then((_) => _qrTimer?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Session Report',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _error.isNotEmpty
              ? _buildError()
              : _detail == null
                  ? const SizedBox()
                  : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              color: AppColors.textSecondary.withOpacity(0.4), size: 48),
          const SizedBox(height: 12),
          Text(_error,
              style:
                  GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    final course = d['course'] as Map<String, dynamic>? ?? {};
    final isOpen = (d['status'] as String?)?.toUpperCase() == 'OPEN';
    final students = d['students'] as List<dynamic>? ?? [];

    final startTime = d['startTime'] != null
        ? DateTime.parse(d['startTime'].toString()).toLocal()
        : null;

    String _fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $p';
    }

    final presentCount =
        students.where((s) => (s as Map)['status'] == 'PRESENT').length;
    final absentCount =
        students.where((s) => (s as Map)['status'] == 'ABSENT').length;
    final total = students.length;
    final pct = total > 0 ? (presentCount / total * 100) : 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${course['courseCode'] ?? ''} — ${course['courseName'] ?? ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isOpen
                                  ? AppColors.errorRed
                                  : AppColors.successGreen)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOpen ? 'LIVE' : 'CLOSED',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOpen
                                ? AppColors.errorRed
                                : AppColors.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (startTime != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${startTime.day}/${startTime.month}/${startTime.year}  ·  ${_fmt(startTime)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Stat row
                  Row(
                    children: [
                      _statChip('$presentCount Present',
                          AppColors.successGreen),
                      const SizedBox(width: 8),
                      _statChip('$absentCount Absent', AppColors.errorRed),
                      const SizedBox(width: 8),
                      _statChip(
                          '${pct.toStringAsFixed(0)}%', AppColors.primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 75
                            ? AppColors.successGreen
                            : AppColors.warningOrange,
                      ),
                    ),
                  ),
                  if (isOpen) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _closeSession,
                        icon: const Icon(Icons.lock_outline,
                            color: Colors.white, size: 18),
                        label: Text('Close Session',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showAttendanceQR,
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('Show Attendance QR', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Students (${students.length})',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (students.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('No students enrolled in this course.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13)),
              )
            else
              ...students.map((s) {
                final stu = s as Map<String, dynamic>;
                final status = (stu['status'] as String?) ?? 'ABSENT';
                final isPresent = status == 'PRESENT';
                final signIn = stu['signIn'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: (isPresent
                                ? AppColors.successGreen
                                : AppColors.errorRed)
                            .withOpacity(0.12),
                        child: Icon(
                          isPresent
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          size: 18,
                          color: isPresent
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stu['name'] as String? ?? '—',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (signIn != null)
                              Text(
                                'Signed in at $signIn',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPresent
                                  ? AppColors.successGreen
                                  : AppColors.errorRed)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPresent
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
