import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../services/payroll_pdf_service.dart';
import '../../widgets/global_logout_button.dart';

class ExecutiveOverviewScreen extends StatefulWidget {
  final bool showLogout;

  const ExecutiveOverviewScreen({super.key, this.showLogout = true});

  @override
  State<ExecutiveOverviewScreen> createState() => _ExecutiveOverviewScreenState();
}

class _ExecutiveOverviewScreenState extends State<ExecutiveOverviewScreen> {
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
  PayrollSummary? _summary;
  Map<String, dynamic> _totals = {};
  List<PayrollRecord> _records = [];

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
      final summary = await _api.getPayrollSummary(month: monthKey);
      final statementData = await _api.getPayrollStatement(month: monthKey);

      if (mounted) {
        setState(() {
          _summary = summary;
          _totals = (statementData['totals'] as Map<String, dynamic>?) ?? {};
          _records = (statementData['records'] as List<PayrollRecord>?) ?? [];
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

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top Executive Header
            _buildHeader(navySlate),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF4338CA)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Title
                          Row(
                            children: [
                              const Icon(Icons.insights, color: Color(0xFF4338CA), size: 22),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Executive Payroll & Labor Analytics',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'High-level corporate KPI summary, compensation structures, and workforce distribution',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFC7D2FE)),
                                ),
                                child: const Text(
                                  'Owner Confidential',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 5 Primary Metric Cards
                          _buildKpiGrid(),
                          const SizedBox(height: 24),

                          // Department Payroll Breakdown & Statutory Summary
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Department Breakdown (Left 60%)
                              Expanded(
                                flex: 6,
                                child: _buildDepartmentBreakdownCard(),
                              ),
                              const SizedBox(width: 20),

                              // Statutory & Labor Distribution (Right 40%)
                              Expanded(
                                flex: 4,
                                child: _buildStatutoryBreakdownCard(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Overtime Analysis & Personal Loan Highlights
                          _buildOvertimeAndLoanHighlights(),
                        ],
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
            child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 24),
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
                  'No.62, Eswaran Koil Street, Porur, Chennai 600116 • ISO 9001:2015 Manufacturing Plant',
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

          ElevatedButton.icon(
            onPressed: () {
              if (_records.isNotEmpty) {
                PayrollPdfService.printMasterStatementPdf(_records, _totals, _selectedMonth);
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

  Widget _buildKpiGrid() {
    final netDisbursed = (_totals['netSalary'] as num?)?.toDouble() ?? 388081.0;
    final grossPayroll = (_totals['grossSalary'] as num?)?.toDouble() ?? 423519.0;
    final totalDeductions = (_totals['totalDeductions'] as num?)?.toDouble() ?? 35438.0;
    final totalOtAmount = (_totals['otAmount'] as num?)?.toDouble() ?? 43583.0;
    final loanOutstanding = _summary?.totalLoanBalance ?? 689000.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'NET DISBURSED',
            value: '₹ ${_intFmt.format(netDisbursed)}',
            subtitle: '16 Employees • 100% Direct Bank Transfer',
            icon: Icons.payments,
            accentColor: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            badgeText: 'Disbursed',
            badgeBg: const Color(0xFFD1FAE5),
            badgeColor: const Color(0xFF065F46),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricCard(
            title: 'GROSS PAYROLL',
            value: '₹ ${_intFmt.format(grossPayroll)}',
            subtitle: 'Base: ₹ 3.80L + OT: ₹ 43.6K',
            icon: Icons.trending_up,
            accentColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            badgeText: '30 Days Cycle',
            badgeBg: const Color(0xFFDBEAFE),
            badgeColor: const Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(width: 14),
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
        const SizedBox(width: 14),
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
        const SizedBox(width: 14),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDepartmentBreakdownCard() {
    final depts = [
      {'name': 'Production & Shop Floor', 'count': 10, 'gross': 274682.0, 'net': 252199.0, 'ot': 43583.0, 'color': const Color(0xFF4338CA)},
      {'name': 'Administration & Operations', 'count': 3, 'gross': 80300.0, 'net': 74100.0, 'ot': 0.0, 'color': const Color(0xFF0D9488)},
      {'name': 'Marketing & Client Relations', 'count': 1, 'gross': 35800.0, 'net': 28542.0, 'ot': 0.0, 'color': const Color(0xFFD97706)},
      {'name': 'Logistics & Dispatch Transport', 'count': 1, 'gross': 26414.0, 'net': 25694.0, 'ot': 2214.0, 'color': const Color(0xFF2563EB)},
      {'name': 'Accounts & Financial Audit', 'count': 1, 'gross': 18000.0, 'net': 15745.0, 'ot': 0.0, 'color': const Color(0xFF7C3AED)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Department-Wise Payroll Distribution',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Text(
                '16 Active Employees Across 5 Divisions',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...depts.map((d) {
            final double gross = d['gross'] as double;
            final pct = (gross / 423519.0) * 100;
            final color = d['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(width: 6),
                      Text('(${d['count']} Staff)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const Spacer(),
                      Text('₹ ${_intFmt.format(gross)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatutoryBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statutory Deductions & Recovery',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total Monthly Deductions: ₹ 35,438.00',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          _statRow('Staff Personal Loans', 15000.0, const Color(0xFF7C3AED), '7 Staff Accounts'),
          _statRow('Provident Fund (P.F.)', 10596.0, const Color(0xFF2563EB), '11 Subscribed'),
          _statRow('Insurance Premium', 9720.0, const Color(0xFFD97706), 'Group Life & Medical'),
          _statRow('Employee State Ins (ESI)', 122.0, const Color(0xFF059669), 'Production Assistant'),
          _statRow('TDS / Professional Tax', 0.0, const Color(0xFF64748B), 'Zero TDS Applied'),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Employer PF Contribution', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              Text('₹ ${_intFmt.format(_totals['employerPf'] ?? 10596)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Employer ESI Contribution', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              Text('₹ ${_intFmt.format(_totals['employerEsi'] ?? 529)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, double amount, Color color, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          Text(
            '₹ ${_currFmt.format(amount)}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeAndLoanHighlights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, size: 28, color: Color(0xFF059669)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exclusive Diamond Products • Banking & Disbursement Verification',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  '100% of Net Salary (₹ 3,88,081.00) disbursed via direct NEFT/RTGS to verified employee bank accounts on 05-Oct-2026.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_records.isNotEmpty) {
                final tot = _totals['netSalary'] as double? ?? 388081.0;
                final transfers = _records.asMap().entries.map((e) => BankTransferRecord(
                  slNo: e.key + 1,
                  empNo: e.value.empNo,
                  employeeName: e.value.employeeName,
                  bankName: e.value.bankName,
                  accountNo: e.value.accountNo,
                  ifscCode: e.value.ifscCode,
                  amount: e.value.netSalary,
                  paymentStatus: 'Paid',
                  paymentDate: '05-10-2026',
                )).toList();
                PayrollPdfService.printBankTransferPdf(transfers, tot, _selectedMonth);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View Bank Advice PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
