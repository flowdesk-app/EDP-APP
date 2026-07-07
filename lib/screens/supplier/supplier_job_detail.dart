import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';

class SupplierJobDetail extends StatefulWidget {
  final JobModel job;
  final String supplierId;

  const SupplierJobDetail({
    super.key,
    required this.job,
    required this.supplierId,
  });

  @override
  State<SupplierJobDetail> createState() => _SupplierJobDetailState();
}

class _SupplierJobDetailState extends State<SupplierJobDetail> {
  final _api = ApiService();
  bool _loading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
    await _api.updateJobStatus(
      widget.job.jobId,
      status,
      location: 'Transit',
    );
    setState(() => _loading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status updated successfully!'),
        backgroundColor: Color(0xFF29B6F6),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          job.partNumber ?? job.customerName ?? 'Job Details',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard(job),
            const SizedBox(height: 24),
            _actionButtons(job),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(JobModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _detail('Part Number', job.partNumber ?? job.customerName ?? 'N/A'),
          _detail('Destination', job.destinationName ?? ''),
          _detail('Quantity', '${job.quantity ?? 0} units'),

          _detail('Process', job.processType ?? 'N/A'),
          _detail('Vehicle', job.vehicleNumber ?? 'N/A'),
          _detail('Status', job.status),
          _detail('Dispatched', _fmt(job.createdDate)),
        ],
      ),
    );
  }

  Widget _actionButtons(JobModel job) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (job.status == 'At Supplier') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: const Text('Mark as Delivered'),
              onPressed: () => _updateStatus('Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
    
    if (job.status == 'Dispatched') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Mark as Received'),
              onPressed: () => _updateStatus('At Supplier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
