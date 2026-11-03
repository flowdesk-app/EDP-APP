import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  late String _selectedMonth;
  late List<String> _months;

  bool _loading = true;
  List<LeaveRecord> _leaveRecords = [];
  String _searchQuery = '';
  String _selectedDept = 'All';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat('MMMM yyyy').format(now);
    _initMonths(now);
    _loadData();
  }

  void _initMonths(DateTime now) {
    final List<String> list = [];
    final start = DateTime(2026, 9);
    for (int i = 0; i < 16; i++) {
      final dt = DateTime(start.year, start.month + i);
      list.add(DateFormat('MMMM yyyy').format(dt));
    }
    _months = list;
    if (!_months.contains(_selectedMonth)) {
      _months.insert(0, _selectedMonth);
    }
  }

  String _getMonthKey(String monthStr) {
    try {
      final dt = DateFormat('MMMM yyyy').parse(monthStr);
      return DateFormat('yyyy-MM').format(dt);
    } catch (_) {
      return '2026-11';
    }
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

  List<LeaveRecord> get _filteredRecords {
    return _leaveRecords.where((r) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          r.employeeName.toLowerCase().contains(q) ||
          r.empNo.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q);
      final matchesDept = _selectedDept == 'All' || r.department == _selectedDept;
      return matchesSearch && matchesDept;
    }).toList();
  }

  List<String> get _departments {
    final set = <String>{'All'};
    for (var r in _leaveRecords) {
      if (r.department.isNotEmpty) set.add(r.department);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgSlate = Color(0xFFF8FAFC);
    const navySlate = Color(0xFF0F172A);

    final totalOpening = _leaveRecords.fold<double>(0.0, (s, r) => s + r.openingLeave);
    final totalAccrual = _leaveRecords.fold<double>(0.0, (s, r) => s + r.monthlyAccrual);
    final totalTaken = _leaveRecords.fold<double>(0.0, (s, r) => s + r.leaveTaken);
    final totalLop = _leaveRecords.fold<double>(0.0, (s, r) => s + r.lopDays);
    final totalClosing = _leaveRecords.fold<double>(0.0, (s, r) => s + r.closingBalance);

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(navySlate),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF4338CA)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. TOP EXECUTIVE KPI CARDS
                          _buildExecutiveKpiCards(
                            totalTaken: totalTaken,
                            totalLop: totalLop,
                            totalAccrual: totalAccrual,
                            totalClosing: totalClosing,
                          ),
                          const SizedBox(height: 20),

                          // 2. TOOLBAR: SEARCH & DEPARTMENT FILTER
                          _buildToolbar(),
                          const SizedBox(height: 16),

                          // 3. FULL-WIDTH SPACIOUS LEAVE REGISTER TABLE
                          _buildSpaciousLeaveTable(
                            totalOpening: totalOpening,
                            totalAccrual: totalAccrual,
                            totalTaken: totalTaken,
                            totalLop: totalLop,
                            totalClosing: totalClosing,
                          ),
                          const SizedBox(height: 20),

                          // 4. STATUTORY AUDIT FOOTER NOTE
                          _buildAuditFooterCard(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 1. TOP EXECUTIVE KPI CARDS
  // ============================================================
  Widget _buildExecutiveKpiCards({
    required double totalTaken,
    required double totalLop,
    required double totalAccrual,
    required double totalClosing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final count = isWide ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          childAspectRatio: isWide ? 2.3 : 1.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _kpiCard(
              title: 'TOTAL LEAVES AVAILED',
              value: '${totalTaken.toStringAsFixed(1)} Days',
              subtext: 'Paid leaves approved across 16 staff',
              icon: Icons.beach_access,
              gradient: const [Color(0xFF0369A1), Color(0xFF0284C7)],
              iconColor: const Color(0xFFBAE6FD),
            ),
            _kpiCard(
              title: 'TOTAL LOSS OF PAY (LOP)',
              value: '${totalLop.toStringAsFixed(1)} Days',
              subtext: 'Salary deducted for unapproved/excess absence',
              icon: Icons.money_off,
              gradient: const [Color(0xFF991B1B), Color(0xFFDC2626)],
              iconColor: const Color(0xFFFECACA),
            ),
            _kpiCard(
              title: 'MONTHLY ACCRUAL CREDIT',
              value: '+${totalAccrual.toStringAsFixed(1)} Days',
              subtext: '1.5 days/month earned leave under Factories Act',
              icon: Icons.trending_up,
              gradient: const [Color(0xFF065F46), Color(0xFF059669)],
              iconColor: const Color(0xFFA7F3D0),
            ),
            _kpiCard(
              title: 'CLOSING LEAVE POOL',
              value: '${totalClosing.toStringAsFixed(1)} Days',
              subtext: 'Remaining balance carried into next month',
              icon: Icons.inventory_2_outlined,
              gradient: const [Color(0xFF312E81), Color(0xFF4338CA)],
              iconColor: const Color(0xFFDDD6FE),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required List<Color> gradient,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.6),
              ),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. TOOLBAR: SEARCH & DEPARTMENT FILTER
  // ============================================================
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 42,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search employee name, code (e.g. 20004), or department...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Department selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _departments.map((dept) {
                final isSelected = _selectedDept == dept;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(dept),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedDept = dept),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_bulleted, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  '${_filteredRecords.length} / ${_leaveRecords.length} Records',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. FULL-WIDTH SPACIOUS LEAVE TABLE
  // ============================================================
  Widget _buildSpaciousLeaveTable({
    required double totalOpening,
    required double totalAccrual,
    required double totalTaken,
    required double totalLop,
    required double totalClosing,
  }) {
    final records = _filteredRecords;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.beach_access, color: Color(0xFF0284C7), size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leave & Attendance Register (Document 3)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Opening Leave, Accrual, Leaves Taken & LOP Days for ${_selectedMonth.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: totalLop > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: totalLop > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Icon(totalLop > 0 ? Icons.warning_amber : Icons.check_circle, size: 14, color: totalLop > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'Total LOP: ${totalLop.toStringAsFixed(1)} Days',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: totalLop > 0 ? const Color(0xFFDC2626) : const Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 28,
                    horizontalMargin: 24,
                    headingRowHeight: 52,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 68,
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
                    rows: [
                      ...records.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final r = entry.value;
                        final hasLop = r.lopDays > 0;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) return const Color(0xFFF8FAFC);
                            if (hasLop) return const Color(0xFFFFFBEB);
                            return idx % 2 == 0 ? const Color(0xFFFAFAFA) : Colors.white;
                          }),
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  r.empNo,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: hasLop ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                                    child: Text(
                                      r.employeeName.isNotEmpty ? r.employeeName[0] : 'E',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: hasLop ? const Color(0xFFB45309) : const Color(0xFF0369A1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    r.employeeName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r.department, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                              ),
                            ),
                            DataCell(Text(r.openingLeave.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${r.monthlyAccrual.toStringAsFixed(1)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                ),
                              ),
                            ),
                            DataCell(Text(r.leaveTaken.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                            DataCell(
                              hasLop
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFCA5A5)),
                                      ),
                                      child: Text(
                                        '${r.lopDays.toStringAsFixed(1)} LOP',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFDC2626)),
                                      ),
                                    )
                                  : const Text('0.0', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ),
                            DataCell(
                              Text(
                                r.closingBalance.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF059669)),
                              ),
                            ),
                            DataCell(
                              hasLop
                                  ? Text(
                                      r.remarks.isNotEmpty ? r.remarks : '${r.lopDays.toStringAsFixed(1)} Days LOP',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                    )
                                  : Text(
                                      r.remarks.isNotEmpty ? r.remarks : 'Normal leave',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                            ),
                          ],
                        );
                      }),
                      // GRAND TOTAL ROW
                      DataRow(
                        color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                        cells: [
                          const DataCell(Text('Σ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                          DataCell(Text('${records.length} Employees', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)))),
                          const DataCell(Text('All Depts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569)))),
                          DataCell(Text(totalOpening.toStringAsFixed(1), style: _totalCellStyle)),
                          DataCell(Text('+${totalAccrual.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 13))),
                          DataCell(Text(totalTaken.toStringAsFixed(1), style: _totalCellStyle)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${totalLop.toStringAsFixed(1)} Days',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12.5),
                              ),
                            ),
                          ),
                          DataCell(Text(totalClosing.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 14))),
                          const DataCell(Text('Audited', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF065F46)))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 5. AUDIT NOTE
  // ============================================================
  Widget _buildAuditFooterCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel_outlined, color: Color(0xFF0284C7), size: 22),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Statutory Leave Compliance: In accordance with Chapter VIII of the Factories Act 1948 and Tamil Nadu Model Standing Orders, every worker is entitled to leave with wages at the rate of 1 day for every 20 days worked (accruing 1.5 days/month). All LOP days are directly factored into gross salary calculations in Document 1.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP EXECUTIVE HEADER BAR
  // ============================================================
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
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
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

          // Dynamic Month Selector
          Container(
            height: 40,
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
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
                items: _months.map((m) {
                  return DropdownMenuItem<String>(
                    value: m,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 16, color: Color(0xFF0284C7)),
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

  static const TextStyle _thStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Color(0xFF1E293B),
    letterSpacing: 0.5,
  );

  static const TextStyle _totalCellStyle = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 13,
    color: Color(0xFF0F172A),
  );
}
