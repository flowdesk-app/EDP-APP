import 'package:flutter/material.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../widgets/global_logout_button.dart';

class LeaveRegisterScreen extends StatefulWidget {
  final bool showLogout;

  const LeaveRegisterScreen({super.key, this.showLogout = true});

  @override
  State<LeaveRegisterScreen> createState() => _LeaveRegisterScreenState();
}

class _LeaveRegisterScreenState extends State<LeaveRegisterScreen> {
  final ApiService _api = ApiService();

  String _selectedMonth = 'September 2026';
  final List<String> _months = [
    'September 2026',
    'October 2026',
    'November 2026',
    'December 2026',
  ];

  bool _loading = true;
  List<LeaveRecord> _leaveRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getMonthKey(String monthStr) {
    if (monthStr.startsWith('September')) return '2026-09';
    if (monthStr.startsWith('October')) return '2026-10';
    if (monthStr.startsWith('November')) return '2026-11';
    if (monthStr.startsWith('December')) return '2026-12';
    return '2026-09';
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final monthKey = _getMonthKey(_selectedMonth);

    try {
      final leaves = await _api.getLeaveRegister(month: monthKey);
      if (mounted) {
        setState(() {
          _leaveRecords = leaves;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgSlate = Color(0xFFF8FAFC);
    const navySlate = Color(0xFF0F172A);

    final totalLop = _leaveRecords.fold<double>(0.0, (s, r) => s + r.lopDays);
    final totalTaken = _leaveRecords.fold<double>(0.0, (s, r) => s + r.leaveTaken);

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(navySlate),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF4338CA)))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.beach_access, color: Color(0xFF0284C7), size: 24),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Leave & Attendance Register (Document 3)',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        'Opening Leave, Accrual, Leaves Taken & LOP Days for ${_selectedMonth.toUpperCase()}',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Text(
                                      'Total LOP: ${totalLop.toStringAsFixed(1)} Days',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      'Total Availed: ${totalTaken.toStringAsFixed(1)} Days',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowHeight: 40,
                                  dataRowMinHeight: 44,
                                  dataRowMaxHeight: 48,
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                                  columns: const [
                                    DataColumn(label: Text('EMP NO', style: _thStyle)),
                                    DataColumn(label: Text('EMPLOYEE NAME', style: _thStyle)),
                                    DataColumn(label: Text('DEPARTMENT', style: _thStyle)),
                                    DataColumn(label: Text('OPENING LEAVE', style: _thStyle), numeric: true),
                                    DataColumn(label: Text('MONTHLY ACCRUAL', style: _thStyle), numeric: true),
                                    DataColumn(label: Text('LEAVE TAKEN', style: _thStyle), numeric: true),
                                    DataColumn(label: Text('LOP DAYS', style: _thStyle), numeric: true),
                                    DataColumn(label: Text('CLOSING BALANCE', style: _thStyle), numeric: true),
                                    DataColumn(label: Text('REMARKS', style: _thStyle)),
                                  ],
                                  rows: _leaveRecords.map((lr) {
                                    final hasLop = lr.lopDays > 0;
                                    return DataRow(
                                      color: WidgetStateProperty.all(hasLop ? const Color(0xFFFFFBEB) : Colors.white),
                                      cells: [
                                        DataCell(Text(lr.empNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                                        DataCell(Text(lr.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)))),
                                        DataCell(Text(lr.department, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                        DataCell(Text('${lr.openingLeave}', style: const TextStyle(fontSize: 11.5))),
                                        DataCell(Text('${lr.monthlyAccrual}', style: const TextStyle(fontSize: 11.5))),
                                        DataCell(Text('${lr.leaveTaken}', style: const TextStyle(fontSize: 11.5))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: hasLop ? const Color(0xFFFEE2E2) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${lr.lopDays}',
                                              style: TextStyle(
                                                fontWeight: hasLop ? FontWeight.w800 : FontWeight.normal,
                                                color: hasLop ? const Color(0xFFDC2626) : const Color(0xFF334155),
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${lr.closingBalance}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF065F46)))),
                                        DataCell(Text(lr.remarks, style: TextStyle(fontSize: 11, color: hasLop ? const Color(0xFFDC2626) : const Color(0xFF64748B)))),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color navySlate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.beach_access, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXCLUSIVE DIAMOND PRODUCTS',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navySlate),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Staff Leave & Attendance Register • Porur, Chennai 600116',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF334155)),
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                items: _months.map((m) {
                  return DropdownMenuItem<String>(
                    value: m,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 15, color: Color(0xFF4338CA)),
                        const SizedBox(width: 8),
                        Text(m),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedMonth = val);
                    _loadData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          if (widget.showLogout) const GlobalLogoutButton(),
        ],
      ),
    );
  }

  static const TextStyle _thStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.5);
}
