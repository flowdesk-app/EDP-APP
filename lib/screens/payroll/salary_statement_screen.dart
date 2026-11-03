import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../services/payroll_pdf_service.dart';
import '../../widgets/global_logout_button.dart';

class SalaryStatementScreen extends StatefulWidget {
  final bool showLogout;
  final Function(PayrollRecord)? onSelectPayslip;

  const SalaryStatementScreen({super.key, this.showLogout = true, this.onSelectPayslip});

  @override
  State<SalaryStatementScreen> createState() => _SalaryStatementScreenState();
}

class _SalaryStatementScreenState extends State<SalaryStatementScreen> {
  final ApiService _api = ApiService();
  final NumberFormat _currFmt = NumberFormat('#,##,##0.00', 'en_IN');
  final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

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

  List<PayrollRecord> _payrollRecords = [];
  Map<String, dynamic> _totals = {};

  @override
  void initState() {
    super.initState();
    _loadStatementData();
  }

  String _getMonthKey(String monthStr) {
    if (monthStr.startsWith('September')) return '2026-09';
    if (monthStr.startsWith('October')) return '2026-10';
    if (monthStr.startsWith('November')) return '2026-11';
    if (monthStr.startsWith('December')) return '2026-12';
    return '2026-09';
  }

  Future<void> _loadStatementData() async {
    setState(() => _loading = true);
    final monthKey = _getMonthKey(_selectedMonth);

    try {
      final res = await _api.getPayrollStatement(month: monthKey);
      if (mounted) {
        setState(() {
          _payrollRecords = (res['records'] as List<PayrollRecord>?) ?? [];
          _totals = (res['totals'] as Map<String, dynamic>?) ?? {};
          _loading = false;
        });
      }
    } catch (e) {
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
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top Executive Header
            _buildHeader(navySlate),

            // Main Content Area
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
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  const Spacer(),

                                  // Quick Print Statement Button
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

                            // Interactive 24-Column Data Table with Horizontal & Vertical Scroll
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
                                                  if (widget.onSelectPayslip != null) {
                                                    widget.onSelectPayslip!(r);
                                                  } else {
                                                    PayrollPdfService.printPayslipPdf(r);
                                                  }
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
            child: const Icon(Icons.table_chart, color: Colors.white, size: 24),
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
                  'Master Salary Statement (24 Columns) • Porur, Chennai 600116',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Month Selector
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
                    _loadStatementData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          ElevatedButton.icon(
            onPressed: () {
              if (_payrollRecords.isNotEmpty) {
                PayrollPdfService.printMasterStatementPdf(_payrollRecords, _totals, _selectedMonth);
              }
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Export Statement PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),

          if (widget.showLogout) const GlobalLogoutButton(),
        ],
      ),
    );
  }

  static const TextStyle _thStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.5);
  static const TextStyle _tdStyle = TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500);
  static const TextStyle _tdMutedStyle = TextStyle(fontSize: 11, color: Color(0xFF94A3B8));
  static const TextStyle _totalCellStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF0F172A));
}
