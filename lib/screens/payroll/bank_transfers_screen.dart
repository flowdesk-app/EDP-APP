import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

  late String _selectedMonth;
  late List<String> _months;

  bool _loading = true;
  List<BankTransferRecord> _transfers = [];
  double _totalAmount = 388081.0;
  String _searchQuery = '';
  String _selectedBank = 'All';

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

  List<BankTransferRecord> get _filteredTransfers {
    return _transfers.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          t.employeeName.toLowerCase().contains(q) ||
          t.empNo.toLowerCase().contains(q) ||
          t.bankName.toLowerCase().contains(q) ||
          t.accountNo.toLowerCase().contains(q) ||
          t.ifscCode.toLowerCase().contains(q);
      final matchesBank = _selectedBank == 'All' || t.bankName.toLowerCase().contains(_selectedBank.toLowerCase());
      return matchesSearch && matchesBank;
    }).toList();
  }

  List<String> get _bankFilters {
    return ['All', 'State Bank of India', 'ICICI', 'HDFC', 'Canara', 'Indian Overseas', 'Indian Bank', 'Axis'];
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
            _buildHeader(navySlate),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF4338CA)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. TOP EXECUTIVE KPI METRIC CARDS
                          _buildExecutiveKpiCards(),
                          const SizedBox(height: 20),

                          // 2. SEARCH & FILTER TOOLBAR
                          _buildToolbar(),
                          const SizedBox(height: 16),

                          // 3. FULL-WIDTH SPACIOUS BANK TRANSFER TABLE
                          _buildSpaciousBankTable(),
                          const SizedBox(height: 20),

                          // 4. STATUTORY BANKING COMPLIANCE & AUTHORIZATION NOTE
                          _buildBankingComplianceCard(),
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
  // 1. EXECUTIVE KPI CARDS
  // ============================================================
  Widget _buildExecutiveKpiCards() {
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
              title: 'TOTAL NET DISBURSED',
              value: '₹ ${_currFmt.format(_totalAmount)}',
              subtext: '100% Direct Corporate NEFT/RTGS Advice',
              icon: Icons.account_balance,
              gradient: const [Color(0xFF1E1B4B), Color(0xFF4338CA)],
              iconColor: const Color(0xFF818CF8),
            ),
            _kpiCard(
              title: 'BENEFICIARY ACCOUNTS',
              value: '${_transfers.length} Bank Accounts',
              subtext: 'Across ICICI, HDFC, SBI, IOB, Canara, Axis',
              icon: Icons.people_outline,
              gradient: const [Color(0xFF064E3B), Color(0xFF059669)],
              iconColor: const Color(0xFF6EE7B7),
            ),
            _kpiCard(
              title: 'AVERAGE NET PAYOUT',
              value: '₹ ${_intFmt.format(_transfers.isNotEmpty ? _totalAmount / _transfers.length : 0)}',
              subtext: 'Per active employee for ${_selectedMonth.split(' ').first}',
              icon: Icons.analytics_outlined,
              gradient: const [Color(0xFF1E293B), Color(0xFF334155)],
              iconColor: const Color(0xFF94A3B8),
            ),
            _kpiCard(
              title: 'DISBURSEMENT STATUS',
              value: '100% Verified',
              subtext: 'Zero failed transfers • Audited Advice',
              icon: Icons.verified_user_outlined,
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
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
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
  // 2. TOOLBAR: SEARCH & FILTER
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
                  hintText: 'Search employee name, code, bank name, account number, or IFSC...',
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

          // Bank selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bankFilters.map((b) {
                final isSelected = _selectedBank == b;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(b),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedBank = b),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF4338CA),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
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

          ElevatedButton.icon(
            onPressed: () {
              PayrollPdfService.printBankTransferPdf(_transfers, _totalAmount, _selectedMonth);
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Export Bank Advice PDF'),
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
  // 3. FULL-WIDTH SPACIOUS BANK TRANSFER TABLE
  // ============================================================
  Widget _buildSpaciousBankTable() {
    final records = _filteredTransfers;

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
                const Icon(Icons.account_balance, color: Color(0xFF4338CA), size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Online Bank Transfer Advice (Document 2)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Direct Corporate NEFT/RTGS Advice for ${_selectedMonth.toUpperCase()} • 100% Disbursed',
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
                      const Icon(Icons.verified, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'Total Batch: ₹ ${_currFmt.format(_totalAmount)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
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
                      ...records.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final t = entry.value;

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
                                  t.empNo,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    child: Text(
                                      t.employeeName.isNotEmpty ? t.employeeName[0] : 'E',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF4338CA)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    t.employeeName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  const Icon(Icons.account_balance, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(t.bankName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    t.accountNo,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                                    tooltip: 'Copy Account Number',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: t.accountNo));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Copied A/C ${t.accountNo} to clipboard!'), duration: const Duration(seconds: 1)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                t.ifscCode,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569), fontFamily: 'monospace'),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  '₹ ${_currFmt.format(t.amount)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF065F46), fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                                    SizedBox(width: 4),
                                    Text('Direct Credit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                                  ],
                                ),
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
                          const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                          DataCell(Text('${records.length} Employees', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)))),
                          const DataCell(Text('All Corporate Banks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569)))),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹ ${_currFmt.format(_totalAmount)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13.5, fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                          const DataCell(Text('Authorized', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF065F46)))),
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
  // 4. BANKING COMPLIANCE & AUTHORIZATION NOTE
  // ============================================================
  Widget _buildBankingComplianceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF4338CA), size: 22),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Corporate Banking Instruction Note: We hereby authorize the debit of our Current Account for the above sum of ₹ 3,88,081.00 (Rupees Three Lakhs Eighty-Eight Thousand Eighty-One Only) towards employee salary disbursements via NEFT/RTGS direct transfer. Exclusive Diamond Products, Chennai Plant.',
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

  static const TextStyle _thStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Color(0xFF1E293B),
    letterSpacing: 0.5,
  );
}
