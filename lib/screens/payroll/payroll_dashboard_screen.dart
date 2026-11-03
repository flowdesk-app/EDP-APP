import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import 'attendance_terminal_dashboard.dart';
import 'bank_transfers_screen.dart';
import 'biometric_registry_screen.dart';
import 'executive_overview_screen.dart';
import 'leave_register_screen.dart';
import 'payslips_screen.dart';
import 'personal_loans_screen.dart';
import 'salary_statement_screen.dart';

class PayrollDashboardScreen extends StatefulWidget {
  final int initialIndex;

  const PayrollDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  bool get _isEmployeeOnly {
    final role = ApiService().currentUser?.role;
    return role == UserRole.employee ||
        role == UserRole.employee1 ||
        role == UserRole.employee2 ||
        role == UserRole.employee3;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmployeeOnly) {
      // Employees only have access to Attendance & Face Terminal
      return const AttendanceTerminalDashboard();
    }

    final screens = [
      const AttendanceTerminalDashboard(),
      const ExecutiveOverviewScreen(),
      SalaryStatementScreen(
        onSelectPayslip: (emp) {
          setState(() => _selectedIndex = 3);
        },
      ),
      const PaySlipsScreen(),
      const BankTransfersScreen(),
      const LeaveRegisterScreen(),
      const PersonalLoansScreen(),
      const BiometricRegistryScreen(),
    ];

    final currentScreen = _selectedIndex < screens.length ? screens[_selectedIndex] : screens[0];

    return Scaffold(
      body: Row(
        children: [
          // Left-Hand Sidebar Navigation (Dedicated, not empty!)
          _buildLeftSidebar(),

          // Main View Area
          Expanded(child: currentScreen),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    final items = [
      {'title': 'Attendance Terminal', 'icon': Icons.co_present_outlined, 'selectedIcon': Icons.co_present, 'badge': 'LIVE'},
      {'title': 'Executive Overview', 'icon': Icons.insights_outlined, 'selectedIcon': Icons.insights, 'badge': null},
      {'title': 'Salary Statement', 'icon': Icons.table_chart_outlined, 'selectedIcon': Icons.table_chart, 'badge': '24 Col'},
      {'title': 'Employee Pay Slips', 'icon': Icons.receipt_long_outlined, 'selectedIcon': Icons.receipt_long, 'badge': 'PDF'},
      {'title': 'Bank Transfers', 'icon': Icons.account_balance_outlined, 'selectedIcon': Icons.account_balance, 'badge': null},
      {'title': 'Leave Register', 'icon': Icons.beach_access_outlined, 'selectedIcon': Icons.beach_access, 'badge': 'LOP'},
      {'title': 'Staff Personal Loans', 'icon': Icons.request_quote_outlined, 'selectedIcon': Icons.request_quote, 'badge': null},
      {'title': 'Staff Biometrics', 'icon': Icons.badge_outlined, 'selectedIcon': Icons.badge, 'badge': null},
    ];

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        children: [
          // Sidebar Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4338CA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDP PAYROLL',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Enterprise Suite',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (ctx, idx) {
                final item = items[idx];
                final isSelected = _selectedIndex == idx;
                final badge = item['badge'] as String?;

                return InkWell(
                  onTap: () => setState(() => _selectedIndex = idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? (item['selectedIcon'] as IconData) : (item['icon'] as IconData),
                          size: 18,
                          color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // User Role Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              color: const Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.shield_outlined, size: 14, color: Color(0xFF4338CA)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ApiService().currentUser?.email ?? 'payroll@flowdesk.com',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Owner / Management',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
