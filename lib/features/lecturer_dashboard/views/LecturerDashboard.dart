import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/otp_service.dart';
import '../../../models/session_model.dart';
import '../controllers/LecturerController.dart';

class LecturerDashboard extends StatelessWidget {
  const LecturerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final LecturerController controller = Get.put(LecturerController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchAll,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${controller.lecturerName} 👋',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'LECTURER',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: Text(
                          controller.lecturerName.isNotEmpty
                              ? controller.lecturerName[0].toUpperCase()
                              : 'L',
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
                  if (controller.errorMessage.value.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(controller.errorMessage.value,
                          style: GoogleFonts.inter(
                              color: AppColors.errorRed, fontSize: 13)),
                    ),
                  Row(
                    children: [
                      _buildStatCard('${controller.totalEnrolled.value}', 'Students',
                          Icons.group_outlined, AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      _buildStatCard('${controller.liveCount}', 'Live Now',
                          Icons.radio_button_checked, AppColors.errorRed),
                      const SizedBox(width: 12),
                      _buildStatCard('${controller.courses.length}', 'Courses',
                          Icons.book_outlined, AppColors.successGreen),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Today's Sessions",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.todaySessions.isEmpty)
                    _emptyState('No sessions scheduled for today.')
                  else
                    ...controller.todaySessions
                        .map((s) => _buildSessionCard(s, controller))
                        .toList(),
                  if (controller.sessions.isNotEmpty &&
                      controller.todaySessions.length < controller.sessions.length) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Recent Sessions',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...controller.sessions
                        .where((s) => !controller.todaySessions.contains(s))
                        .take(5)
                        .map((s) => _buildSessionCard(s, controller))
                        .toList(),
                  ],
                  const SizedBox(height: 100),
                ],
              );
            }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSessionDialog(context, controller),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Open Session',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppColors.textSecondary)),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      LecturerSessionModel session, LecturerController controller) {
    final pctVal = double.tryParse(session.pct.toString()) ?? 0.0;
    final isLive = session.isLive;

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
                  session.course,
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
                  color: (isLive
                          ? AppColors.errorRed
                          : AppColors.successGreen)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: isLive
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'LIVE' : 'CLOSED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLive
                            ? AppColors.errorRed
                            : AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.time,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pctVal / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                pctVal >= 75
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${session.present} Present · ${session.absent} Absent',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${pctVal.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: pctVal >= 75
                      ? AppColors.successGreen
                      : AppColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Get.toNamed('/session-detail', arguments: session.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'View Report',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAttendanceQRDialog(session),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('QR'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmClose(session, controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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

  void _confirmClose(
      LecturerSessionModel session, LecturerController controller) {
    Get.defaultDialog(
      title: 'Close Session',
      titleStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      middleText:
          'Are you sure you want to close ${session.course}? Students will no longer be able to sign in.',
      middleTextStyle:
          GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
      textCancel: 'Cancel',
      textConfirm: 'Close',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.errorRed,
      onConfirm: () {
        Get.back();
        controller.closeSession(session.id);
      },
    );
  }

  void _showCreateSessionDialog(
      BuildContext context, LecturerController controller) {
    String? selectedCourseId;
    int windowMinutes = 15;
    DateTime selectedDateTime = DateTime.now();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open New Session',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Select Course',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.primaryBlue.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: controller.courses.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text(c['courseName'] as String),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedCourseId = v),
                  hint: const Text('Select a course'),
                ),
                const SizedBox(height: 20),
                
                // Date/Time Picker
                Text('Start Time',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now().subtract(const Duration(days: 7)),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                Text('Attendance Window',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [15, 30, 45, 60].map((m) {
                    final isSelected = windowMinutes == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$m min'),
                        selected: isSelected,
                        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                        onSelected: (s) {
                          setState(() => windowMinutes = m);
                        },
                      ),
                    );
                  }).toList(),
                ),
                
                if (selectedCourseId != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Update Course Location',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latController,
                          decoration: InputDecoration(
                            hintText: 'Latitude',
                            filled: true,
                            fillColor: AppColors.primaryBlue.withOpacity(0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lngController,
                          decoration: InputDecoration(
                            hintText: 'Longitude',
                            filled: true,
                            fillColor: AppColors.primaryBlue.withOpacity(0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final lat = double.tryParse(latController.text);
                            final lng = double.tryParse(lngController.text);
                            if (lat != null && lng != null) {
                              controller.updateCourseLocationManual(selectedCourseId!, lat, lng);
                            } else {
                              Get.snackbar('Error', 'Invalid coordinates');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Save Manual'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.updateCourseLocationGPS(selectedCourseId!),
                          icon: const Icon(Icons.gps_fixed, size: 16),
                          label: const Text('Use GPS'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedCourseId != null) {
                        Get.back();
                        controller.createSession(selectedCourseId!, windowMinutes, startTime: selectedDateTime);
                      } else {
                        Get.snackbar('Error', 'Please select a course',
                            snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('CREATE SESSION',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}
