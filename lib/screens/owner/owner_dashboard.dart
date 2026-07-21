import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import '../login_screen.dart';
import 'filtered_jobs_screen.dart';
import 'material_search_screen.dart';
import 'recoating_dashboard_screen.dart';
import 'production_dashboard_screen.dart';
import 'blank_orders_screen.dart';
import 'spare_production_dashboard_screen.dart';
import '../../widgets/flowdesk_logo.dart';
import '../../widgets/drawer_menu_button.dart';
import 'package:intl/intl.dart';
import 'alerts_screen.dart';
import '../../models/notification_model.dart';
import 'job_timeline_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<JobModel> _currentJobs = [];
  List<NotificationModel> _alerts = [];

  int _returnedJobs = 0;
  int _recoatingJobs = 0;
  int _productionJobs = 0;
  int _readyForDeliveryJobs = 0;
  int _blankOrders = 0;
  int _poNotGivenCount = 0;

  String? _selectedMonth;
  String? _selectedDate;
  
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = null;
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = await _api.getFilteredJobs(
        month: _selectedMonth,
        date: _selectedDate,
      );
      final stats = _selectedDate != null 
        ? await _api.getDashboardDateStats(_selectedDate!) 
        : await _api.getDashboardMonthStats(_selectedMonth!);
      
      final notifications = await _api.getNotifications();

      if (mounted) {
        _currentJobs = jobs;
        _alerts = notifications.take(5).toList();

        _returnedJobs = jobs.where((j) => j.status == 'Returned').length;
        _poNotGivenCount = stats?['poNotGivenCount'] ?? 0;
        final recoatingJobs = jobs.where((j) => j.jobType == 'Re-coating').toList();
        _recoatingJobs = recoatingJobs.where((j) => j.status == 'Created' || j.status == 'Arrived' || j.status == 'Extracted').length;
        _productionJobs = jobs.where((j) => j.status != 'Removed' && j.status != 'Closed' && j.status != 'Delivered' && j.status != 'Returned' && j.status != 'Completed' && j.jobType != 'New' && !(j.jobType == 'Re-coating' && (j.status == 'Created' || j.status == 'Arrived' || j.status == 'Extracted'))).length;
        _readyForDeliveryJobs = jobs.where((j) => j.status == 'Completed').length;

        _blankOrders = jobs.where((j) => j.status == 'Blank Order' && j.sentToSpare != true).length;
        _poNotGivenCount = jobs.where((j) => j.poNotGiven == true).length;

      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd-MM-yyyy').format(picked);
        _selectedMonth = null;
      });
      _load();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
    });
    _load();
  }

  void _performSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      _searchCtrl.clear();
      Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialSearchScreen(initialQuery: query)))
          .then((_) => _load());
    }
  }

  void _navToFiltered(String title, List<JobModel> jobs, {bool Function(JobModel)? filter}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredJobsScreen(title: title, jobs: jobs, filter: filter, month: _selectedMonth, date: _selectedDate)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    double childAspectRatio = 1.15;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 2.0;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const FlowdeskLogo(fontSize: 24),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF202124)),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF202124)),
            onPressed: _selectDate,
          ),

          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF202124)),
            onPressed: () async {
              await _api.logout();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search Job/Part',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_selectedDate == null)
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            underline: const SizedBox(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF202124)),
                            items: List.generate(12, (index) {
                              final date = DateTime(DateTime.now().year, DateTime.now().month - index, 1);
                              final value = DateFormat('yyyy-MM').format(date);
                              final label = DateFormat('MMMM yyyy').format(date);
                              return DropdownMenuItem(value: value, child: Text(label));
                            }),
                            onChanged: (val) {
                              setState(() => _selectedMonth = val);
                              _load();
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              Text(DateFormat('dd MMMM yyyy').format(DateTime.parse(_selectedDate!)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _clearDateFilter),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: childAspectRatio,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildStatCard('Returned', _returnedJobs, Icons.assignment_return, const Color(0xFF8E24AA), () => _navToFiltered('Returned Materials', _currentJobs.where((j) => j.status == 'Returned').toList())),
                      _buildStatCard('PO Not Given', _poNotGivenCount, Icons.assignment_late, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlankOrdersScreen(jobs: _currentJobs.where((j) => j.poNotGiven == true).toList(), title: 'PO Not Given'))).then((_) => _load())),
                      _buildStatCard('Blank Orders', _blankOrders, Icons.note_add, Colors.orangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlankOrdersScreen(jobs: _currentJobs.where((j) => j.status == 'Blank Order' && j.sentToSpare != true).toList(), title: 'Blank Orders'))).then((_) => _load())),
                      _buildStatCard('Re-coating', _recoatingJobs, Icons.build_circle_outlined, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecoatingDashboardScreen(recoatingJobs: _currentJobs.where((j) => j.jobType == 'Re-coating').toList(), month: _selectedMonth, date: _selectedDate))).then((_) => _load())),
                      _buildStatCard('Production', _productionJobs, Icons.precision_manufacturing, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductionDashboardScreen(productionJobs: _currentJobs.where((j) => j.status != 'Removed' && j.status != 'Closed' && j.status != 'Delivered' && j.status != 'Returned' && j.status != 'Completed' && j.jobType != 'New' && !(j.jobType == 'Re-coating' && (j.status == 'Created' || j.status == 'Arrived' || j.status == 'Extracted'))).toList(), month: _selectedMonth, date: _selectedDate))).then((_) => _load())),
                      _buildStatCard('Ready for Delivery', _readyForDeliveryJobs, Icons.local_shipping, Colors.green, () => _navToFiltered('Ready for Delivery', _currentJobs.where((j) => j.status == 'Completed').toList(), filter: (j) => j.status == 'Completed')),
                      _buildStatCard('EDP Spare Production', 0, Icons.settings_suggest, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpareProductionDashboardScreen()))),
                    ],
                  ),
                ],
              ),
            ),
            
            // Alerts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124))),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())).then((_) => _load()),
                    child: const Text('More'),
                  ),
                ],
              ),
            ),
            if (_alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Center(child: Text('No active alerts.', style: TextStyle(color: Colors.grey))),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _alerts.map((alert) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: alert.jobId != null ? () async {
                        final jobIndex = _currentJobs.indexWhere((j) => j.jobId == alert.jobId);
                        if (jobIndex != -1) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => JobTimelineScreen(job: _currentJobs[jobIndex])));
                        } else {
                          final job = await _api.getJobByJobId(alert.jobId!);
                          if (job != null && context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => JobTimelineScreen(job: job)));
                          }
                        }
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            alert.type == 'delayed' ? Icons.warning_amber_rounded : Icons.info_outline,
                            color: alert.type == 'delayed' ? Colors.orange : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert.message, style: const TextStyle(fontSize: 13, color: Color(0xFF202124), fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd MMM yyyy, hh:mm a').format(alert.createdAt.toLocal()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ), // closes InkWell
                )).toList(),
                ),
              ),
            const SizedBox(height: 24),          ],
        ),
      ),
    );
  }



  Widget _buildStatCard(String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05),
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 36),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF5F6368), size: 14),
                  ),
                ],
              ),
              const Spacer(),
              Text('$count', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF202124), letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF5F6368), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }


}


