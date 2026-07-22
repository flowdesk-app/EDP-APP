import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import 'package:intl/intl.dart';

class BlankOrdersScreen extends StatefulWidget {
  final List<JobModel> jobs;
  final String title;

  const BlankOrdersScreen({super.key, required this.jobs, required this.title});

  @override
  State<BlankOrdersScreen> createState() => _BlankOrdersScreenState();
}

class _BlankOrdersScreenState extends State<BlankOrdersScreen> {
  final ApiService _api = ApiService();
  late List<JobModel> _currentJobs;
  bool _isEditing = false;
  final Set<String> _selectedJobIds = {};

  @override
  void initState() {
    super.initState();
    _currentJobs = List.from(widget.jobs);
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _showJobDialog(JobModel job) {
    DateTime? blankReceivedDate;
    DateTime? productionDate;
    DateTime? expectedProductionDate;
    final TextEditingController supplierPoCtrl = TextEditingController();
    DateTime? supplierPoDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Process ${job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card')}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Blank Received Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context, blankReceivedDate, (d) => setState(() => blankReceivedDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                        child: Text(blankReceivedDate != null ? DateFormat('dd-MM-yyyy').format(blankReceivedDate!) : 'Select Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Supplier Purchase Order Number', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: supplierPoCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                    ),
                    const SizedBox(height: 16),
                    const Text('Supplier Purchase Order Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context, supplierPoDate, (d) => setState(() => supplierPoDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                        child: Text(supplierPoDate != null ? DateFormat('dd-MM-yyyy').format(supplierPoDate!) : 'Select Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Production Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context, productionDate, (d) => setState(() => productionDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                        child: Text(productionDate != null ? DateFormat('dd-MM-yyyy').format(productionDate!) : 'Select Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Expected Production Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context, expectedProductionDate, (d) => setState(() => expectedProductionDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                        child: Text(expectedProductionDate != null ? DateFormat('dd-MM-yyyy').format(expectedProductionDate!) : 'Select Date'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (blankReceivedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Blank Received Date')));
                      return;
                    }
                    if (productionDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Production Date')));
                      return;
                    }

                    // Update Job
                    try {
                      final updatedJob = job.copyWith(
                        status: 'Production',
                        currentLocation: 'EDP',
                        receivedDate: blankReceivedDate,
                        productionDate: productionDate,
                        expectedProductionDate: expectedProductionDate,
                        supplierPurchaseOrderNumber: supplierPoCtrl.text.trim().isEmpty ? null : supplierPoCtrl.text.trim(),
                        supplierPurchaseOrderDate: supplierPoDate,
                      );
                      
                      // Call update API
                      await _api.updateJob(updatedJob);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job moved to Production')));
                        Navigator.pop(context); // Go back to dashboard to refresh
                      }
                    } catch (e) {
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                       }
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _deleteSelectedJobs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Jobs?'),
        content: Text('Are you sure you want to delete ${_selectedJobIds.length} job(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      try {
        for (final id in _selectedJobIds) {
          await _api.deleteJob(id);
        }
        if (!mounted) return;
        Navigator.pop(context); // dismiss loading
        setState(() {
          _currentJobs.removeWhere((j) => _selectedJobIds.contains(j.jobId));
          _selectedJobIds.clear();
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jobs deleted successfully')));
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  void _showPoNotGivenDialog(JobModel job) {
    DateTime? poDate;
    final poNumberCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Process ${job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card')}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('PO Received Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context, poDate, (d) => setState(() => poDate = d)),
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                        child: Text(poDate != null ? DateFormat('dd-MM-yyyy').format(poDate!) : 'Select Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: poNumberCtrl,
                      decoration: const InputDecoration(labelText: 'Purchase Order Number', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (poDate == null || poNumberCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select PO Date and enter PO Number')));
                      return;
                    }

                    try {
                      final updatedJob = job.copyWith(
                        poNotGiven: false,
                        purchaseOrderReceived: true,
                        purchaseOrderDate: poDate,
                        purchaseOrderNumber: poNumberCtrl.text.trim(),
                      );
                      
                      await _api.updateJob(updatedJob);
                      
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      // Update local list
                      this.setState(() {
                        _currentJobs.removeWhere((j) => j.jobId == job.jobId);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job updated to Blank Order')));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () {
                setState(() {
                  if (_selectedJobIds.length == _currentJobs.length) {
                    _selectedJobIds.clear();
                  } else {
                    _selectedJobIds.addAll(_currentJobs.map((j) => j.jobId));
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Selected',
              onPressed: _selectedJobIds.isEmpty ? null : _deleteSelectedJobs,
            ),
          ],
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                _selectedJobIds.clear();
              });
            },
          ),
        ],
      ),
      body: _currentJobs.isEmpty 
        ? const Center(child: Text('No jobs found'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _currentJobs.length,
            itemBuilder: (context, index) {
              final job = _currentJobs[index];
              return Row(
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
                      activeColor: Colors.red,
                    ),
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          if (_isEditing) {
                            setState(() {
                              if (_selectedJobIds.contains(job.jobId)) {
                                _selectedJobIds.remove(job.jobId);
                              } else {
                                _selectedJobIds.add(job.jobId);
                              }
                            });
                            return;
                          }
                          if (widget.title == 'PO Not Given') {
                            _showPoNotGivenDialog(job);
                          } else {
                            _showJobDialog(job);
                          }
                        },
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
                                Text(job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : job.jobId), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        if (job.edpPurchaseOrderNumber != null && job.edpPurchaseOrderNumber!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('EDP PO', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(' (No: ${job.edpPurchaseOrderNumber})', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              if (job.edpPurchaseOrderDate != null)
                                Text(' - Date: ${DateFormat('dd-MM-yyyy').format(job.edpPurchaseOrderDate!)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ],
                        if (job.supplierPurchaseOrderNumber != null && job.supplierPurchaseOrderNumber!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Supplier PO', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(' (No: ${job.supplierPurchaseOrderNumber})', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              if (job.supplierPurchaseOrderDate != null)
                                Text(' - Date: ${DateFormat('dd-MM-yyyy').format(job.supplierPurchaseOrderDate!)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ],
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
                    ),
                  ),
                ),
              ),
            ],
          );
            },
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
