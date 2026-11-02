import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/global_logout_button.dart';

class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  String _selectedMonth = 'November 2026';
  final List<String> _months = [
    'November 2026',
    'December 2026',
    'January 2027',
    'February 2027',
    'March 2027',
  ];

  final List<Map<String, String>> _employees = [
    {
      'name': 'Owner / Executive',
      'email': 'owner@flowdesk.com',
      'role': 'Owner',
      'department': 'Management',
      'status': 'Active',
    },
    {
      'name': 'Operations Admin',
      'email': 'admin@flowdesk.com',
      'role': 'Admin',
      'department': 'Operations',
      'status': 'Active',
    },
    {
      'name': 'Employee 1',
      'email': 'employee1@flowdesk.com',
      'role': 'Inventory Staff',
      'department': 'Inventory & Raw Materials',
      'status': 'Active',
    },
    {
      'name': 'Employee 2',
      'email': 'employee2@flowdesk.com',
      'role': 'Production Staff',
      'department': 'Shop Floor & Production',
      'status': 'Active',
    },
    {
      'name': 'Employee 3',
      'email': 'employee3@flowdesk.com',
      'role': 'Dispatch Staff',
      'department': 'Quality & Dispatch',
      'status': 'Active',
    },
  ];

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
                  ApiService().currentUser?.email ?? 'payroll@flowdesk.com',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const GlobalLogoutButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome & Period Bar
            _buildWelcomeBanner(),
            const SizedBox(height: 20),

            // Metric KPI Cards
            _buildMetricCards(),
            const SizedBox(height: 24),

            // Employee Roster Section
            _buildEmployeeRosterSection(),
            const SizedBox(height: 24),

            // Payroll Modules Preview
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
                  'Welcome to Employee Payroll',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage monthly salaries, attendance records, allowances, and payroll disbursement.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                  if (val != null) setState(() => _selectedMonth = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 12) / 2;

        final metrics = [
          {
            'title': 'Total Staff',
            'value': '${_employees.length}',
            'subtitle': 'Active workforce',
            'icon': Icons.people_outline,
            'color': const Color(0xFF1976D2),
            'bg': const Color(0xFFE3F2FD),
          },
          {
            'title': 'Pay Cycle',
            'value': _selectedMonth.split(' ').first,
            'subtitle': _selectedMonth.split(' ').last,
            'icon': Icons.date_range_outlined,
            'color': const Color(0xFF00897B),
            'bg': const Color(0xFFE0F2F1),
          },
          {
            'title': 'Working Days',
            'value': '26',
            'subtitle': 'Calendar working days',
            'icon': Icons.calendar_today_outlined,
            'color': const Color(0xFFF57C00),
            'bg': const Color(0xFFFFF3E0),
          },
          {
            'title': 'Payroll Status',
            'value': 'Ready',
            'subtitle': 'Ready for setup',
            'icon': Icons.check_circle_outline,
            'color': const Color(0xFF2E7D32),
            'bg': const Color(0xFFE8F5E9),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
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
                  'Employee Payroll Roster',
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
                  '${_employees.length} Staff Registered',
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        emp['name']!.substring(0, 1),
                        style: const TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp['name']!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
                          ),
                          Text(
                            emp['email']!,
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
                            emp['department']!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            emp['role']!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 12, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 4),
                          Text(
                            emp['status']!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
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
        'desc': 'Basic pay, DA, HRA, incentives, overtime calculations, and deductions.',
        'icon': Icons.calculate_outlined,
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Monthly Attendance & Leaves',
        'desc': 'Working days, present days, approved leaves, and overtime hours tracking.',
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
        'desc': 'Payment summary, bank transfer files, and employee transaction history.',
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
            'This dashboard is ready to receive your specific payroll formula rules, attendance tracking system, and salary slip format in upcoming steps.',
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
