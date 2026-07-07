import 'package:flutter/material.dart';
import '../../models/supplier_model.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import 'job_timeline_screen.dart';

class SupplierDetailScreen extends StatefulWidget {
  final SupplierModel supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<JobModel> _assignedJobs = [];
  bool _isEditing = false;
  final Set<String> _selectedJobIds = {};

  @override
  void initState() {
    super.initState();
    _loadSupplierJobs();
  }

  Future<void> _loadSupplierJobs() async {
    final allJobs = await _api.getJobsForOwner();
    if (mounted) {
      setState(() {
        _assignedJobs = allJobs.where((j) {
          return j.destinationName == widget.supplier.supplierName &&
                 j.status != 'Completed' && j.status != 'Closed' && j.status != 'Delivered' && j.status != 'Returned' && j.status != 'Removed';
        }).toList();
        _loading = false;
      });
    }
  }

  Future<void> _removeSelectedJobs() async {
    if (_selectedJobIds.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Jobs?'),
        content: Text('Are you sure you want to remove ${_selectedJobIds.length} job(s)? They will be moved to Edit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await Future.wait(_selectedJobIds.map((id) async {
        try {
          await _api.updateJobStatus(id, 'Removed');
        } catch (e) {
          debugPrint('Failed to remove $id: $e');
        }
      }));
      if (!mounted) return;
      Navigator.pop(context); // close progress
      setState(() {
        _isEditing = false;
        _selectedJobIds.clear();
      });
      _loadSupplierJobs(); // Refresh from backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: _isEditing 
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isEditing = false; _selectedJobIds.clear(); }))
            : const BackButton(),
        title: Text(_isEditing ? '${_selectedJobIds.length} Selected' : widget.supplier.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          if (_isEditing && _selectedJobIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _removeSelectedJobs),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _loadSupplierJobs),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assignedJobs.isEmpty
              ? const Center(child: Text("No jobs assigned to this supplier yet.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignedJobs.length,
                  itemBuilder: (context, index) {
                    final job = _assignedJobs[index];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.only(left: _isEditing ? 0 : 16, right: 16, top: 8, bottom: 8),
                        leading: _isEditing 
                            ? Checkbox(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF5F6368)),
                                  const SizedBox(width: 4),
                                  Text('Total Order: ${job.quantity}', style: const TextStyle(color: Color(0xFF5F6368))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.assignment_turned_in, size: 14, color: Color(0xFF29B6F6)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Process: ${job.processType ?? 'N/A'}',
                                      style: const TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (job.status == 'Delivered' || job.status == 'Completed' || job.status == 'Closed') ? Icons.check_circle : Icons.pending_actions,
                              color: (job.status == 'Delivered' || job.status == 'Completed' || job.status == 'Closed') ? const Color(0xFF1E8E3E) : const Color(0xFFF9AB00),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
                          ],
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
