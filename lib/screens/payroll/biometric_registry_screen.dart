import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../widgets/global_logout_button.dart';
import 'face_enrollment_dialog.dart';

class BiometricRegistryScreen extends StatefulWidget {
  final bool showLogout;

  const BiometricRegistryScreen({super.key, this.showLogout = true});

  @override
  State<BiometricRegistryScreen> createState() => _BiometricRegistryScreenState();
}

class _BiometricRegistryScreenState extends State<BiometricRegistryScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  List<EnrolledEmployeeModel> _employees = [];
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
      if (mounted) {
        setState(() {
          _employees = list;
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
                                    'Staff Registry: All 16 company employees from the official payroll master are listed below. Click "Enroll Face" to capture or upload employee photos. When an unrecognized person or non-enrolled staff faces the camera terminal, attendance will NOT be marked.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. SEARCH & SUMMARY ROW
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
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Text(
                                  'Pending: ${totalCount - enrolledCount} Staff',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 3. STAFF CARDS GRID (ALL 16 EMPLOYEES)
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 400,
                                mainAxisExtent: 200,
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
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            emp.lastEnrolledAt != null
                                                ? 'Enrolled: ${DateFormat('dd MMM yyyy').format(emp.lastEnrolledAt!)}'
                                                : 'Pending photo enrollment',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isEnrolled ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                              fontWeight: isEnrolled ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => _openEnrollmentDialog(emp),
                                            icon: Icon(isEnrolled ? Icons.refresh : Icons.camera_alt, size: 14),
                                            label: Text(isEnrolled ? 'Re-enroll' : 'Enroll Face'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isEnrolled ? const Color(0xFF0F172A) : const Color(0xFF4338CA),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
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
