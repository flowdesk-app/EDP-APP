import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import '../../widgets/flowdesk_logo.dart';
import 'supplier_job_detail.dart';
import '../login_screen.dart';
import 'package:intl/intl.dart';

class SupplierDashboard extends StatefulWidget {
  final String supplierId;
  const SupplierDashboard({super.key, required this.supplierId});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late Future<List<JobModel>> _jobsFuture;
  late TabController _tabController;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
    _load();
  }

  void _load() {
    setState(() {
      _jobsFuture = _api.getJobsForSupplier();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const FlowdeskLogo(fontSize: 24),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _load),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF29B6F6),
          unselectedLabelColor: const Color(0xFF5F6368),
          indicatorColor: const Color(0xFF29B6F6),
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: FutureBuilder<List<JobModel>>(
        future: _jobsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snap.data ?? [];
          
          final assigned = jobs.where((j) => j.status != 'Delivered' && j.status != 'Delivered' && j.status != 'Closed' && j.status != 'Removed').toList();
          final allDelivered = jobs.where((j) => j.status == 'Delivered' || j.status == 'Delivered' || j.status == 'Closed').toList();
          
          final delivered = allDelivered.where((j) {
            if (_selectedMonth == null) return true;
            return DateFormat('yyyy-MM').format(j.createdDate) == _selectedMonth;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(assigned, 'No jobs assigned right now.'),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Text('Month:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedMonth,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF29B6F6)),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124), fontSize: 16),
                          items: List.generate(12, (index) {
                            final date = DateTime(DateTime.now().year, DateTime.now().month - index, 1);
                            final value = DateFormat('yyyy-MM').format(date);
                            final label = DateFormat('MMMM yyyy').format(date);
                            return DropdownMenuItem(value: value, child: Text(label));
                          }),
                          onChanged: (val) => setState(() => _selectedMonth = val),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildList(delivered, 'No items delivered in this month.')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<JobModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 56, color: Color(0xFF1E8E3E)),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: Color(0xFF5F6368))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _JobCard(job: list[i], supplierId: widget.supplierId, onUpdate: _load),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final String supplierId;
  final VoidCallback onUpdate;

  const _JobCard({required this.job, required this.supplierId, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final isDelivered = job.status == 'Delivered' || job.status == 'Delivered' || job.status == 'Closed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE0E0E0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDelivered ? null : () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierJobDetail(job: job, supplierId: supplierId)));
          onUpdate();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(job.partNumber ?? job.customerName ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF29B6F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(job.status, style: const TextStyle(color: Color(0xFF29B6F6), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _row(Icons.precision_manufacturing_outlined, job.processType ?? 'Processing'),
              _row(Icons.inventory_2_outlined, '${job.quantity ?? 0} units — ${job.destinationName ?? ''}'),
              _row(Icons.calendar_today_outlined, 'Dispatched: ${_fmt(job.createdDate)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? const Color(0xFF5F6368)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color ?? const Color(0xFF5F6368)))),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
