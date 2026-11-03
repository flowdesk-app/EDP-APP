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

  List<EnrolledEmployeeModel> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees.where((e) {
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.department.toLowerCase().contains(_searchQuery.toLowerCase());
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search & Summary Row
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                    decoration: InputDecoration(
                                      hintText: 'Search staff by name, email, or department...',
                                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
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
                              const SizedBox(width: 16),
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
                          const SizedBox(height: 20),

                          // Staff Grid
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 380,
                                mainAxisExtent: 180,
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
                                    border: Border.all(color: isEnrolled ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
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
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: isEnrolled ? const Color(0xFF10B981) : const Color(0xFFEEF2FF),
                                            child: Text(
                                              emp.name.isNotEmpty ? emp.name[0] : 'E',
                                              style: TextStyle(
                                                color: isEnrolled ? Colors.white : const Color(0xFF4338CA),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  emp.name,
                                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  emp.department,
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isEnrolled ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isEnrolled ? 'Enrolled' : 'Not Enrolled',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isEnrolled ? const Color(0xFF15803D) : const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            emp.lastEnrolledAt != null
                                                ? 'Enrolled: ${DateFormat('dd MMM yyyy').format(emp.lastEnrolledAt!)}'
                                                : 'No biometric registered',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
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
                                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
