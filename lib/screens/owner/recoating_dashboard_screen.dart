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
    final HSLColor hsl = HSLColor.fromColor(baseColor);
    final Color darkerColor = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          colors: [baseColor, darkerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      count.toString(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
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
