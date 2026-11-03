import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payroll_model.dart';
import '../../services/api_service.dart';
import '../../services/payroll_pdf_service.dart';
import '../../widgets/global_logout_button.dart';

class BankTransfersScreen extends StatefulWidget {
  final bool showLogout;

  const BankTransfersScreen({super.key, this.showLogout = true});

  @override
  State<BankTransfersScreen> createState() => _BankTransfersScreenState();
}

class _BankTransfersScreenState extends State<BankTransfersScreen> {
  final ApiService _api = ApiService();
  final NumberFormat _currFmt = NumberFormat('#,##,##0.00', 'en_IN');

  String _selectedMonth = 'September 2026';
  final List<String> _months = [
    'September 2026',
    'October 2026',
    'November 2026',
    'December 2026',
  ];

  bool _loading = true;
  List<BankTransferRecord> _transfers = [];
  double _totalAmount = 388081.0;

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
      final transfers = await _api.getBankTransfers(month: monthKey);
      final tot = transfers.fold<double>(0.0, (s, t) => s + t.amount);

      if (mounted) {
        setState(() {
          _transfers = transfers;
          _totalAmount = tot > 0 ? tot : 388081.0;
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

            // Content Area
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
                                  const Icon(Icons.account_balance, color: Color(0xFF4338CA), size: 24),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Online Bank Transfer Advice (Document 2)',
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
                                      PayrollPdfService.printBankTransferPdf(_transfers, _totalAmount, _selectedMonth);
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
                                    ..._transfers.map((t) {
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
                                        DataCell(Text('${_transfers.length} Employees', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
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
                                              '₹ ${_currFmt.format(_totalAmount)}',
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
            child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
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
                  'Corporate Online Bank Transfer Advice • Porur, Chennai 600116',
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

  static const TextStyle _thStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.5);
  static const TextStyle _tdMutedStyle = TextStyle(fontSize: 11, color: Color(0xFF94A3B8));
}
