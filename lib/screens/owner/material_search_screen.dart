import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import 'package:intl/intl.dart';

class MaterialSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const MaterialSearchScreen({super.key, this.initialQuery});

  @override
  State<MaterialSearchScreen> createState() => _MaterialSearchScreenState();
}

class _MaterialSearchScreenState extends State<MaterialSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<JobModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await _api.searchJobs(query.trim());
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Where Is My Material?', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF202124)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter Part Number or Job ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29B6F6),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _performSearch(_searchController.text),
                  child: const Text('Search', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(child: Text('No materials found. Please enter a valid Job ID or Part Number.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final job = _searchResults[index];
                          return _buildResultCard(job);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job.customerName?.isNotEmpty == true ? job.customerName! : (job.partNumber != null ? 'Part No: ${job.partNumber}' : 'Job Card'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF29B6F6))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(job.status, style: TextStyle(color: _getStatusColor(job.status), fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Part Number', job.partNumber ?? job.customerName ?? 'N/A'),
            _buildDetailRow('Quantity', job.quantity?.toString() ?? 'N/A'),
            _buildDetailRow('Current Location', job.currentLocation, isHighlight: true),
            _buildDetailRow('Supplier', job.supplier ?? job.destinationName ?? 'None'),
            _buildDetailRow('Dispatch Date', DateFormat('dd-MMM-yyyy').format(job.createdDate)),
            _buildDetailRow('Expected Return', job.expectedReturnDate != null ? DateFormat('dd-MMM-yyyy').format(job.expectedReturnDate!) : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w500)),
          ),
          const Text(':  ', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? const Color(0xFF202124) : const Color(0xFF3C4043),
              ),
            ),
          ),
        ],
      ),
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
