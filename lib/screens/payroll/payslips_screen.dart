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
                                                    'Employee ID: ${selected.empNo} • Disbursed ${selected.paymentDate} • Direct Bank Transfer',
                                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () => PayrollPdfService.printPayslipPdf(selected),
                                                icon: const Icon(Icons.print_outlined, size: 16),
                                                label: const Text('Print Payslip PDF'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF4338CA),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
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

  Widget _buildPayslipCard(PayrollRecord selected) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'EXCLUSIVE DIAMOND PRODUCTS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Color(0xFF0F172A)),
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
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF0F172A)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meta Table
          Table(
            border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.5),
            children: [
              _buildMetaRow('Employee Code', selected.empNo, 'Employee Name', selected.employeeName),
              _buildMetaRow('Designation', selected.designation, 'Department', selected.department),
              _buildMetaRow('Date of Joining', selected.doj, 'Bank Name', selected.bankName),
              _buildMetaRow('Bank A/C No', selected.accountNo, 'IFSC Code', selected.ifscCode),
              _buildMetaRow(
                'UAN Number',
                selected.uanNo.isNotEmpty ? selected.uanNo : 'N/A',
                'PF Number',
                selected.pfNo.isNotEmpty ? selected.pfNo : 'N/A',
              ),
              _buildMetaRow(
                'Total Days in Month',
                '${selected.totalDays} Days',
                'Days Worked / Paid',
                '${selected.daysWorked} Days',
              ),
              _buildMetaRow(
                'Loss of Pay (LOP)',
                '${selected.lopDays} Days',
                'Overtime Hours',
                selected.otHoursFormatted,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Earnings & Deductions Tables
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5)),
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
                      _payslipLine('Overtime Compensation (${selected.otHoursFormatted})', selected.otAmount, isHighlight: selected.otAmount > 0),
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

              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5)),
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
                      _payslipLine('Staff Loan / Advance Recovery', selected.advanceLoan, isHighlight: selected.advanceLoan > 0),
                      _payslipLine('Life / Medical Insurance', selected.insurance),
                      _payslipLine('Tax Deducted at Source (TDS)', selected.tds),
                      _payslipLine('Other Deductions', selected.others),
                      const SizedBox(height: 38),
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

          // Net Take Home Banner
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
                    const Text('NET TAKE-HOME SALARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF065F46))),
                    const SizedBox(height: 2),
                    Text(
                      selected.netSalaryWords.isNotEmpty ? selected.netSalaryWords : 'Rupees ${_intFmt.format(selected.netSalary)} Only',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '₹ ${_currFmt.format(selected.netSalary)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Statutory info
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

          // Signatures
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

  static TableRow _buildMetaRow(String label1, String val1, String label2, String val2) {
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
}
