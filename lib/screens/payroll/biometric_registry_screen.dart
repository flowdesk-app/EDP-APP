import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../widgets/global_logout_button.dart';
import 'add_edit_employee_dialog.dart';
import 'face_enrollment_dialog.dart';

class BiometricRegistryScreen extends StatefulWidget {
  final bool showLogout;

  const BiometricRegistryScreen({super.key, this.showLogout = true});

  @override
  State<BiometricRegistryScreen> createState() => _BiometricRegistryScreenState();
}

class _BiometricRegistryScreenState extends State<BiometricRegistryScreen> {
  final ApiService _api = ApiService();
  final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

  bool _loading = true;
  List<EnrolledEmployeeModel> _employees = [];
  List<Map<String, dynamic>> _alerts = [];
  String _searchQuery = '';
  String _selectedDept = 'All';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getEnrolledEmployees();
      final alerts = await _api.getPayrollNotifications();
      if (mounted) {
        setState(() {
          _employees = list;
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openEnrollmentDialog(EnrolledEmployeeModel emp) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => FaceEnrollmentDialog(employee: emp),
    );
    if (updated == true) {
      _loadEmployees();
    }
  }

  void _openAddEmployeeDialog() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AddEditEmployeeDialog(),
    );
    if (updated == true) {
      _loadEmployees();
    }
  }

  void _openEditEmployeeDialog(EnrolledEmployeeModel emp) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditEmployeeDialog(employeeToEdit: emp),
    );
    if (updated == true) {
      _loadEmployees();
    }
  }

  Future<void> _promptRemoveEmployee(EnrolledEmployeeModel emp) async {
    final empNo = emp.empNo ?? '';

    // Check for active loan liabilities
    final loanCheck = await _api.checkEmployeeLoans(empNo);
    final hasLoan = loanCheck['hasLoan'] == true;
    final loan = loanCheck['loan'];

    if (!mounted) return;

    if (hasLoan && loan != null) {
      // LOAN LIABILITY DETECTED DIALOG
      final sanctioned = (loan['loanSanctioned'] as num?)?.toDouble() ?? 0.0;
      final balance = (loan['closingBalance'] as num?)?.toDouble() ?? 0.0;
      final deduction = (loan['monthlyDeduction'] as num?)?.toDouble() ?? 0.0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 26),
              SizedBox(width: 10),
              Text('Active Loan Liability Detected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee ${emp.name} (#$empNo) has an active staff personal loan that has NOT been fully repaid.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  children: [
                    _dialogStatRow('Loan Sanctioned', '₹ ${_intFmt.format(sanctioned)}'),
                    const SizedBox(height: 6),
                    _dialogStatRow('Outstanding Balance', '₹ ${_intFmt.format(balance)}', isBold: true, color: const Color(0xFFDC2626)),
                    const SizedBox(height: 6),
                    _dialogStatRow('Monthly Recovery', '₹ ${_intFmt.format(deduction)}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Note: Confirming removal will remove the employee from the biometric scanner and active payroll roster, and generate a settlement notification on the Executive Dashboard for final recovery.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel & Retain Employee'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _api.removePayrollEmployee(empNo, force: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Employee removed with loan settlement alert!'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                  _loadEmployees();
                }
              },
              child: const Text('Confirm & Log Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      // NO LOANS - STANDARD SAFE REMOVAL
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Employee Removal', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to remove ${emp.name} (#$empNo)?\n\nThey have zero active loan balances and clean statutory records.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _api.removePayrollEmployee(empNo, force: false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Employee removed successfully!'),
                      backgroundColor: const Color(0xFF0F172A),
                    ),
                  );
                  _loadEmployees();
                }
              },
              child: const Text('Remove Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _dialogStatRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? const Color(0xFF0F172A),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  List<String> get _departments {
    final set = <String>{'All'};
    for (var e in _employees) {
      if (e.department.isNotEmpty) set.add(e.department);
    }
    return set.toList();
  }

  List<EnrolledEmployeeModel> get _filteredEmployees {
    return _employees.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q) ||
          (e.empNo != null && e.empNo!.toLowerCase().contains(q)) ||
          e.department.toLowerCase().contains(q);
      final matchesDept = _selectedDept == 'All' || e.department == _selectedDept;
      return matchesSearch && matchesDept;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgSlate = Color(0xFFF8FAFC);
    const navySlate = Color(0xFF0F172A);
    final enrolledCount = _employees.where((e) => e.isFaceEnrolled).length;
    final totalCount = _employees.length;

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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Loan Settlement Alerts Banner (if any)
                          if (_alerts.isNotEmpty) ...[
                            _buildAlertsBanner(),
                            const SizedBox(height: 16),
                          ],

                          // 1. INFO BANNER
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Staff Registry: Use "+ Add New Employee" to register staff and configure their salary & biometrics. When removing employees with active personal loans, a settlement notification will be created on the Executive Dashboard. Only enrolled staff will be recognized for shift attendance.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. SEARCH & SUMMARY ROW WITH ADD BUTTON
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                    decoration: InputDecoration(
                                      hintText: 'Search staff by name, code (e.g. 20004), or department...',
                                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                                      filled: true,
                                      fillColor: Colors.white,
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

                              // Department chips
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
                                        backgroundColor: Colors.white,
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

                              // + Add New Employee Button
                              ElevatedButton.icon(
                                onPressed: _openAddEmployeeDialog,
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Add Employee'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4338CA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  'Enrolled: $enrolledCount / $totalCount Staff',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3. STAFF CARDS GRID
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400,
                                mainAxisExtent: 210,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (ctx, i) {
                                final emp = _filteredEmployees[i];
                                final isEnrolled = emp.isFaceEnrolled;

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isEnrolled ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                                      width: isEnrolled ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: isEnrolled ? const Color(0xFF10B981) : const Color(0xFFEEF2FF),
                                            child: Text(
                                              emp.name.isNotEmpty ? emp.name[0] : 'E',
                                              style: TextStyle(
                                                color: isEnrolled ? Colors.white : const Color(0xFF4338CA),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    if (emp.empNo != null && emp.empNo!.isNotEmpty)
                                                      Container(
                                                        margin: const EdgeInsets.only(right: 6),
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                                        ),
                                                        child: Text(
                                                          '#${emp.empNo}',
                                                          style: const TextStyle(
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.w800,
                                                            color: Color(0xFF0F172A),
                                                            fontFamily: 'monospace',
                                                          ),
                                                        ),
                                                      ),
                                                    Expanded(
                                                      child: Text(
                                                        emp.name,
                                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  emp.designation != null && emp.designation!.isNotEmpty
                                                      ? emp.designation!
                                                      : emp.department,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Dept: ${emp.department}',
                                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isEnrolled ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: isEnrolled ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                                            ),
                                            child: Text(
                                              isEnrolled ? 'Enrolled' : 'Not Enrolled',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isEnrolled ? const Color(0xFF15803D) : const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              // Edit details button
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF4338CA)),
                                                tooltip: 'Edit Details & Salary',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _openEditEmployeeDialog(emp),
                                              ),
                                              const SizedBox(width: 10),
                                              // Remove employee button
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                                tooltip: 'Remove / Terminate Employee',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _promptRemoveEmployee(emp),
                                              ),
                                            ],
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => _openEnrollmentDialog(emp),
                                            icon: Icon(isEnrolled ? Icons.refresh : Icons.camera_alt, size: 13),
                                            label: Text(isEnrolled ? 'Re-enroll' : 'Enroll Face'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isEnrolled ? const Color(0xFF0F172A) : const Color(0xFF4338CA),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
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

  Widget _buildAlertsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notification_important, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 10),
              Text(
                'Active Loan Settlement Recovery Notifications (${_alerts.length})',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._alerts.map((a) {
            final id = a['_id']?.toString() ?? '';
            final msg = a['message']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(msg, style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D))),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _api.dismissPayrollNotification(id);
                      _loadEmployees();
                    },
                    child: const Text('Mark Settled', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
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
            child: const Icon(Icons.badge, color: Colors.white, size: 24),
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
                  'Staff Facial Biometric Registry & Verification Status • Porur, Chennai Plant',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          if (widget.showLogout) const GlobalLogoutButton(),
        ],
      ),
    );
  }
}
