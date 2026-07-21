import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import 'job_timeline_screen.dart';
import '../../widgets/drawer_menu_button.dart';

class RemovedJobsScreen extends StatefulWidget {
  const RemovedJobsScreen({super.key});

  @override
  State<RemovedJobsScreen> createState() => _RemovedJobsScreenState();
}

class _RemovedJobsScreenState extends State<RemovedJobsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<JobModel> _jobs = [];
  bool _isEditing = false;
  final Set<String> _selectedJobIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRemovedJobs();
  }

  Future<void> _fetchRemovedJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final jobs = await _api.getFilteredJobs(status: 'Removed');
      setState(() => _jobs = jobs);
    } catch (e) {
      debugPrint('Error fetching removed jobs: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelectedJobs() async {
    if (_selectedJobIds.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text('Are you sure you want to PERMANENTLY delete ${_selectedJobIds.length} job(s)? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await Future.wait(_selectedJobIds.map((id) async {
        try {
          await _api.deleteJob(id);
        } catch (e) {
          debugPrint('Failed to delete $id: $e');
        }
      }));
      if (!mounted) return;
      Navigator.pop(context); // close progress
      setState(() {
        _isEditing = false;
        _selectedJobIds.clear();
      });
      _fetchRemovedJobs();
    }
  }

  Future<void> _restoreSelectedJobs() async {
    if (_selectedJobIds.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Jobs?'),
        content: Text('Are you sure you want to restore ${_selectedJobIds.length} job(s)? They will return to their previous active status.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Restore', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await Future.wait(_selectedJobIds.map((id) async {
        try {
          await _api.restoreJob(id);
        } catch (e) {
          debugPrint('Failed to restore $id: $e');
        }
      }));
      if (!mounted) return;
      Navigator.pop(context); // close progress
      setState(() {
        _isEditing = false;
        _selectedJobIds.clear();
      });
      _fetchRemovedJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: _isEditing 
            ? IconButton(icon: const Icon(Icons.close, color: Color(0xFF202124)), onPressed: () => setState(() { _isEditing = false; _selectedJobIds.clear(); }))
            : const DrawerMenuButton(),
        title: Text(_isEditing ? '${_selectedJobIds.length} Selected' : 'Edit', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.select_all, color: Colors.blue),
              tooltip: 'Select All',
              onPressed: () {
                setState(() {
                  if (_selectedJobIds.length == _jobs.length) {
                    _selectedJobIds.clear();
                  } else {
                    _selectedJobIds.addAll(_jobs.map((j) => j.jobId));
                  }
                });
              },
            ),
          if (_isEditing && _selectedJobIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.restore, color: Colors.blue), tooltip: 'Restore', onPressed: _restoreSelectedJobs),
          if (_isEditing && _selectedJobIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), tooltip: 'Delete Forever', onPressed: _deleteSelectedJobs),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _fetchRemovedJobs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
              : _jobs.isEmpty
                  ? const Center(child: Text('No jobs found.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _jobs.length,
                      itemBuilder: (context, index) {
                        final job = _jobs[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: _selectedJobIds.contains(job.jobId) ? const Color(0xFFD93025) : const Color(0xFFE0E0E0), width: _selectedJobIds.contains(job.jobId) ? 2 : 1),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.only(left: _isEditing ? 0 : 16, right: 16, top: 8, bottom: 8),
                            leading: _isEditing 
                                ? Checkbox(
                                    activeColor: Colors.red,
                                    value: _selectedJobIds.contains(job.jobId),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedJobIds.add(job.jobId);
                                        } else {
                                          _selectedJobIds.remove(job.jobId);
                                        }
                                      });
                                    },
                                  )
                                : null,
                            title: Text(
                              job.partNumber ?? job.customerName ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF202124)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF5F6368)),
                                  const SizedBox(width: 4),
                                  Text('${job.quantity} units', style: const TextStyle(color: Color(0xFF5F6368))),
                                ],
                              ),
                            ),
                            onTap: _isEditing ? () {
                              setState(() {
                                if (_selectedJobIds.contains(job.jobId)) {
                                  _selectedJobIds.remove(job.jobId);
                                } else {
                                  _selectedJobIds.add(job.jobId);
                                }
                              });
                            } : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JobTimelineScreen(job: job),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
