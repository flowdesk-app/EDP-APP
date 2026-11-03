import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../services/payroll_pdf_service.dart';
import '../../widgets/global_logout_button.dart';

class PaySlipsScreen extends StatefulWidget {
  final bool showLogout;
  final PayrollRecord? preselectedEmployee;

  const PaySlipsScreen({super.key, this.showLogout = true, this.preselectedEmployee});

  @override
  State<PaySlipsScreen> createState() => _PaySlipsScreenState();
}

class _PaySlipsScreenState extends State<PaySlipsScreen> {
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
  List<PayrollRecord> _employees = [];
  PayrollRecord? _selectedEmployee;

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
      final res = await _api.getPayrollStatement(month: monthKey);
      final recs = (res['records'] as List<PayrollRecord>?) ?? [];

      if (mounted) {
        setState(() {
          _employees = recs;
          if (widget.preselectedEmployee != null) {
            final match = recs.where((r) => r.empNo == widget.preselectedEmployee!.empNo);
            _selectedEmployee = match.isNotEmpty ? match.first : (recs.isNotEmpty ? recs.first : null);
          } else if (_selectedEmployee == null && recs.isNotEmpty) {
            _selectedEmployee = recs.first;
          } else if (_selectedEmployee != null) {
            final match = recs.where((r) => r.empNo == _selectedEmployee!.empNo);
            if (match.isNotEmpty) _selectedEmployee = match.first;
          }
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
    final selected = _selectedEmployee;

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top Executive Header
            _buildHeader(navySlate),

            // Main Content Area (Split View)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF4338CA)))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Pane: Employee List (320px)
                          SizedBox(
                            width: 320,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Select Employee',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${_employees.length} Staff',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      itemCount: _employees.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (ctx, i) {
                                        final emp = _employees[i];
                                        final isSelected = selected?.empNo == emp.empNo;

                                        return ListTile(
                                          dense: true,
                                          selected: isSelected,
                                          selectedTileColor: const Color(0xFFEEF2FF),
                                          leading: CircleAvatar(
                                            radius: 17,
                                            backgroundColor: isSelected ? const Color(0xFF4338CA) : const Color(0xFFF1F5F9),
                                            child: Text(
                                              emp.employeeName.isNotEmpty ? emp.employeeName[0] : 'E',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            emp.employeeName,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
                                              fontWeight: FontWeight.w800,
                                              color: isSelected ? const Color(0xFF059669) : const Color(0xFF334155),
                                            ),
                                          ),
                                          onTap: () => setState(() => _selectedEmployee = emp),
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
                                        borderRadius: BorderRadius.circular(14),
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
                                          // Top Actions
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'OFFICIAL PAYSLIP: ${selected.employeeName}',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                  ),
                                                  Text(
                                                    'Employee Code: ${selected.empNo} • Month: $_selectedMonth • Official Verified Voucher',
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed: () => PayrollPdfService.printPayslipPdf(selected, month: _selectedMonth),
                                                    icon: const Icon(Icons.print_outlined, size: 16),
                                                    label: const Text('Print Payslip PDF'),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(0xFF334155),
                                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  ElevatedButton.icon(
                                                    onPressed: () => PayrollPdfService.downloadPayslipPdf(selected, month: _selectedMonth),
                                                    icon: const Icon(Icons.download_rounded, size: 16),
                                                    label: const Text('Download Payslip PDF'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF4338CA),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // Document 4 Frame
                                          _buildPayslipCard(selected),
                                        ],
                                      ),
                                    ),
                                  ),
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

  String _formatScreenAmt(double val, {bool showDashIfZero = false}) {
    if (val <= 0.001) return showDashIfZero ? '-' : '';
    if (val % 1 == 0) {
      return _intFmt.format(val);
    }
    return _currFmt.format(val);
  }

  Widget _buildPayslipCard(PayrollRecord selected) {
    final payslip = OfficialPayslipModel.fromPayrollRecord(selected, month: _selectedMonth);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Company Header (Logo on left, Centered Address & Title & Name, Symmetrical right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 52,
                      child: Image.asset(
                        'assets/images/edp_logo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (context, error, stackTrace) => const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'EDP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            Text(
                              'Exclusive Diamond Products',
                              style: TextStyle(fontSize: 8, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'No.62, Eswaran Koil Street',
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Porur, Chennai - 600116',
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Pay Slip - ${payslip.monthTitle}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payslip.employeeName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 140),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Employee Details Table (4 columns)
                Table(
                  border: TableBorder.all(color: Colors.black, width: 0.8),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.8),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.8),
                  },
                  children: [
                    _buildScreenDetailRow('Employee No.', payslip.empNo, 'PAN No.', payslip.panNo),
                    _buildScreenDetailRow('Designation', payslip.designation, 'PF No.', payslip.pfNo),
                    _buildScreenDetailRow('Department', payslip.department, 'ESI No.', payslip.esiNo),
                    _buildScreenDetailRow('Date of Joining', payslip.doj, 'Bank A/c No.', payslip.bankAccountNo),
                  ],
                ),

                // 3. Attendance Table (8 columns) - shares top border
                Table(
                  border: const TableBorder(
                    left: BorderSide(color: Colors.black, width: 0.8),
                    right: BorderSide(color: Colors.black, width: 0.8),
                    bottom: BorderSide(color: Colors.black, width: 0.8),
                    horizontalInside: BorderSide(color: Colors.black, width: 0.8),
                    verticalInside: BorderSide(color: Colors.black, width: 0.8),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.1),
                    1: FlexColumnWidth(0.9),
                    2: FlexColumnWidth(1.1),
                    3: FlexColumnWidth(0.9),
                    4: FlexColumnWidth(1.1),
                    5: FlexColumnWidth(0.9),
                    6: FlexColumnWidth(1.3),
                    7: FlexColumnWidth(1.1),
                  },
                  children: [
                    TableRow(
                      children: [
                        _screenCell('Leave', isBold: true),
                        _screenCell(payslip.leave, align: TextAlign.center),
                        _screenCell('Balance', isBold: true),
                        _screenCell(payslip.balance, align: TextAlign.center),
                        _screenCell('LOP', isBold: true),
                        _screenCell(payslip.lop, align: TextAlign.center),
                        _screenCell('OT Hours', isBold: true),
                        _screenCell(payslip.otHours, align: TextAlign.center),
                      ],
                    ),
                  ],
                ),

                // 4. Earnings & Deductions Table (4 columns) - shares top border
                Table(
                  border: const TableBorder(
                    left: BorderSide(color: Colors.black, width: 0.8),
                    right: BorderSide(color: Colors.black, width: 0.8),
                    bottom: BorderSide(color: Colors.black, width: 0.8),
                    horizontalInside: BorderSide(color: Colors.black, width: 0.8),
                    verticalInside: BorderSide(color: Colors.black, width: 0.8),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.8),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.8),
                    3: FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      children: [
                        _screenCell('Earnings', isBold: true),
                        _screenCell('Amount (Rs.)', isBold: true, align: TextAlign.right),
                        _screenCell('Deductions', isBold: true),
                        _screenCell('Amount (Rs.)', isBold: true, align: TextAlign.right),
                      ],
                    ),
                    // 8 Official Item Rows
                    _buildScreenItemRow('Basic', _formatScreenAmt(payslip.basic), 'PF', _formatScreenAmt(payslip.pf)),
                    _buildScreenItemRow('HRA', _formatScreenAmt(payslip.hra), 'ESI', _formatScreenAmt(payslip.esi, showDashIfZero: true)),
                    _buildScreenItemRow('Lunch', _formatScreenAmt(payslip.lunch), 'TDS', _formatScreenAmt(payslip.tds)),
                    _buildScreenItemRow('Transport', _formatScreenAmt(payslip.transport), 'Prof Tax', _formatScreenAmt(payslip.profTax)),
                    _buildScreenItemRow('Medical', _formatScreenAmt(payslip.medical), 'Advance/Loan', _formatScreenAmt(payslip.advanceLoan)),
                    _buildScreenItemRow('Special Allowance', _formatScreenAmt(payslip.specialAllowance), 'Insurance', _formatScreenAmt(payslip.insurance)),
                    _buildScreenItemRow('Overtime', _formatScreenAmt(payslip.overtime), 'Other Deductions', _formatScreenAmt(payslip.otherDeductions)),
                    _buildScreenItemRow('Other Allowance*', _formatScreenAmt(payslip.otherAllowance), '', ''),
                    // Totals Row
                    TableRow(
                      children: [
                        _screenCell('Total', isBold: true),
                        _screenCell(_formatScreenAmt(payslip.totalEarnings), isBold: true, align: TextAlign.right),
                        _screenCell('Total', isBold: true),
                        _screenCell(_formatScreenAmt(payslip.totalDeductions), isBold: true, align: TextAlign.right),
                      ],
                    ),
                  ],
                ),

                // 5. Net Salary Box
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 0.8),
                      right: BorderSide(color: Colors.black, width: 0.8),
                      bottom: BorderSide(color: Colors.black, width: 0.8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Salary',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        _formatScreenAmt(payslip.netSalary),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),

                // 6. Footnote
                const Text(
                  '*Includes Arrears if any. Computer generated statement and signature not required',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TableRow _buildScreenDetailRow(String l1, String v1, String l2, String v2) {
    return TableRow(
      children: [
        _screenCell(l1, isBold: true),
        _screenCell(v1),
        _screenCell(l2, isBold: true),
        _screenCell(v2),
      ],
    );
  }

  static TableRow _buildScreenItemRow(String earnLabel, String earnVal, String dedLabel, String dedVal) {
    return TableRow(
      children: [
        _screenCell(earnLabel),
        _screenCell(earnVal, align: TextAlign.right),
        _screenCell(dedLabel),
        _screenCell(dedVal, align: TextAlign.right),
      ],
    );
  }

  static Widget _screenCell(
    String text, {
    bool isBold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : align == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
        textAlign: align,
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
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
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
                  'Official Employee Pay Slips • Porur, Chennai 600116',
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
}
