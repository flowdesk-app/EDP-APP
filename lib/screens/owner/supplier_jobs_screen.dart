import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../models/supplier_model.dart';
import 'job_timeline_screen.dart';

class SupplierJobsScreen extends StatelessWidget {
  final SupplierModel supplier;
  final List<JobModel> allJobs;

  const SupplierJobsScreen({
    super.key,
    required this.supplier,
    required this.allJobs,
  });

  @override
  Widget build(BuildContext context) {
    final jobs = allJobs
        .where((j) => j.status != 'Delivered' && j.destinationName == supplier.supplierName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          supplier.supplierName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: jobs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 56, color: Color(0xFF5F6368)),
                  SizedBox(height: 12),
                  Text(
                    'No active jobs with this supplier.',
                    style: TextStyle(color: Color(0xFF5F6368)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) {
                final job = jobs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobTimelineScreen(job: job),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.partNumber ?? job.customerName ?? 'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Process: ${job.processType ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5F6368),
                            ),
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