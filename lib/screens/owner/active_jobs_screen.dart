import 'package:flutter/material.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import '../../models/supplier_model.dart';
import 'package:intl/intl.dart';
import 'job_timeline_screen.dart';
import '../../models/user_model.dart';

class ActiveJobsScreen extends StatefulWidget {
  final bool showBackButton;

  const ActiveJobsScreen({super.key, this.showBackButton = false});

  @override
  State<ActiveJobsScreen> createState() => _ActiveJobsScreenState();
}

class _ActiveJobsScreenState extends State<ActiveJobsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<JobModel> _jobs = [];
  List<SupplierModel> _suppliers = [];

  bool _isEditing = false;
  final Set<String> _selectedJobIds = {};
  bool _isAdmin = false;

  String? _selectedMonth;
  String? _selectedDate;
  String? _selectedSupplier;
  String? _selectedStatus;
  
  final TextEditingController _partNumberCtrl = TextEditingController();

  final List<String> _statusOptions = ['Created', 'Dispatched', 'At Supplier', 'In Process', 'Returned', 'Delivered', 'Closed'];

  @override
  void initState() {
    super.initState();
    _isAdmin = _api.currentUser?.role == UserRole.admin;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final suppliers = await _api.getSuppliers();
      setState(() => _suppliers = suppliers);
      await _fetchJobs();
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchJobs() async {
    setState(() {
       _isLoading = true;
       _errorMessage = null;
    });
    try {
      final jobs = await _api.getFilteredJobs(
        month: _selectedMonth,
        date: _selectedDate,
        supplier: _selectedSupplier,
        partNumber: _partNumberCtrl.text.trim().isEmpty ? null : _partNumberCtrl.text.trim(),
        status: _selectedStatus,
      );
      
      // Default to showing only "Active" jobs (not Closed/Removed) and must be at EDP if no status filter is explicitly selected
      final activeJobs = _selectedStatus == null 
          ? jobs.where((j) => j.status != 'Closed' && j.status != 'Removed' && j.status != 'Completed' && (j.currentLocation == 'EDP' || j.currentLocation.toLowerCase() == 'edp production' || j.currentLocation.isEmpty) && !(j.jobType == 'Re-coating' && (j.status == 'Created' || j.status == 'Arrived' || j.status == 'Extracted'))).toList()
          : jobs.where((j) => j.status != 'Removed' && j.status != 'Completed' && (j.currentLocation == 'EDP' || j.currentLocation.toLowerCase() == 'edp production' || j.currentLocation.isEmpty) && !(j.jobType == 'Re-coating' && (j.status == 'Created' || j.status == 'Arrived' || j.status == 'Extracted'))).toList();
          
      setState(() => _jobs = activeJobs);
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        _selectedMonth = null; // Clear month if date is selected
      });
      _fetchJobs();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedDate = null;
      _selectedSupplier = null;
      _selectedStatus = null;
      _partNumberCtrl.clear();
    });
    _fetchJobs();
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
      setState(() => _isLoading = true);
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
      _fetchJobs();
    }
  }

  Future<void> _undoJob(JobModel job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Last Action'),
        content: const Text('Are you sure you want to revert this job to its previous state?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Undo', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _api.undoJobStatus(job.jobId);
        _fetchJobs();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to undo: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: _isEditing 
            ? IconButton(icon: const Icon(Icons.close, color: Color(0xFF202124)), onPressed: () => setState(() { _isEditing = false; _selectedJobIds.clear(); }))
            : (widget.showBackButton ? const BackButton() : const DrawerMenuButton()),
        title: Text(_isEditing ? '${_selectedJobIds.length} Selected' : 'EDP Production', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAdmin && _isEditing)
            IconButton(
              icon: Icon(
                _selectedJobIds.length == _jobs.length && _jobs.isNotEmpty ? Icons.deselect : Icons.select_all,
                color: const Color(0xFF202124),
              ),
              tooltip: _selectedJobIds.length == _jobs.length && _jobs.isNotEmpty ? 'Deselect All' : 'Select All',
              onPressed: () {
                setState(() {
                  if (_selectedJobIds.length == _jobs.length && _jobs.isNotEmpty) {
                    _selectedJobIds.clear();
                  } else {
                    _selectedJobIds.addAll(_jobs.map((j) => j.jobId));
                  }
                });
              },
            ),
          if (_isAdmin && _isEditing && _selectedJobIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _removeSelectedJobs),
          if (_isAdmin && !_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _fetchJobs),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
                    : _jobs.isEmpty
                        ? const Center(child: Text('No jobs found matching filters.', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: _fetchJobs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                          final job = _jobs[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => JobTimelineScreen(job: job)),
                              ).then((_) => _fetchJobs());
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: _selectedJobIds.contains(job.jobId) ? const BorderSide(color: Color(0xFF29B6F6), width: 2) : BorderSide.none,
                              ),
                              child: Row(
                                children: [
                                  if (_isEditing)
                                    Checkbox(
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
                                                  Text(job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                              if (job.status != 'Created') ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.undo, color: Colors.blueGrey, size: 20),
                                                  onPressed: () => _undoJob(job),
                                                  tooltip: 'Undo Last Action',
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Month Filter
            DropdownButton<String>(
              hint: const Text('Month'),
              value: _selectedMonth,
              items: List.generate(12, (index) {
                final date = DateTime(DateTime.now().year, DateTime.now().month - index, 1);
                final value = DateFormat('yyyy-MM').format(date);
                final label = DateFormat('MMMM yyyy').format(date);
                return DropdownMenuItem(value: value, child: Text(label));
              }),
              onChanged: (val) {
                setState(() {
                  _selectedMonth = val;
                  _selectedDate = null;
                });
                _fetchJobs();
              },
            ),
            const SizedBox(width: 12),
            
            // Date Filter
            ActionChip(
              label: Text(_selectedDate ?? 'Select Date'),
              avatar: const Icon(Icons.calendar_today, size: 16),
              onPressed: _selectDate,
            ),
            const SizedBox(width: 12),
            
            // Supplier Filter
            DropdownButton<String>(
              hint: const Text('Supplier'),
              value: _selectedSupplier,
              items: _suppliers.map((s) => DropdownMenuItem(value: s.supplierName, child: Text(s.supplierName))).toList(),
              onChanged: (val) {
                setState(() => _selectedSupplier = val);
                _fetchJobs();
              },
            ),
            const SizedBox(width: 12),

            // Status Filter
            DropdownButton<String>(
              hint: const Text('Status'),
              value: _selectedStatus,
              items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                setState(() => _selectedStatus = val);
                _fetchJobs();
              },
            ),
            const SizedBox(width: 12),

            // Part Number Filter
            SizedBox(
              width: 150,
              child: TextField(
                controller: _partNumberCtrl,
                decoration: InputDecoration(
                  hintText: 'Part #',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, size: 16),
                    onPressed: _fetchJobs,
                  ),
                ),
                onSubmitted: (_) => _fetchJobs(),
              ),
            ),
            const SizedBox(width: 12),
            
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            )
          ],
        ),
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
