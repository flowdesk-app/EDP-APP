import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../widgets/global_logout_button.dart';
import 'face_attendance_terminal_screen.dart';
import 'face_enrollment_dialog.dart';

class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  final ApiService _api = ApiService();

  String _selectedMonth = 'November 2026';
  final List<String> _months = [
    'November 2026',
    'December 2026',
    'January 2027',
    'February 2027',
    'March 2027',
  ];

  bool _loading = true;
  List<EnrolledEmployeeModel> _employees = [];
  List<AttendanceModel> _todayAttendance = [];
  List<MonthlyAttendanceSummary> _monthlySummaries = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  String _getMonthKey(String monthStr) {
    if (monthStr.startsWith('November')) return '2026-11';
    if (monthStr.startsWith('December')) return '2026-12';
    if (monthStr.startsWith('January')) return '2027-01';
    if (monthStr.startsWith('February')) return '2027-02';
    if (monthStr.startsWith('March')) return '2027-03';
    return DateFormat('yyyy-MM').format(DateTime.now());
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final monthKey = _getMonthKey(_selectedMonth);
      final employees = await _api.getEnrolledEmployees();
      final todayRecords = await _api.getTodayAttendance();
      final summaries = await _api.getAttendanceSummary(month: monthKey);

      if (mounted) {
        setState(() {
          _employees = employees;
          _todayAttendance = todayRecords;
          _monthlySummaries = summaries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openFaceTerminal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceAttendanceTerminalScreen()),
    );
    _loadAllData();
  }

  void _openEnrollmentDialog(EnrolledEmployeeModel employee) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => FaceEnrollmentDialog(employee: employee),
    );
    if (updated == true) {
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payroll Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Exclusive Diamond Products • Employee Payroll System',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _api.currentUser?.email ?? 'payroll@flowdesk.com',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadAllData,
          ),
          const SizedBox(width: 4),
          const GlobalLogoutButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Welcome Banner with Terminal Launcher Button
                  _buildWelcomeBanner(),
                  const SizedBox(height: 20),

                  // Overview Metric KPI Cards
                  _buildMetricCards(),
                  const SizedBox(height: 24),

                  // Today's Live Attendance & Overtime Tracker Section
                  _buildTodayAttendanceSection(),
                  const SizedBox(height: 24),

                  // Employee Face Biometric & Payroll Roster
                  _buildEmployeeRosterSection(),
                  const SizedBox(height: 24),

                  // Monthly Overtime & Hours Ledger Section
                  _buildMonthlySummarySection(),
                  const SizedBox(height: 24),

                  // Upcoming Modular Extensions Preview
                  _buildPayrollModulesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0288D1), Color(0xFF01579B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Employee Attendance & Payroll Portal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Face recognition attendance terminal, 8-hour basic shift tracking, and automatic overtime calculation.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Open Face Attendance Terminal Button
          ElevatedButton.icon(
            onPressed: _openFaceTerminal,
            icon: const Icon(Icons.center_focus_strong, size: 18),
            label: const Text('Open Face Terminal', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: const Color(0xFF102A12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 3,
            ),
          ),
          const SizedBox(width: 12),

          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0288D1)),
                style: const TextStyle(
                  color: Color(0xFF0288D1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMonth = val);
                    _loadAllData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    final activeToday = _todayAttendance.where((p) => p.clockInTime != null && p.clockOutTime == null).length;
    final completedToday = _todayAttendance.where((p) => p.status == 'Completed').length;
    final totalOtToday = _todayAttendance.fold<double>(0.0, (sum, p) => sum + p.overtimeHours);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2;

        final metrics = [
          {
            'title': 'Active on Shift',
            'value': '$activeToday Employees',
            'subtitle': 'Clocked in right now',
            'icon': Icons.login,
            'color': const Color(0xFF1976D2),
            'bg': const Color(0xFFE3F2FD),
          },
          {
            'title': 'Completed Today',
            'value': '$completedToday Shifts',
            'subtitle': 'Finished & calculated',
            'icon': Icons.check_circle_outline,
            'color': const Color(0xFF2E7D32),
            'bg': const Color(0xFFE8F5E9),
          },
          {
            'title': "Today's Overtime",
            'value': '${totalOtToday.toStringAsFixed(1)} hrs',
            'subtitle': 'Over 8.0h shift time',
            'icon': Icons.timelapse,
            'color': const Color(0xFFF57C00),
            'bg': const Color(0xFFFFF3E0),
          },
          {
            'title': 'Enrolled Faces',
            'value': '${_employees.where((e) => e.isFaceEnrolled).length} / ${_employees.length}',
            'subtitle': 'Biometric registered',
            'icon': Icons.face_retouching_natural,
            'color': const Color(0xFF7B1FA2),
            'bg': const Color(0xFFF3E5F5),
          },
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.map((m) {
            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m['bg'] as Color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['value'] as String,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                        ),
                        Text(
                          m['subtitle'] as String,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTodayAttendanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Color(0xFF0288D1), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's Shift Attendance & Overtime Tracker",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                ),
              ),
              Text(
                DateFormat('dd MMMM yyyy').format(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 24),

          if (_todayAttendance.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.camera_front_outlined, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No punches recorded yet today.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Employees can scan in at the Face Attendance Terminal when starting their shift.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openFaceTerminal,
                      icon: const Icon(Icons.center_focus_strong, size: 16),
                      label: const Text('Open Terminal Screen'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayAttendance.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final p = _todayAttendance[index];
                final isCompleted = p.status == 'Completed';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFE1F5FE),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.login,
                          color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF0288D1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.employeeName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                            ),
                            Text(
                              p.department ?? 'Production',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'In: ${p.clockInTime != null ? DateFormat('hh:mm a').format(p.clockInTime!) : '--'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Out: ${p.clockOutTime != null ? DateFormat('hh:mm a').format(p.clockOutTime!) : 'On Shift'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: p.clockOutTime != null ? Colors.black87 : const Color(0xFF0288D1),
                                fontWeight: p.clockOutTime != null ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic: ${p.regularHours} hrs',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                            ),
                            Row(
                              children: [
                                Text(
                                  'OT: ${p.overtimeHours} hrs',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: p.overtimeHours > 0 ? FontWeight.bold : FontWeight.normal,
                                    color: p.overtimeHours > 0 ? const Color(0xFFE65100) : Colors.grey,
                                  ),
                                ),
                                if (p.overtimeHours > 0) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, color: Color(0xFFFFA000), size: 12),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isCompleted ? 'Shift Done' : 'On Shift',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF0288D1),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeRosterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: Color(0xFF0288D1), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Employee Biometric Roster & Face Enrollment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_employees.length} Staff Members',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0288D1)),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _employees.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final emp = _employees[index];
              final hasFace = emp.isFaceEnrolled;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        emp.name.isNotEmpty ? emp.name.substring(0, 1) : 'E',
                        style: const TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
                          ),
                          Text(
                            emp.email,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.department,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            emp.role,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasFace ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasFace ? Icons.check_circle : Icons.warning_amber_rounded,
                            size: 13,
                            color: hasFace ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasFace ? 'Face Enrolled' : 'Not Enrolled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hasFace ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openEnrollmentDialog(emp),
                      icon: const Icon(Icons.camera_alt, size: 14),
                      label: Text(hasFace ? 'Update Face' : 'Register Face', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasFace ? const Color(0xFF1976D2) : const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFF0288D1), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly Hours & Overtime Accumulation ($_selectedMonth)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '8h Basic Shift + OT Formula',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          if (_monthlySummaries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No shift records recorded yet for $_selectedMonth.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _monthlySummaries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (ctx, index) {
                final s = _monthlySummaries[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE1F5FE),
                        child: Text(
                          s.employeeName.isNotEmpty ? s.employeeName.substring(0, 1) : 'E',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0288D1)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.employeeName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              s.employeeEmail,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${s.daysWorked} Days Worked',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${s.totalRegularHours} hrs Basic',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.totalOvertimeHours > 0 ? const Color(0xFFFFF3E0) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${s.totalOvertimeHours} hrs Overtime',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: s.totalOvertimeHours > 0 ? const Color(0xFFE65100) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPayrollModulesSection() {
    final modules = [
      {
        'title': 'Salary Structure & Formulas',
        'desc': 'Basic pay, DA, HRA, incentives, overtime rates, and deduction rules.',
        'icon': Icons.calculate_outlined,
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Monthly Attendance & Leaves',
        'desc': 'Calendar working days, leaves, shift schedules, and holidays.',
        'icon': Icons.fact_check_outlined,
        'color': const Color(0xFF00897B),
      },
      {
        'title': 'Salary Slips & Registers',
        'desc': 'Instant PDF pay slip generation with print and download provisions.',
        'icon': Icons.picture_as_pdf_outlined,
        'color': const Color(0xFFF57C00),
      },
      {
        'title': 'Bank & Payment Disbursements',
        'desc': 'Payment summary, bank transfer registers, and employee payment records.',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF7B1FA2),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF0288D1), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Upcoming Payroll Configurations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ready for Custom Rules',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The attendance system is actively tracking 8-hour basic shifts and overtime hours. Additional salary rates, payslip templates, and deduction formulas will be added per your next instructions.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;
              final itemWidth = isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: modules.map((mod) {
                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (mod['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(mod['icon'] as IconData, color: mod['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mod['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF202124)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mod['desc'] as String,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
