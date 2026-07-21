import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import 'filtered_jobs_screen.dart';

class RecoatingDashboardScreen extends StatefulWidget {
  final List<JobModel> recoatingJobs;
  final String? month;
  final String? date;

  const RecoatingDashboardScreen({
    super.key, 
    required this.recoatingJobs,
    this.month,
    this.date,
  });

  @override
  State<RecoatingDashboardScreen> createState() => _RecoatingDashboardScreenState();
}

class _RecoatingDashboardScreenState extends State<RecoatingDashboardScreen> {
  List<JobModel> _currentJobs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentJobs = widget.recoatingJobs;
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await ApiService().getFilteredJobs(month: widget.month, date: widget.date);
      if (mounted) {
        setState(() {
          _currentJobs = jobs.where((j) => j.jobType == 'Re-coating').toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navToFiltered(BuildContext context, String title, List<JobModel> jobs, {bool Function(JobModel)? filter}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredJobsScreen(title: title, jobs: jobs, filter: filter, month: widget.month, date: widget.date)))
      .then((_) => _fetchJobs());
  }

  Widget _buildStatCard(BuildContext context, String title, int count, IconData icon, Color baseColor, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: baseColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 20.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: baseColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: baseColor, size: 24),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$count',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    double childAspectRatio = 1.15;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 2.0;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    final arrivedJobs = _currentJobs.where((j) => j.status == 'Created' || j.status == 'Arrived').toList();
    final extractedJobs = _currentJobs.where((j) => j.status == 'Extracted').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Re-coating Dashboard', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard(context, 'Arrived', arrivedJobs.length, Icons.input, Colors.blueAccent, 
              () => _navToFiltered(context, 'Arrived', arrivedJobs, filter: (j) => j.jobType == 'Re-coating' && (j.status == 'Created' || j.status == 'Arrived'))),
            _buildStatCard(context, 'Extracted', extractedJobs.length, Icons.layers_clear, Colors.orange, 
              () => _navToFiltered(context, 'Extracted', extractedJobs, filter: (j) => j.jobType == 'Re-coating' && j.status == 'Extracted')),
          ],
        ),
      ),
    );
  }
}
