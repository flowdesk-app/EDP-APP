import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import 'filtered_jobs_screen.dart';

class RecoatingDashboardScreen extends StatefulWidget {
  final List<JobModel> recoatingJobs;

  const RecoatingDashboardScreen({super.key, required this.recoatingJobs});

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
      final jobs = await ApiService().getJobsForOwner();
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredJobsScreen(title: title, jobs: jobs, filter: filter)))
      .then((_) => _fetchJobs());
  }

  Widget _buildStatCard(BuildContext context, String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 1.15,
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
