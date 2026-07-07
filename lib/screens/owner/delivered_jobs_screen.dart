import 'package:flutter/material.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import 'package:intl/intl.dart';
import 'job_timeline_screen.dart';

class DeliveredJobsScreen extends StatefulWidget {
  const DeliveredJobsScreen({super.key});

  @override
  State<DeliveredJobsScreen> createState() => _DeliveredJobsScreenState();
}

class _DeliveredJobsScreenState extends State<DeliveredJobsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<JobModel> _jobs = [];

  final TextEditingController _partNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
       _isLoading = true;
       _errorMessage = null;
    });
    try {
      final jobs = await _api.getFilteredJobs(
        partNumber: _partNumberCtrl.text.trim().isEmpty ? null : _partNumberCtrl.text.trim(),
      );
      
      final deliveredJobs = jobs.where((j) => j.status == 'Delivered' || j.status == 'Closed').toList();
          
      setState(() => _jobs = deliveredJobs);
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Delivered Jobs', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _fetchJobs),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _partNumberCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search Part Number...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onSubmitted: (_) => _fetchJobs(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
                    : _jobs.isEmpty
                        ? const Center(child: Text('No delivered jobs found.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
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
                                side: BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            job.status,
                                            style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Expanded(child: _buildInfo('Part Number', job.partNumber ?? 'N/A')),
                                        Expanded(child: _buildInfo('Quantity', '${job.quantity ?? 0}')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(child: _buildInfo('Date', DateFormat('dd-MMM-yyyy').format(job.createdDate))),
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
}
