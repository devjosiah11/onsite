import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/attendance_model.dart';
import '../controllers/HistoryController.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HistoryController());
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Attendance',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }

        if (_controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_controller.errorMessage.value,
                    style: GoogleFonts.inter(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _controller.fetchHistory,
                  child: Text('Retry',
                      style: GoogleFonts.inter(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchHistory,
          color: AppColors.primaryBlue,
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Summary Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSummaryCard(
                        '${_controller.totalPresent}',
                        'PRESENT',
                        const Color(0xFFE8F5E9),
                        const Color(0xFF4CAF50)),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                        '${_controller.totalAbsent}',
                        'ABSENT',
                        const Color(0xFFFFEBEE),
                        const Color(0xFFE53935)),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                        '${_controller.overallRate.toStringAsFixed(0)}%',
                        'RATE',
                        const Color(0xFFE3F2FD),
                        AppColors.primaryBlue),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryBlue,
                dividerColor: AppColors.border,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Present'),
                  Tab(text: 'Absent'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(null),
                    _buildList('PRESENT'),
                    _buildList('ABSENT'),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
      String value, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: textColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String? statusFilter) {
    final records = statusFilter == null
        ? _controller.logs
        : _controller.logs.where((l) => l.status == statusFilter).toList();

    if (records.isEmpty) {
      return Center(
        child: Text(
          statusFilter == null
              ? 'No attendance records yet.'
              : 'No ${statusFilter.toLowerCase()} records.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final log = records[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(AttendanceLogModel log) {
    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat('hh:mm a');

    final statusColor = log.isPresent
        ? const Color(0xFF4CAF50)
        : log.isExcused
            ? AppColors.warningOrange
            : const Color(0xFFE53935);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.courseLabel.isEmpty
                      ? '${log.courseCode} — ${log.courseName}'
                      : log.courseLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(log.sessionDate),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (log.signedInAt != null)
                  Text(
                    'Signed in: ${timeFmt.format(log.signedInAt!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                        radius: 3, backgroundColor: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      log.status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (log.isFlagged) ...[
                const SizedBox(height: 4),
                const Icon(Icons.flag, color: AppColors.warningOrange, size: 14),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

extension on AttendanceLogModel {
  String get courseLabel => '$courseCode — $courseName';
}
