import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../widgets/job_type_badge.dart';
import '../../widgets/global_logout_button.dart';
import 'job_timeline_screen.dart';

class JobApprovalScreen extends StatefulWidget {
  final int initialTab;

  const JobApprovalScreen({super.key, this.initialTab = 0});

  @override
  State<JobApprovalScreen> createState() => _JobApprovalScreenState();
}

class _JobApprovalScreenState extends State<JobApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  bool _loading = true;
  List<JobModel> _allJobs = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadJobs();
  }

  @override
  void didUpdateWidget(covariant JobApprovalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != _tabController.index) {
      _tabController.animateTo(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      final jobs = await _api.getFilteredJobs();
      if (mounted) {
        setState(() {
          _allJobs = jobs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load jobs: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<JobModel> get _requestJobs {
    return _allJobs.where((j) {
      if (j.accessGranted) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return j.jobId.toLowerCase().contains(q) ||
          (j.partNumber?.toLowerCase().contains(q) ?? false) ||
          (j.customerName?.toLowerCase().contains(q) ?? false) ||
          (j.partDescription?.toLowerCase().contains(q) ?? false) ||
          (j.wheelSize?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<JobModel> get _grantedJobs {
    return _allJobs.where((j) {
      if (!j.accessGranted) return false;
      if (j.grantedAt == null && j.grantedBy == null) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return j.jobId.toLowerCase().contains(q) ||
          (j.partNumber?.toLowerCase().contains(q) ?? false) ||
          (j.customerName?.toLowerCase().contains(q) ?? false) ||
          (j.partDescription?.toLowerCase().contains(q) ?? false) ||
          (j.wheelSize?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _grantAccess(JobModel job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            const Text('Grant Access?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve access for Job #${job.jobId}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${job.customerName ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Part Number: ${job.partNumber ?? 'N/A'}', style: const TextStyle(fontSize: 13)),
                  Text('Quantity: ${job.quantity ?? 0}', style: const TextStyle(fontSize: 13)),
                  if (job.requestedBy != null)
                    Text('Requested by: ${job.requestedBy}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Once approved, this job will become active and accessible for Admin and Employees.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.grantJobAccess(job.jobId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access granted for #${job.jobId}'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
          _loadJobs();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to grant access: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allJobs.where((j) => !j.accessGranted).length;
    final grantedCount = _allJobs.where((j) => j.accessGranted && (j.grantedAt != null || j.grantedBy != null)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Job Access Approvals', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          const GlobalLogoutButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF202124)),
            onPressed: _loading ? null : _loadJobs,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A73E8),
          unselectedLabelColor: const Color(0xFF5F6368),
          indicatorColor: const Color(0xFF1A73E8),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 8),
                  const Text('Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pendingCount > 0 ? const Color(0xFFE65100) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 18),
                  const SizedBox(width: 8),
                  const Text('Granted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: grantedCount > 0 ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$grantedCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by Job ID, Customer, Part Number, Description',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestListView(_requestJobs),
                      _buildGrantedListView(_grantedJobs),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestListView(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Pending Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
              ),
              const SizedBox(height: 8),
              const Text(
                'All jobs created by admin and employees have been approved, or no new requests exist.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildRequestJobCard(job);
        },
      ),
    );
  }

  Widget _buildRequestJobCard(JobModel job) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFB74D), width: 1.5),
      ),
      color: const Color(0xFFFFFDF9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                JobTypeBadge(jobType: job.jobType ?? 'New'),
                if (job.isAssembly || (job.numberOfSets != null && job.numberOfSets! > 0)) ...[
                  const SizedBox(width: 8),
                  SetsBadge(numberOfSets: job.numberOfSets),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_clock, size: 12, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(
                        'Requested by: ${job.requestedBy ?? 'Admin'}',
                        style: const TextStyle(color: Color(0xFFE65100), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.customerName?.isNotEmpty == true
                  ? job.customerName!
                  : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card #${job.jobId}'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF202124)),
            ),
            if (job.wheelSize != null && job.wheelSize!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Description: ${job.wheelSize!}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: _buildInfoItem('Job ID', job.jobId)),
                Expanded(child: _buildInfoItem('Part Number', job.partNumber ?? 'N/A')),
                Expanded(child: _buildInfoItem('Quantity', '${job.quantity ?? 0}')),
                Expanded(child: _buildInfoItem('Status', job.status)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(job.createdDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JobTimelineScreen(job: job)),
                    ).then((_) => _loadJobs());
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A73E8),
                    side: const BorderSide(color: Color(0xFF1A73E8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _grantAccess(job),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Grant Access'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrantedListView(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Granted Jobs Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Jobs approved by the owner will appear here in the Granted list.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildGrantedJobCard(job);
        },
      ),
    );
  }

  Widget _buildGrantedJobCard(JobModel job) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFC8E6C9), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                JobTypeBadge(jobType: job.jobType ?? 'New'),
                if (job.isAssembly || (job.numberOfSets != null && job.numberOfSets! > 0)) ...[
                  const SizedBox(width: 8),
                  SetsBadge(numberOfSets: job.numberOfSets),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        'Granted by ${job.grantedBy ?? 'Owner'}',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.customerName?.isNotEmpty == true
                  ? job.customerName!
                  : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card #${job.jobId}'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF202124)),
            ),
            if (job.wheelSize != null && job.wheelSize!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Description: ${job.wheelSize!}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: _buildInfoItem('Job ID', job.jobId)),
                Expanded(child: _buildInfoItem('Part Number', job.partNumber ?? 'N/A')),
                Expanded(child: _buildInfoItem('Quantity', '${job.quantity ?? 0}')),
                Expanded(child: _buildInfoItem('Current Status', job.status)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (job.grantedAt != null) ...[
                  const Icon(Icons.event_available, size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  Text(
                    'Granted: ${DateFormat('dd MMM yyyy, hh:mm a').format(job.grantedAt!)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(job.createdDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (job.requestedBy != null) ...[
                  const SizedBox(width: 12),
                  Text('(Requested by: ${job.requestedBy})', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JobTimelineScreen(job: job)),
                    ).then((_) => _loadJobs());
                  },
                  icon: const Icon(Icons.timeline, size: 16),
                  label: const Text('View Timeline & Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A73E8),
                    side: const BorderSide(color: Color(0xFF1A73E8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF202124))),
      ],
    );
  }
}
