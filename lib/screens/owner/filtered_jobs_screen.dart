import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'job_timeline_screen.dart';

class FilteredJobsScreen extends StatefulWidget {
  final String title;
  final List<JobModel> jobs;
  final bool Function(JobModel)? filter;

  const FilteredJobsScreen({
    super.key,
    required this.title,
    required this.jobs,
    this.filter,
  });

  @override
  State<FilteredJobsScreen> createState() => _FilteredJobsScreenState();
}

class _FilteredJobsScreenState extends State<FilteredJobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  late List<JobModel> _allJobs;
  List<JobModel> _filteredJobs = [];
  bool _isEditing = false;
  bool _isRefreshing = false;
  final Set<String> _selectedJobIds = {};

  @override
  void initState() {
    super.initState();
    // Exclude Removed jobs
    _allJobs = widget.jobs.where((j) => j.status != 'Removed').toList();
    _filteredJobs = _allJobs;
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = _allJobs;
      } else {
        _filteredJobs = _allJobs.where((j) {
          final partMatch = (j.partNumber?.toLowerCase().contains(query) ?? false) || 
                            (j.partDescription?.toLowerCase().contains(query) ?? false);
          final destMatch = (j.destinationName?.toLowerCase().contains(query) ?? false) ||
                            (j.customerName?.toLowerCase().contains(query) ?? false);
          return partMatch || destMatch;
        }).toList();
      }
    });
  }

  Future<void> _refreshJobs() async {
    setState(() => _isRefreshing = true);
    try {
      final allJobs = await _api.getFilteredJobs();
      List<JobModel> freshJobs = [];
      if (widget.filter != null) {
        freshJobs = allJobs.where((j) => j.status != 'Removed').where(widget.filter!).toList();
      } else if (widget.title == 'Pending Jobs') {
        freshJobs = allJobs.where((j) => j.status != 'Delivered' && j.status != 'Closed' && j.status != 'Returned' && j.status != 'Delivered' && j.status != 'Removed').toList();
      } else if (widget.title == 'Delivered Jobs') {
        freshJobs = allJobs.where((j) => (j.status == 'Delivered' || j.status == 'Closed' || j.status == 'Delivered') && j.status != 'Removed').toList();
      } else if (widget.title == 'Returned Materials') {
        freshJobs = allJobs.where((j) => j.status == 'Returned').toList();
      } else {
        freshJobs = allJobs.where((j) => j.status != 'Removed').toList();
      }

      if (mounted) {
        setState(() => _allJobs = freshJobs);
        _filterJobs(); // reapplies any active search filter
      }
    } catch (e) {
      debugPrint('Error refreshing: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
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
          _allJobs.removeWhere((j) => j.jobId == id);
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
      _filterJobs(); // Re-apply search filter
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
        title: Text(_isEditing ? '${_selectedJobIds.length} Selected' : widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          if (_isEditing && _selectedJobIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _removeSelectedJobs),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _isRefreshing ? null : _refreshJobs),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs by product or customer',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: _isRefreshing
                ? const Center(child: CircularProgressIndicator())
                : _filteredJobs.isEmpty
                    ? const Center(child: Text("No jobs found."))
                    : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = _filteredJobs[index];
                      final displayTitle = job.partNumber?.isNotEmpty == true
                          ? '${job.partNumber} - ${job.customerName ?? ""}'
                          : (job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card'));

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: _selectedJobIds.contains(job.jobId) ? const BorderSide(color: Color(0xFF29B6F6), width: 2) : const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
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
                            ).then((_) => _refreshJobs());
                          },
                          child: Row(
                            children: [
                              if (_isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Checkbox(
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
                                  ),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              if (job.logisticsName != null && job.logisticsName!.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.blue.shade200),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.local_shipping, size: 12, color: Colors.blue.shade700),
                                                      const SizedBox(width: 4),
                                                      Text(job.logisticsName!, style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(job.status).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              job.status,
                                              style: TextStyle(color: _getStatusColor(job.status), fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          Expanded(child: _buildInfo('Part Number', job.partNumber ?? 'N/A')),
                                          Expanded(child: _buildInfo('Quantity', '${job.quantity ?? 0}')),
                                          Expanded(child: _buildInfo('Available', '${(job.status == 'Delivered' || job.status == 'Closed') && job.deliveredQuantity == null ? 0 : (job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)}')),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: _buildSupplierChain(job)
                                          ),
                                          const SizedBox(width: 8),
                                          _buildInfo('Date', DateFormat('dd-MMM-yyyy').format(job.createdDate)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              if (job.poNotGiven == true)
                                                const Text('PO Not Given', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                                              else ...[
                                                const Text('PO Given', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                                if (job.purchaseOrderNumber != null && job.purchaseOrderNumber!.isNotEmpty)
                                                  Text(' (No: ${job.purchaseOrderNumber})', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                                if (job.purchaseOrderDate != null)
                                                  Text(' - Date: ${DateFormat('dd-MM-yyyy').format(job.purchaseOrderDate!)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                              ],
                                            ],
                                          ),
                                          if ((job.receivedDate != null && job.jobType == 'New') || job.productionDate != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Row(
                                                children: [
                                                  if (job.receivedDate != null && job.jobType == 'New')
                                                    Expanded(child: Text('Blank Rcvd: ${DateFormat('dd-MM-yyyy').format(job.receivedDate!)}', style: const TextStyle(fontSize: 11, color: Colors.black54))),
                                                  if (job.productionDate != null)
                                                    Expanded(child: Text('Prod Date: ${DateFormat('dd-MM-yyyy').format(job.productionDate!)}', style: const TextStyle(fontSize: 11, color: Colors.black54))),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSupplierChain(JobModel job) {
    List<InlineSpan> spans = [];
    
    // Always start with EDP
    spans.add(const TextSpan(
      text: 'EDP',
      style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.w500),
    ));
    
    List<String> chain = job.supplierChain.isNotEmpty 
        ? job.supplierChain 
        : (job.supplier != null ? [job.supplier!] : (job.destinationName?.isNotEmpty == true ? [job.destinationName!] : []));

    for (int i = 0; i < chain.length; i++) {
      spans.add(const TextSpan(
        text: ' -> ',
        style: TextStyle(color: Color(0xFF202124)),
      ));

      bool isLast = i == chain.length - 1;
      bool jobIsDelivered = job.status == 'Delivered' || job.status == 'Closed';
      bool isDeliveredSpan = chain[i].startsWith('Delivered');
      bool isReturnedSpan = chain[i].startsWith('Returned');
      
      if (isDeliveredSpan) {
        spans.add(TextSpan(
          text: chain[i],
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
        ));
      } else if (isReturnedSpan) {
        spans.add(TextSpan(
          text: chain[i],
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
        ));
      } else if (isLast && jobIsDelivered) {
        spans.add(TextSpan(
          text: 'Delivered (${chain[i]})',
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
        ));
      } else {
        Color color = (isLast && !jobIsDelivered) ? Colors.green : const Color(0xFF202124);
        spans.add(TextSpan(
          text: chain[i],
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ));
      }
    }

    if (job.status == 'Delivered' && chain.isEmpty) {
      spans.add(const TextSpan(
        text: ' -> Delivered',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Supplier Chain', style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
        const SizedBox(height: 4),
        RichText(text: TextSpan(children: spans, style: const TextStyle(fontSize: 14))),
        if (((job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)) > 0 && ((job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)) < (job.quantity ?? 0))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Available at ${job.currentLocation}: ${(job.quantity ?? 0) - (job.deliveredQuantity ?? 0) - (job.returnedQuantity ?? 0)}', 
              style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Created': return Colors.grey;
      case 'Dispatched': return Colors.blue;
      case 'At Supplier': return Colors.orange;
      case 'In Process': return Colors.deepPurple;
      case 'Returned': return Colors.purple;
      case 'Delivered': return Colors.green;
      case 'Closed': return const Color(0xFF1E8E3E);
      default: return Colors.blueGrey;
    }
  }
}
