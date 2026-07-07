import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class DeclinedJobsScreen extends StatefulWidget {
  const DeclinedJobsScreen({super.key});

  @override
  State<DeclinedJobsScreen> createState() => _DeclinedJobsScreenState();
}

class _DeclinedJobsScreenState extends State<DeclinedJobsScreen> {
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
      final leads = await _api.getDeclinedLeads();
      if (mounted) {
        setState(() => _leads = leads);
      }
    } catch (e) {
      debugPrint('Error loading leads: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Declined Jobs', style: TextStyle(color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF202124)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _leads.isEmpty
          ? const Center(child: Text('No declined jobs found.', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _leads.length,
              itemBuilder: (context, index) {
                final lead = _leads[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel, size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text('Declined', style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
