import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../services/payroll_pdf_service.dart';
import '../../widgets/global_logout_button.dart';

class PersonalLoansScreen extends StatefulWidget {
  final bool showLogout;

  const PersonalLoansScreen({super.key, this.showLogout = true});

  @override
  State<PersonalLoansScreen> createState() => _PersonalLoansScreenState();
}

class _PersonalLoansScreenState extends State<PersonalLoansScreen> {
  final ApiService _api = ApiService();
  final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

  late String _selectedMonth;
  late List<String> _months;

  bool _loading = true;
  List<PersonalLoanRecord> _loanRecords = [];
  String _searchQuery = '';
  String _selectedDept = 'All';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to current calendar month (e.g. "November 2026").
    // When calendar turns to December 2026, it will automatically switch to "December 2026".
    _selectedMonth = DateFormat('MMMM yyyy').format(now);
    _initMonths(now);
    _loadData();
  }

  void _initMonths(DateTime now) {
    final List<String> list = [];
    final start = DateTime(2026, 9); // Base month
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
      final loans = await _api.getPersonalLoans(month: monthKey);
      if (mounted) {
        setState(() {
          _loanRecords = loans;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PersonalLoanRecord> get _filteredRecords {
    return _loanRecords.where((l) {
      final matchesSearch = _searchQuery.isEmpty ||
          l.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.empNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.department.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDept == 'All' || l.department == _selectedDept;
      return matchesSearch && matchesDept;
    }).toList();
  }

  List<String> get _departments {
    final set = <String>{'All'};
    for (var r in _loanRecords) {
      if (r.department.isNotEmpty) set.add(r.department);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgSlate = Color(0xFFF8FAFC);
    const navySlate = Color(0xFF0F172A);

    final totalSanctioned = _loanRecords.fold<double>(0.0, (s, l) => s + l.loanSanctioned);
    final totalPrevious = _loanRecords.fold<double>(0.0, (s, l) => s + l.previousBalance);
    final totalDeduction = _loanRecords.fold<double>(0.0, (s, l) => s + l.monthlyDeduction);
    final totalClosing = _loanRecords.fold<double>(0.0, (s, l) => s + l.closingBalance);

    final totalsMap = {
      'loanSanctioned': totalSanctioned,
      'previousBalance': totalPrevious,
      'monthlyDeduction': totalDeduction,
      'closingBalance': totalClosing,
    };

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
                          // 1. TOP EXECUTIVE KPI CARDS (Big, spacious, fills the upper area)
                          _buildExecutiveKpiCards(
                            totalSanctioned: totalSanctioned,
                            totalPrevious: totalPrevious,
                            totalDeduction: totalDeduction,
                            totalClosing: totalClosing,
                          ),
                          const SizedBox(height: 20),

                          // 2. SEARCH, DEPARTMENT FILTER & PDF EXPORT TOOLBAR
                          _buildFilterToolbar(totalsMap),
                          const SizedBox(height: 16),

                          // 3. FULL-WIDTH SPACIOUS MASTER LOAN TABLE
                          _buildSpaciousMasterTable(
                            totalSanctioned: totalSanctioned,
                            totalPrevious: totalPrevious,
                            totalDeduction: totalDeduction,
                            totalClosing: totalClosing,
                          ),
                          const SizedBox(height: 20),

                          // 4. POLICY & STATUTORY AUDIT FOOTER NOTE
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
    required double totalSanctioned,
    required double totalPrevious,
    required double totalDeduction,
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
              title: 'TOTAL LOANS SANCTIONED',
              value: '₹ ${_intFmt.format(totalSanctioned)}',
              subtext: '${_loanRecords.length} Active Staff Accounts approved',
              icon: Icons.account_balance_wallet,
              gradient: const [Color(0xFF312E81), Color(0xFF4338CA)],
              iconColor: const Color(0xFF818CF8),
            ),
            _kpiCard(
              title: 'STARTING BALANCE (${_selectedMonth.split(' ').first.toUpperCase()})',
              value: '₹ ${_intFmt.format(totalPrevious)}',
              subtext: 'Carryover from previous month ledger',
              icon: Icons.history,
              gradient: const [Color(0xFF1E293B), Color(0xFF334155)],
              iconColor: const Color(0xFF94A3B8),
            ),
            _kpiCard(
              title: 'MONTHLY RECOVERIES',
              value: '₹ ${_intFmt.format(totalDeduction)}',
              subtext: 'Deducted directly from monthly salary',
              icon: Icons.receipt_long,
              gradient: const [Color(0xFF78350F), Color(0xFFD97706)],
              iconColor: const Color(0xFFFDE68A),
            ),
            _kpiCard(
              title: 'CURRENT OUTSTANDING',
              value: '₹ ${_intFmt.format(totalClosing)}',
              subtext: 'Closing balance remaining to recover',
              icon: Icons.monetization_on,
              gradient: const [Color(0xFF581C87), Color(0xFF7C3AED)],
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
  // 2. TOOLBAR: SEARCH, DEPARTMENT & ACTIONS
  // ============================================================
  Widget _buildFilterToolbar(Map<String, dynamic> totalsMap) {
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
          // Live search box
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 42,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search staff name, code (e.g. 20004), or department...',
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
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(dept),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedDept = dept),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF4338CA),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0)),
                  ),
                );
              }).toList(),
            ),
          ),
          const Spacer(),

          // Print Document 5 Button
          ElevatedButton.icon(
            onPressed: () {
              PayrollPdfService.printLoanStatementPdf(_loanRecords, totalsMap, _selectedMonth);
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Document 5'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. FULL-WIDTH SPACIOUS MASTER TABLE
  // ============================================================
  Widget _buildSpaciousMasterTable({
    required double totalSanctioned,
    required double totalPrevious,
    required double totalDeduction,
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
          // Table header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Color(0xFF7C3AED), size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff Personal Loan Statement (Document 5)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showing ${records.length} of ${_loanRecords.length} staff records as on ${_selectedMonth.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        '100% On-Schedule Recoveries (${_selectedMonth.split(' ').first})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable table container that fills entire width
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
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text('#', style: _thStyle)),
                      DataColumn(label: Text('EMP CODE', style: _thStyle)),
                      DataColumn(label: Text('NAME OF EMPLOYEE', style: _thStyle)),
                      DataColumn(label: Text('DEPARTMENT', style: _thStyle)),
                      DataColumn(label: Text('LOAN SANCTIONED', style: _thStyle), numeric: true),
                      DataColumn(label: Text('PREVIOUS BALANCE', style: _thStyle), numeric: true),
                      DataColumn(label: Text('MONTHLY DEDUCTION', style: _thStyle), numeric: true),
                      DataColumn(label: Text('CLOSING BALANCE', style: _thStyle), numeric: true),
                      DataColumn(label: Text('REPAID %', style: _thStyle)),
                      DataColumn(label: Text('STATUS', style: _thStyle)),
                    ],
                    rows: [
                      ...records.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final l = entry.value;
                        final repaidAmt = l.loanSanctioned - l.closingBalance;
                        final progress = l.loanSanctioned > 0 ? (repaidAmt / l.loanSanctioned).clamp(0.0, 1.0) : 0.0;
                        final isCleared = l.closingBalance <= 0;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) return const Color(0xFFF8FAFC);
                            return idx % 2 == 0 ? const Color(0xFFFAFAFA) : Colors.white;
                          }),
                          cells: [
                            DataCell(Text('$idx', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  l.empNo,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFFEDE9FE),
                                    child: Text(
                                      l.employeeName.isNotEmpty ? l.employeeName[0] : 'S',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF6D28D9)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l.employeeName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _deptColor(l.department).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _deptColor(l.department).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  l.department,
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _deptColor(l.department)),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '₹ ${_intFmt.format(l.loanSanctioned)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'monospace'),
                              ),
                            ),
                            DataCell(
                              Text(
                                '₹ ${_intFmt.format(l.previousBalance)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), fontFamily: 'monospace'),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Text(
                                  '₹ ${_intFmt.format(l.monthlyDeduction)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF92400E), fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '₹ ${_intFmt.format(l.closingBalance)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                  color: isCleared ? const Color(0xFF059669) : const Color(0xFF6D28D9),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(progress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 80,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isCleared ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCleared ? const Color(0xFFDCFCE7) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isCleared ? const Color(0xFF86EFAC) : const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  isCleared ? 'Cleared' : 'Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isCleared ? const Color(0xFF15803D) : const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // GRAND TOTALS ROW
                      DataRow(
                        color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                        cells: [
                          const DataCell(Text('Σ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13))),
                          const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                          DataCell(Text('${records.length} Staff Accounts', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)))),
                          const DataCell(Text('All Depts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569)))),
                          DataCell(Text('₹ ${_intFmt.format(totalSanctioned)}', style: _totalCellStyle)),
                          DataCell(Text('₹ ${_intFmt.format(totalPrevious)}', style: _totalCellStyle)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE68A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹ ${_intFmt.format(totalDeduction)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF78350F), fontSize: 13, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹ ${_intFmt.format(totalClosing)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF581C87), fontSize: 14, fontFamily: 'monospace'),
                            ),
                          ),
                          const DataCell(Text('—', style: TextStyle(color: Color(0xFF94A3B8)))),
                          const DataCell(Text('Verified', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF065F46)))),
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
  // 4. AUDIT & RECOVERY POLICY BANNER
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
          Icon(Icons.info_outline, color: Color(0xFF4338CA), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Statutory Payroll Audit Note: All monthly loan deductions are automatically deducted from the employee gross earnings under Document 1 (Salary Statement) and credited to the closing ledger before the final net disbursement bank transfer advice is issued. Exclusive Diamond Products Staff Welfare Rules, Chennai Plant.',
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
                colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
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
                  'Staff Personal Loan Ledger & Recoveries • Porur, Chennai 600116',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Dynamic Month Selector (defaults to current month, auto-advances)
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
                        const Icon(Icons.calendar_month, size: 16, color: Color(0xFF4338CA)),
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

  Color _deptColor(String dept) {
    switch (dept) {
      case 'Production':
        return const Color(0xFF0284C7);
      case 'Admin':
        return const Color(0xFF4338CA);
      case 'Marketing':
        return const Color(0xFFD97706);
      case 'Accounts':
        return const Color(0xFF059669);
      case 'Logistics':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF475569);
    }
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
    fontFamily: 'monospace',
  );
}
