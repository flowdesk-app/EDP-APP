import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../services/payroll_pdf_service.dart';
import '../../widgets/global_logout_button.dart';

class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final NumberFormat _currFmt = NumberFormat('#,##,##0.00', 'en_IN');
  final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

  late TabController _tabController;

  String _selectedMonth = 'September 2026';
  final List<String> _months = [
    'September 2026',
    'October 2026',
    'November 2026',
    'December 2026',
  ];

  bool _loading = true;
  String _searchQuery = '';
  String _selectedDeptFilter = 'All';

  // State data
  List<PayrollRecord> _payrollRecords = [];
  Map<String, dynamic> _totals = {};
  List<BankTransferRecord> _bankTransfers = [];
  List<LeaveRecord> _leaveRecords = [];
  List<PersonalLoanRecord> _loanRecords = [];
  PayrollSummary? _summary;
  PayrollRecord? _selectedPayslipEmployee;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllPayrollData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getMonthKey(String monthStr) {
    if (monthStr.startsWith('September')) return '2026-09';
    if (monthStr.startsWith('October')) return '2026-10';
    if (monthStr.startsWith('November')) return '2026-11';
    if (monthStr.startsWith('December')) return '2026-12';
    return '2026-09';
  }

  Future<void> _loadAllPayrollData() async {
    setState(() => _loading = true);
    final monthKey = _getMonthKey(_selectedMonth);

    try {
      final statementData = await _api.getPayrollStatement(month: monthKey);
      final transfers = await _api.getBankTransfers(month: monthKey);
      final leaves = await _api.getLeaveRegister(month: monthKey);
      final loans = await _api.getPersonalLoans(month: monthKey);
      final summary = await _api.getPayrollSummary(month: monthKey);

      final recs = (statementData['records'] as List<PayrollRecord>?) ?? [];
      final tots = (statementData['totals'] as Map<String, dynamic>?) ?? {};

      if (mounted) {
        setState(() {
          _payrollRecords = recs;
          _totals = tots;
          _bankTransfers = transfers;
          _leaveRecords = leaves;
          _loanRecords = loans;
          _summary = summary;
          if (_selectedPayslipEmployee == null && recs.isNotEmpty) {
            _selectedPayslipEmployee = recs.first;
          } else if (_selectedPayslipEmployee != null) {
            final match = recs.where((r) => r.empNo == _selectedPayslipEmployee!.empNo);
            if (match.isNotEmpty) {
              _selectedPayslipEmployee = match.first;
            }
          }
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading payroll data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PayrollRecord> get _filteredRecords {
    return _payrollRecords.where((r) {
      final matchesQuery = _searchQuery.isEmpty ||
          r.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.empNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.designation.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesDept = _selectedDeptFilter == 'All' ||
          r.department.toLowerCase() == _selectedDeptFilter.toLowerCase();

      return matchesQuery && matchesDept;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgSlate = Color(0xFFF8FAFC);
    const navySlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top Enterprise Executive Header
            _buildExecutiveHeader(navySlate),

            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF4338CA)),
                          SizedBox(height: 16),
                          Text(
                            'Loading Exclusive Diamond Products Payroll...',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSalaryStatementTab(),
                        _buildPayslipsTab(),
                        _buildBankTransfersTab(),
                        _buildLeaveRegisterTab(),
                        _buildPersonalLoansTab(),
                        _buildEmployeeDirectoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER & KPI RIBBON
  // ============================================================
  Widget _buildExecutiveHeader(Color navySlate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Company Seal / Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'EXCLUSIVE DIAMOND PRODUCTS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: navySlate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: const Text(
                            'Corporate Payroll Portal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'No.62, Eswaran Koil Street, Porur, Chennai 600116 • ISO 9001:2015 Manufacturing Plant',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),

              // Month Selector Dropdown
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
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _months.map((m) {
                      return DropdownMenuItem<String>(
                        value: m,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 15, color: Color(0xFF4338CA)),
                            const SizedBox(width: 8),
                            Text(m),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                        _loadAllPayrollData();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Statement PDF Action
              ElevatedButton.icon(
                onPressed: () {
                  if (_payrollRecords.isNotEmpty) {
                    PayrollPdfService.printMasterStatementPdf(_payrollRecords, _totals, _selectedMonth);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Export Statement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),

              // Bank Advice PDF Action
              OutlinedButton.icon(
                onPressed: () {
                  if (_bankTransfers.isNotEmpty) {
                    final tot = _totals['netSalary'] as double? ?? 388081.0;
                    PayrollPdfService.printBankTransferPdf(_bankTransfers, tot, _selectedMonth);
                  }
                },
                icon: const Icon(Icons.account_balance_outlined, size: 16),
                label: const Text('Bank Advice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh Button
              IconButton(
                onPressed: _loadAllPayrollData,
                icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Refresh Payroll Data',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              const GlobalLogoutButton(),
            ],
          ),

          const SizedBox(height: 16),

          // KPI Cards Ribbon
          _buildKpiRibbon(),
        ],
      ),
    );
  }

  Widget _buildKpiRibbon() {
    final netDisbursed = (_totals['netSalary'] as num?)?.toDouble() ?? 388081.0;
    final grossPayroll = (_totals['grossSalary'] as num?)?.toDouble() ?? 423519.0;
    final totalDeductions = (_totals['totalDeductions'] as num?)?.toDouble() ?? 35438.0;
    final totalOtAmount = (_totals['otAmount'] as num?)?.toDouble() ?? 43583.0;
    final loanOutstanding = _summary?.totalLoanBalance ?? 689000.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'NET DISBURSED',
                value: '₹ ${_intFmt.format(netDisbursed)}',
                subtitle: '16 Employees • 100% Direct Bank',
                icon: Icons.payments,
                accentColor: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                badgeText: 'Disbursed',
                badgeBg: const Color(0xFFD1FAE5),
                badgeColor: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'GROSS PAYROLL',
                value: '₹ ${_intFmt.format(grossPayroll)}',
                subtitle: 'Earned: ₹ 3.80L + OT: ₹ 43.6K',
                icon: Icons.trending_up,
                accentColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                badgeText: '30 Days Cycle',
                badgeBg: const Color(0xFFDBEAFE),
                badgeColor: const Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL DEDUCTIONS',
                value: '₹ ${_intFmt.format(totalDeductions)}',
                subtitle: 'PF: ₹10.6K • Ins: ₹9.7K • Loans: ₹15K',
                icon: Icons.pie_chart_outline,
                accentColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                badgeText: '8.3% Ratio',
                badgeBg: const Color(0xFFFEF3C7),
                badgeColor: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'OVERTIME VOLUME',
                value: '888h 30m',
                subtitle: '₹ ${_intFmt.format(totalOtAmount)} Overtime Paid',
                icon: Icons.more_time_rounded,
                accentColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                badgeText: '8 Specialists',
                badgeBg: const Color(0xFFE0F2FE),
                badgeColor: const Color(0xFF075985),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'STAFF PERSONAL LOANS',
                value: '₹ ${_intFmt.format(loanOutstanding)}',
                subtitle: '₹ 15,000 Recovered This Month',
                icon: Icons.account_balance_wallet_outlined,
                accentColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                badgeText: '7 Staff Accounts',
                badgeBg: const Color(0xFFEDE9FE),
                badgeColor: const Color(0xFF5B21B6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB BAR
  // ============================================================
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF4338CA),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: const Color(0xFF4338CA),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: const Color(0xFFE2E8F0),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(
            icon: Icon(Icons.table_chart_outlined, size: 18),
            text: 'Salary Statement (24 Col)',
          ),
          Tab(
            icon: Icon(Icons.receipt_long_outlined, size: 18),
            text: 'Individual Pay Slips',
          ),
          Tab(
            icon: Icon(Icons.account_balance_outlined, size: 18),
            text: 'Online Bank Transfers',
          ),
          Tab(
            icon: Icon(Icons.event_available_outlined, size: 18),
            text: 'Leave & Attendance Register',
          ),
          Tab(
            icon: Icon(Icons.request_quote_outlined, size: 18),
            text: 'Staff Personal Loans',
          ),
          Tab(
            icon: Icon(Icons.badge_outlined, size: 18),
            text: 'Employee Master (16 Staff)',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: MASTER SALARY STATEMENT
  // ============================================================
  Widget _buildSalaryStatementTab() {
    final records = _filteredRecords;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Table Filter & Search Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by employee name, code, or designation...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Department Filter
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDeptFilter,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        items: ['All', 'Production', 'Admin', 'Accounts', 'Marketing', 'Logistics']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d == 'All' ? 'All Departments' : d)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDeptFilter = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Record counter pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Showing ${records.length} of ${_payrollRecords.length} Employees',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  const Spacer(),

                  // Quick Print Button
                  ElevatedButton.icon(
                    onPressed: () {
                      PayrollPdfService.printMasterStatementPdf(_payrollRecords, _totals, _selectedMonth);
                    },
                    icon: const Icon(Icons.print_outlined, size: 15),
                    label: const Text('Print Statement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Interactive 24-Column Data Table with Horizontal Scroll
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 16,
                    headingRowHeight: 40,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 48,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text('#', style: _thStyle)),
                      DataColumn(label: Text('EMP NO', style: _thStyle)),
                      DataColumn(label: Text('EMPLOYEE NAME', style: _thStyle)),
                      DataColumn(label: Text('DESIGNATION', style: _thStyle)),
                      DataColumn(label: Text('BASIC', style: _thStyle), numeric: true),
                      DataColumn(label: Text('D.A.', style: _thStyle), numeric: true),
                      DataColumn(label: Text('H.R.A.', style: _thStyle), numeric: true),
                      DataColumn(label: Text('CONV', style: _thStyle), numeric: true),
                      DataColumn(label: Text('MED.ALW', style: _thStyle), numeric: true),
                      DataColumn(label: Text('OTHER ALW', style: _thStyle), numeric: true),
                      DataColumn(label: Text('EARNED GROSS', style: _thStyle), numeric: true),
                      DataColumn(label: Text('OT HOURS', style: _thStyle)),
                      DataColumn(label: Text('OT AMOUNT', style: _thStyle), numeric: true),
                      DataColumn(label: Text('GROSS SALARY', style: _thStyle), numeric: true),
                      DataColumn(label: Text('P.F.', style: _thStyle), numeric: true),
                      DataColumn(label: Text('E.S.I.', style: _thStyle), numeric: true),
                      DataColumn(label: Text('ADV/LOAN', style: _thStyle), numeric: true),
                      DataColumn(label: Text('INSURANCE', style: _thStyle), numeric: true),
                      DataColumn(label: Text('DEDUCTIONS', style: _thStyle), numeric: true),
                      DataColumn(label: Text('NET TAKE-HOME', style: _thStyle), numeric: true),
                      DataColumn(label: Text('ACTION', style: _thStyle)),
                    ],
                    rows: [
                      ...records.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final r = entry.value;
                        final isEven = idx % 2 == 0;

                        return DataRow(
                          color: WidgetStateProperty.all(isEven ? Colors.white : const Color(0xFFFAFAFA)),
                          cells: [
                            DataCell(Text('$idx', style: _tdMutedStyle)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(r.empNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155))),
                              ),
                            ),
                            DataCell(
                              Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A))),
                            ),
                            DataCell(
                              Text(r.designation, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            ),
                            DataCell(Text(_intFmt.format(r.basic), style: _tdStyle)),
                            DataCell(Text(_intFmt.format(r.da), style: _tdStyle)),
                            DataCell(Text(_intFmt.format(r.hra), style: _tdStyle)),
                            DataCell(Text(_intFmt.format(r.conveyance), style: _tdStyle)),
                            DataCell(Text(_intFmt.format(r.medicalAlw), style: _tdStyle)),
                            DataCell(Text(_intFmt.format(r.otherAlw), style: _tdStyle)),
                            DataCell(
                              Text(_intFmt.format(r.earnedGross), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Color(0xFF0F172A))),
                            ),
                            DataCell(
                              Text(
                                r.otHoursFormatted,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: r.otHoursDecimal > 0 ? FontWeight.w600 : FontWeight.normal,
                                  color: r.otHoursDecimal > 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _intFmt.format(r.otAmount),
                                style: TextStyle(
                                  fontWeight: r.otAmount > 0 ? FontWeight.w700 : FontWeight.normal,
                                  fontSize: 11.5,
                                  color: r.otAmount > 0 ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _intFmt.format(r.grossSalary),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                            DataCell(Text(_intFmt.format(r.pf), style: _tdStyle)),
                            DataCell(Text(_intFmt.format(r.esi), style: _tdStyle)),
                            DataCell(
                              Text(
                                _intFmt.format(r.advanceLoan),
                                style: TextStyle(
                                  fontWeight: r.advanceLoan > 0 ? FontWeight.w700 : FontWeight.normal,
                                  fontSize: 11.5,
                                  color: r.advanceLoan > 0 ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            DataCell(Text(_intFmt.format(r.insurance), style: _tdStyle)),
                            DataCell(
                              Text(
                                _intFmt.format(r.totalDeductions),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFFDC2626)),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  '₹ ${_currFmt.format(r.netSalary)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF065F46)),
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.receipt_outlined, size: 16, color: Color(0xFF4338CA)),
                                tooltip: 'View Official Payslip',
                                onPressed: () {
                                  setState(() {
                                    _selectedPayslipEmployee = r;
                                    _tabController.animateTo(1);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                      // GRAND TOTALS ROW
                      DataRow(
                        color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                        cells: [
                          const DataCell(Text('Σ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                          const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                          DataCell(Text('${records.length} Employees', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)))),
                          const DataCell(Text('All Depts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                          DataCell(Text(_intFmt.format(_totals['basic'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['da'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['hra'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['conveyance'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['medicalAlw'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['otherAlw'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['earnedGross'] ?? 0), style: _totalCellStyle)),
                          const DataCell(Text('888h 30m', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0284C7)))),
                          DataCell(Text(_intFmt.format(_totals['otAmount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF0284C7)))),
                          DataCell(Text(_intFmt.format(_totals['grossSalary'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E3A8A)))),
                          DataCell(Text(_intFmt.format(_totals['pf'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['esi'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['advanceLoan'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFFD97706)))),
                          DataCell(Text(_intFmt.format(_totals['insurance'] ?? 0), style: _totalCellStyle)),
                          DataCell(Text(_intFmt.format(_totals['totalDeductions'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFFDC2626)))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹ ${_currFmt.format(_totals['netSalary'] ?? 0)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ),
                          const DataCell(Text('')),
                        ],
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

  // ============================================================
  // TAB 2: INDIVIDUAL PAYSLIPS
  // ============================================================
  Widget _buildPayslipsTab() {
    final selected = _selectedPayslipEmployee;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Employee List
          SizedBox(
            width: 320,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Employee',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${_payrollRecords.length} Staff',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _payrollRecords.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, i) {
                        final emp = _payrollRecords[i];
                        final isSelected = selected?.empNo == emp.empNo;

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFEEF2FF),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected ? const Color(0xFF4338CA) : const Color(0xFFF1F5F9),
                            child: Text(
                              emp.employeeName.isNotEmpty ? emp.employeeName[0] : 'E',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          title: Text(
                            emp.employeeName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${emp.empNo} • ${emp.designation}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          trailing: Text(
                            '₹ ${_intFmt.format(emp.netSalary)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF059669) : const Color(0xFF334155),
                            ),
                          ),
                          onTap: () => setState(() => _selectedPayslipEmployee = emp),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Right Pane: High-Fidelity Payslip Preview Card
          Expanded(
            child: selected == null
                ? const Center(child: Text('Select an employee to view payslip'))
                : SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Payslip Action Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PAYSLIP: ${selected.employeeName}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'Employee ID: ${selected.empNo} • Status: ${selected.paymentStatus} • Disbursed ${selected.paymentDate}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => PayrollPdfService.printPayslipPdf(selected),
                                    icon: const Icon(Icons.print_outlined, size: 16),
                                    label: const Text('Print Payslip'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4338CA),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Payslip Document Frame (Matching Document 4)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF334155), width: 1.5),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Company Header
                                const Center(
                                  child: Text(
                                    'EXCLUSIVE DIAMOND PRODUCTS',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Center(
                                  child: Text(
                                    'No.62, Eswaran Koil Street, Porur, Chennai 600116',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  color: const Color(0xFFE2E8F0),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Center(
                                    child: Text(
                                      'PAYSLIP FOR THE MONTH OF ${selected.monthDisplay.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Employee Meta Table
                                Table(
                                  border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.5),
                                  children: [
                                    _buildPayslipMetaRow('Employee Code', selected.empNo, 'Employee Name', selected.employeeName),
                                    _buildPayslipMetaRow('Designation', selected.designation, 'Department', selected.department),
                                    _buildPayslipMetaRow('Date of Joining', selected.doj, 'Bank Name', selected.bankName),
                                    _buildPayslipMetaRow('Bank A/C No', selected.accountNo, 'IFSC Code', selected.ifscCode),
                                    _buildPayslipMetaRow(
                                      'UAN Number',
                                      selected.uanNo.isNotEmpty ? selected.uanNo : 'N/A',
                                      'PF Number',
                                      selected.pfNo.isNotEmpty ? selected.pfNo : 'N/A',
                                    ),
                                    _buildPayslipMetaRow(
                                      'Total Days in Month',
                                      '${selected.totalDays} Days',
                                      'Days Worked / Paid',
                                      '${selected.daysWorked} Days',
                                    ),
                                    _buildPayslipMetaRow(
                                      'Loss of Pay (LOP)',
                                      '${selected.lopDays} Days',
                                      'Overtime Hours',
                                      selected.otHoursFormatted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Earnings & Deductions Dual Grid
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Earnings Table
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              color: const Color(0xFFF1F5F9),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('EARNINGS BREAKDOWN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                                  Text('AMOUNT (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            _payslipLine('Basic Pay', selected.basic),
                                            _payslipLine('Dearness Allowance (D.A.)', selected.da),
                                            _payslipLine('House Rent Allowance (H.R.A.)', selected.hra),
                                            _payslipLine('Conveyance Allowance', selected.conveyance),
                                            _payslipLine('Medical Allowance', selected.medicalAlw),
                                            _payslipLine('Other Allowance', selected.otherAlw),
                                            _payslipLine(
                                              'Overtime Compensation (${selected.otHoursFormatted})',
                                              selected.otAmount,
                                              isHighlight: selected.otAmount > 0,
                                            ),
                                            const Divider(height: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                                            Container(
                                              color: const Color(0xFFEEF2FF),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('GROSS EARNINGS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF312E81))),
                                                  Text('₹ ${_currFmt.format(selected.grossSalary)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF312E81))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Deductions Table
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              color: const Color(0xFFF1F5F9),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('DEDUCTIONS BREAKDOWN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                                  Text('AMOUNT (₹)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            _payslipLine('Provident Fund (P.F.)', selected.pf),
                                            _payslipLine('Employee State Insurance (E.S.I.)', selected.esi),
                                            _payslipLine(
                                              'Staff Loan / Advance Recovery',
                                              selected.advanceLoan,
                                              isHighlight: selected.advanceLoan > 0,
                                            ),
                                            _payslipLine('Life / Medical Insurance', selected.insurance),
                                            _payslipLine('Tax Deducted at Source (TDS)', selected.tds),
                                            _payslipLine('Other Deductions', selected.others),
                                            const SizedBox(height: 38), // align row heights
                                            const Divider(height: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                                            Container(
                                              color: const Color(0xFFFEF2F2),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('TOTAL DEDUCTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF991B1B))),
                                                  Text('₹ ${_currFmt.format(selected.totalDeductions)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF991B1B))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Net Salary Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'NET TAKE-HOME SALARY',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF065F46)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            selected.netSalaryWords.isNotEmpty ? selected.netSalaryWords : 'Rupees ${_intFmt.format(selected.netSalary)} Only',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '₹ ${_currFmt.format(selected.netSalary)}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Employer Contribution Info
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Text('Employer PF: ₹ ${_currFmt.format(selected.employerPf)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                                      Text('Employer ESI: ₹ ${_currFmt.format(selected.employerEsi)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                                      Text('Disbursement: Direct Transfer (${selected.bankName})', style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Signature Blocks
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      children: [
                                        Container(width: 160, height: 1, color: const Color(0xFF475569)),
                                        const SizedBox(height: 6),
                                        const Text('Employee Signature', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Container(width: 160, height: 1, color: const Color(0xFF475569)),
                                        const SizedBox(height: 6),
                                        const Text('Authorized Signatory', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                        const Text('Exclusive Diamond Products', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 3: ONLINE BANK TRANSFERS
  // ============================================================
  Widget _buildBankTransfersTab() {
    final tot = _totals['netSalary'] as double? ?? 388081.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Color(0xFF4338CA), size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Online Bank Transfer Register',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Direct NEFT/RTGS Advice for ${_selectedMonth.toUpperCase()} • 100% Disbursed',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      PayrollPdfService.printBankTransferPdf(_bankTransfers, tot, _selectedMonth);
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Export Bank Advice PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    DataColumn(label: Text('SL.NO', style: _thStyle)),
                    DataColumn(label: Text('EMP CODE', style: _thStyle)),
                    DataColumn(label: Text('NAME OF THE EMPLOYEE', style: _thStyle)),
                    DataColumn(label: Text('BANK NAME', style: _thStyle)),
                    DataColumn(label: Text('ACCOUNT NUMBER', style: _thStyle)),
                    DataColumn(label: Text('IFSC CODE', style: _thStyle)),
                    DataColumn(label: Text('AMOUNT (₹)', style: _thStyle), numeric: true),
                    DataColumn(label: Text('PAYMENT STATUS', style: _thStyle)),
                  ],
                  rows: [
                    ..._bankTransfers.map((t) {
                      final isEven = t.slNo % 2 == 0;
                      return DataRow(
                        color: WidgetStateProperty.all(isEven ? Colors.white : const Color(0xFFFAFAFA)),
                        cells: [
                          DataCell(Text('${t.slNo}', style: _tdMutedStyle)),
                          DataCell(Text(t.empNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                          DataCell(Text(t.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)))),
                          DataCell(Text(t.bankName, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)))),
                          DataCell(Text(t.accountNo, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
                          DataCell(Text(t.ifscCode, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Color(0xFF475569)))),
                          DataCell(
                            Text('₹ ${_currFmt.format(t.amount)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF065F46))),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Text('Direct Credit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                            ),
                          ),
                        ],
                      );
                    }),
                    // Total Row
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      cells: [
                        const DataCell(Text('Σ', style: TextStyle(fontWeight: FontWeight.w800))),
                        const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800))),
                        DataCell(Text('${_bankTransfers.length} Employees', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                        const DataCell(Text('All Accounts Verified', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                        const DataCell(Text('')),
                        const DataCell(Text('')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₹ ${_currFmt.format(tot)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                            ),
                          ),
                        ),
                        const DataCell(Text('100% Processed', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF065F46), fontSize: 11))),
                      ],
                    ),
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
  // TAB 4: LEAVE & ATTENDANCE REGISTER
  // ============================================================
  Widget _buildLeaveRegisterTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.beach_access, color: Color(0xFF0284C7), size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave & Attendance Register',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Opening Balance, Monthly Entitlement, Leaves Taken & LOP Days for ${_selectedMonth.toUpperCase()}',
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
                    child: const Text(
                      'Total LOP: 30.0 Days',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
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
                        DataCell(Text('${lr.openingLeave}', style: _tdStyle)),
                        DataCell(Text('${lr.monthlyAccrual}', style: _tdStyle)),
                        DataCell(Text('${lr.leaveTaken}', style: _tdStyle)),
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
                        DataCell(Text('${lr.closingBalance}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF065F46)))),
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
    );
  }

  // ============================================================
  // TAB 5: STAFF PERSONAL LOANS
  // ============================================================
  Widget _buildPersonalLoansTab() {
    final totalSanctioned = _loanRecords.reduce((a, b) => PersonalLoanRecord(empNo: '', employeeName: '', loanSanctioned: a.loanSanctioned + b.loanSanctioned)).loanSanctioned;
    final totalPrevious = _loanRecords.reduce((a, b) => PersonalLoanRecord(empNo: '', employeeName: '', previousBalance: a.previousBalance + b.previousBalance)).previousBalance;
    final totalDeduction = _loanRecords.reduce((a, b) => PersonalLoanRecord(empNo: '', employeeName: '', monthlyDeduction: a.monthlyDeduction + b.monthlyDeduction)).monthlyDeduction;
    final totalClosing = _loanRecords.reduce((a, b) => PersonalLoanRecord(empNo: '', employeeName: '', closingBalance: a.closingBalance + b.closingBalance)).closingBalance;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF7C3AED), size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Personal Loan Statement',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Loan Sanctioned, Monthly Payroll Recoveries & Closing Balances as on ${_selectedMonth.toUpperCase()}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Text(
                      'Outstanding: ₹ ${_intFmt.format(totalClosing)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
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
                    DataColumn(label: Text('#', style: _thStyle)),
                    DataColumn(label: Text('EMP CODE', style: _thStyle)),
                    DataColumn(label: Text('NAME OF EMPLOYEE', style: _thStyle)),
                    DataColumn(label: Text('DEPARTMENT', style: _thStyle)),
                    DataColumn(label: Text('LOAN SANCTIONED (₹)', style: _thStyle), numeric: true),
                    DataColumn(label: Text('PREVIOUS BALANCE (₹)', style: _thStyle), numeric: true),
                    DataColumn(label: Text('MONTHLY DEDUCTION (₹)', style: _thStyle), numeric: true),
                    DataColumn(label: Text('CLOSING BALANCE (₹)', style: _thStyle), numeric: true),
                    DataColumn(label: Text('STATUS', style: _thStyle)),
                  ],
                  rows: [
                    ..._loanRecords.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final l = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('$idx', style: _tdMutedStyle)),
                          DataCell(Text(l.empNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                          DataCell(Text(l.employeeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)))),
                          DataCell(Text(l.department, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                          DataCell(Text(_intFmt.format(l.loanSanctioned), style: _tdStyle)),
                          DataCell(Text(_intFmt.format(l.previousBalance), style: _tdStyle)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '₹ ${_intFmt.format(l.monthlyDeduction)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF92400E)),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹ ${_intFmt.format(l.closingBalance)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF6D28D9)),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                            ),
                          ),
                        ],
                      );
                    }),
                    // Totals Row
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      cells: [
                        const DataCell(Text('Σ', style: TextStyle(fontWeight: FontWeight.w800))),
                        const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800))),
                        DataCell(Text('${_loanRecords.length} Staff Accounts', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                        const DataCell(Text('')),
                        DataCell(Text('₹ ${_intFmt.format(totalSanctioned)}', style: _totalCellStyle)),
                        DataCell(Text('₹ ${_intFmt.format(totalPrevious)}', style: _totalCellStyle)),
                        DataCell(Text('₹ ${_intFmt.format(totalDeduction)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF92400E), fontSize: 12))),
                        DataCell(Text('₹ ${_intFmt.format(totalClosing)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6D28D9), fontSize: 13))),
                        const DataCell(Text('')),
                      ],
                    ),
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
  // TAB 6: EMPLOYEE MASTER DIRECTORY
  // ============================================================
  Widget _buildEmployeeDirectoryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 380,
          mainAxisExtent: 200,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _payrollRecords.length,
        itemBuilder: (ctx, i) {
          final emp = _payrollRecords[i];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        emp.employeeName.isNotEmpty ? emp.employeeName[0] : 'E',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4338CA), fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.employeeName,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            emp.designation,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF4338CA)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        emp.empNo,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCol('Department', emp.department),
                    _infoCol('Bank', emp.bankName),
                    _infoCol('Monthly Net', '₹ ${_intFmt.format(emp.netSalary)}'),
                  ],
                ),
                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'A/C: ••••${emp.accountNo.length > 4 ? emp.accountNo.substring(emp.accountNo.length - 4) : emp.accountNo}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPayslipEmployee = emp;
                          _tabController.animateTo(1);
                        });
                      },
                      child: const Row(
                        children: [
                          Text('View Payslip', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4338CA))),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: Color(0xFF4338CA)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _infoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      ],
    );
  }

  static TableRow _buildPayslipMetaRow(String label1, String val1, String label2, String val2) {
    return TableRow(
      children: [
        _metaCell(label1, isLabel: true),
        _metaCell(val1),
        _metaCell(label2, isLabel: true),
        _metaCell(val2),
      ],
    );
  }

  static Widget _metaCell(String text, {bool isLabel = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      color: isLabel ? const Color(0xFFF8FAFC) : Colors.white,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isLabel ? FontWeight.w700 : FontWeight.w500,
          color: isLabel ? const Color(0xFF334155) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _payslipLine(String label, double amount, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      color: isHighlight ? const Color(0xFFFFFBEB) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? const Color(0xFF92400E) : const Color(0xFF334155),
            ),
          ),
          Text(
            _currFmt.format(amount),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? const Color(0xFF92400E) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // Common typography styles
  static const TextStyle _thStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.5);
  static const TextStyle _tdStyle = TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500);
  static const TextStyle _tdMutedStyle = TextStyle(fontSize: 11, color: Color(0xFF94A3B8));
  static const TextStyle _totalCellStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF0F172A));
}
