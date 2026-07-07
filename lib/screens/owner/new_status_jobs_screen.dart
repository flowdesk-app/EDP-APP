import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class NewStatusJobsScreen extends StatefulWidget {
  const NewStatusJobsScreen({super.key});

  @override
  State<NewStatusJobsScreen> createState() => _NewStatusJobsScreenState();
}

class _NewStatusJobsScreenState extends State<NewStatusJobsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<LeadModel> _leads = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final leads = await _api.getNewStatusLeads();
      if (mounted) {
        setState(() => _leads = leads);
      }
    } catch (e) {
      debugPrint('Error loading leads: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resumeWorkflow(LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _WorkflowBottomSheet(lead: lead, api: _api, onComplete: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('New Status Jobs', style: TextStyle(color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF202124)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _leads.isEmpty
          ? const Center(child: Text('No pending jobs found in New Status.', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _leads.length,
              itemBuilder: (context, index) {
                final lead = _leads[index];
                String processText = '';
                if (lead.status == 'Quotation Pending') {
                  processText = 'In Process: Quotation';
                } else if (lead.status == 'Negotiation Pending') {
                  processText = 'In Process: Negotiation';
                } else {
                  processText = 'In Process: Outcome';
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => _resumeWorkflow(lead),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lead.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(DateFormat('MMM dd, yyyy').format(lead.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(processText, style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _WorkflowBottomSheet extends StatefulWidget {
  final LeadModel lead;
  final ApiService api;
  final VoidCallback onComplete;

  const _WorkflowBottomSheet({required this.lead, required this.api, required this.onComplete});

  @override
  State<_WorkflowBottomSheet> createState() => _WorkflowBottomSheetState();
}

class _WorkflowBottomSheetState extends State<_WorkflowBottomSheet> {
  late LeadModel _lead;
  bool _isLoading = false;
  
  // Dynamic state that mimics CreateJobScreen
  bool? _quotationGiven;
  bool? _negotiationDone;
  String? _outcome;
  DateTime? _customerOrderDate;
  DateTime? _deliveryDate;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    // Pre-fill answers if they were already given
    if (_lead.quotationGiven) _quotationGiven = true;
    if (_lead.negotiationDone) _negotiationDone = true;
  }

  Future<void> _updateLeadAndClose(String newStatus, {bool? quo, bool? neg, String? out}) async {
    setState(() => _isLoading = true);
    try {
      final updatedLead = LeadModel(
        id: _lead.id,
        customerName: _lead.customerName,
        wheelSize: _lead.wheelSize,
        diamondPowderGritSize: _lead.diamondPowderGritSize,
        assignedWorker: _lead.assignedWorker,
        quotationGiven: quo ?? _lead.quotationGiven,
        negotiationDone: neg ?? _lead.negotiationDone,
        outcome: out ?? _lead.outcome,
        status: newStatus,
        createdAt: _lead.createdAt,
      );
      await widget.api.updateLead(updatedLead);
      if (mounted) {
        widget.onComplete();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated to $newStatus')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createJob() async {
    if (_deliveryDate == null || _customerOrderDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Order Date and Delivery Date are required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final generatedJobId = 'JOB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final job = JobModel(
        jobId: generatedJobId,
        jobType: 'New',
        customerName: _lead.customerName,
        wheelSize: _lead.wheelSize,
        diamondPowderGritSize: _lead.diamondPowderGritSize,
        assignedWorker: _lead.assignedWorker,
        customerOrderDate: _customerOrderDate,
        deliveryDate: _deliveryDate,
        negotiationDone: _negotiationDone ?? false,
        status: 'Created',
        currentLocation: 'EDP',
        createdDate: DateTime.now(),
        destinationType: 'Customer',
        destinationName: _lead.customerName,
      );

      await widget.api.createJob(job);

      // Update lead to converted
      final existingLead = LeadModel(
        id: _lead.id,
        customerName: _lead.customerName,
        wheelSize: _lead.wheelSize,
        diamondPowderGritSize: _lead.diamondPowderGritSize,
        assignedWorker: _lead.assignedWorker,
        quotationGiven: true,
        negotiationDone: _negotiationDone ?? false,
        outcome: 'Accepted',
        status: 'Converted',
        createdAt: _lead.createdAt,
      );
      await widget.api.updateLead(existingLead);

      if (mounted) {
        widget.onComplete();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Created Successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate, ValueChanged<DateTime> onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Customer: ${_lead.customerName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else ...[
                if (_lead.status == 'Quotation Pending' || _quotationGiven != null) ...[
                  const Divider(height: 32),
                  const Text('Is the quotation given?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _quotationGiven == true ? Colors.green.shade700 : Colors.green.shade400, 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: _quotationGiven == true ? 4 : 0,
                        ),
                        onPressed: _quotationGiven != null ? null : () => setState(() => _quotationGiven = true),
                        child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _quotationGiven == false ? Colors.red.shade700 : Colors.red.shade400, 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: _quotationGiven == false ? 4 : 0,
                        ),
                        onPressed: _quotationGiven != null ? null : () => Navigator.pop(context), // Already false in DB
                        child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                    ],
                  ),
                ],

                if (_quotationGiven == true && (_lead.status == 'Negotiation Pending' || _negotiationDone != null || _lead.status == 'Quotation Pending')) ...[
                  const Divider(height: 32),
                  const Text('Is negotiation done?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _negotiationDone == true ? Colors.green.shade700 : Colors.green.shade400, 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: _negotiationDone == true ? 4 : 0,
                        ),
                        onPressed: _negotiationDone != null ? null : () => setState(() => _negotiationDone = true),
                        child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _negotiationDone == false ? Colors.red.shade700 : Colors.red.shade400, 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: _negotiationDone == false ? 4 : 0,
                        ),
                        onPressed: _negotiationDone != null ? null : () => setState(() => _negotiationDone = false),
                        child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                    ],
                  ),
                ],

                if (_negotiationDone != null) ...[
                  const Divider(height: 32),
                  const Text('Select Outcome', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _outcome == 'Accepted' ? Colors.green.shade700 : Colors.green.shade400, 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: _outcome == 'Accepted' ? 4 : 0,
                        ),
                        onPressed: _outcome != null ? null : () => setState(() => _outcome = 'Accepted'),
                        child: const Text('Accepted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _outcome == 'Declined' ? Colors.red.shade700 : Colors.red.shade400, 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: _outcome == 'Declined' ? 4 : 0,
                        ),
                        onPressed: _outcome != null ? null : () => _updateLeadAndClose('Declined', quo: true, neg: _negotiationDone ?? false, out: 'Declined'),
                        child: const Text('Declined', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                    ],
                  ),
                ],

                if (_outcome == 'Accepted') ...[
                  const Divider(height: 32),
                  const Text('Select Customer Order Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _pickDate(context, _customerOrderDate, (d) => setState(() => _customerOrderDate = d)),
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                      child: Text(_customerOrderDate != null ? DateFormat('dd-MM-yyyy').format(_customerOrderDate!) : 'Select Date'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Delivery Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _pickDate(context, _deliveryDate, (d) => setState(() => _deliveryDate = d)),
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                      child: Text(_deliveryDate != null ? DateFormat('dd-MM-yyyy').format(_deliveryDate!) : 'Select Date'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_deliveryDate == null || _customerOrderDate == null) ? null : _createJob,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Confirm Job', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
