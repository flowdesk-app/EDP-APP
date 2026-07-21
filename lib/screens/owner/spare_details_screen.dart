import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'spare_to_ready_for_delivery_screen.dart';
import 'spare_to_production_screen.dart';
import 'spare_to_extraction_screen.dart';
import 'spare_to_production_stage_screen.dart';
import 'spare_new_to_production_screen.dart';

class SpareDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> spare;

  const SpareDetailsScreen({super.key, required this.spare});

  @override
  State<SpareDetailsScreen> createState() => _SpareDetailsScreenState();
}

class _SpareDetailsScreenState extends State<SpareDetailsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await _api.updateSpare(widget.spare['_id'], status: status);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _sendToSupplier() async {
    setState(() => _isLoading = true);
    try {
      final suppliers = await _api.getSpareSuppliers();
      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Next Supplier'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suppliers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('Back to EDP Spare Production', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _executeSupplierUpdate('EDP');
                    },
                  );
                }
                final supplier = suppliers[index - 1];
                return ListTile(
                  title: Text(supplier.supplierName),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _executeSupplierUpdate(supplier.supplierName);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        )
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading suppliers: $e')));
      }
    }
  }

  Future<void> _executeSupplierUpdate(String targetSupplier) async {
    setState(() => _isLoading = true);
    try {
      await _api.updateSpare(widget.spare['_id'], currentSupplier: targetSupplier);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildHistoryTimeline() {
    final history = widget.spare['history'] as List<dynamic>? ?? [];
    
    if (history.isEmpty) {
      // Fallback if no history exists (older records)
      final createdDate = widget.spare['createdAt'] != null ? DateTime.parse(widget.spare['createdAt']) : null;
      final lastSentDate = widget.spare['lastSentDate'] != null ? DateTime.parse(widget.spare['lastSentDate']) : null;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Movement History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (createdDate != null)
            _buildTimelineItem('Created at EDP Spare Production', createdDate, isLast: lastSentDate == null),
          if (lastSentDate != null && widget.spare['currentSupplier'] != null && widget.spare['currentSupplier'] != 'EDP')
            _buildTimelineItem('Sent to ${widget.spare['currentSupplier']}', lastSentDate, isLast: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Movement History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(history.length, (index) {
          final entry = history[index];
          final supplier = entry['supplier'] ?? 'Unknown';
          final date = entry['date'] != null ? DateTime.parse(entry['date']) : null;
          final isLast = index == history.length - 1;
          return _buildTimelineItem(
            supplier == 'EDP Spare Production' ? 'Arrived at EDP Spare Production' : 'Sent to $supplier', 
            date, 
            isLast: isLast
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem(String title, DateTime? date, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 4)
                  ]
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.blue.withValues(alpha: 0.2),
                  ),
                )
              else
                const SizedBox(height: 24), // padding for the last item
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 4),
                  if (date != null)
                    Text(DateFormat('dd-MM-yyyy hh:mm a').format(date.toLocal()), style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(bool isFinished, bool isAtEdp) {
    if (_isLoading) return null;
    
    final status = widget.spare['status'] ?? 'Blank';

    if (isFinished) {
      if (widget.spare['jobType'] == 'New') {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
            ]
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpareToReadyForDeliveryScreen(spare: widget.spare)));
                     if (result == true && mounted) {
                       Navigator.pop(context, true);
                     }
                  },
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Move to Ready for Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]
          )
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
            ]
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpareToProductionScreen(spare: widget.spare)));
                     if (result == true && mounted) {
                       Navigator.pop(context, true);
                     }
                  },
                  icon: const Icon(Icons.precision_manufacturing),
                  label: const Text('Move to Ready for Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]
          )
        );
      }
    }

    // Not finished logic
    if (status == 'Blank') {
      if (widget.spare['jobType'] == 'New') {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
            ]
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpareNewToProductionScreen(spare: widget.spare)));
                     if (result == true && mounted) {
                       Navigator.pop(context, true);
                     }
                  },
                  icon: const Icon(Icons.build),
                  label: const Text('Move to Production', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]
          )
        );
      } else {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
            ]
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpareToExtractionScreen(spare: widget.spare)));
                     if (result == true && mounted) {
                       Navigator.pop(context, true);
                     }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Move to Extraction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ]
          )
        );
      }
    } else if (status == 'Extraction') {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                   final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpareToProductionStageScreen(spare: widget.spare)));
                   if (result == true && mounted) {
                     Navigator.pop(context, true);
                   }
                },
                icon: const Icon(Icons.build),
                label: const Text('Move to Production', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]
        )
      );
    }

    // Default for 'New' jobs, OR 'Production' stage of 'Re-coating' jobs
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _sendToSupplier,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Next Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (isAtEdp) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus('Finished'),
                icon: const Icon(Icons.check_circle),
                label: const Text('Move to Finished', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spare = widget.spare;
    final isFinished = spare['status'] == 'Finished';
    final isAtEdp = spare['currentSupplier'] == null || spare['currentSupplier'] == 'EDP';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(spare['partNumber'] ?? 'Spare Details', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'General Information',
                  icon: Icons.info_outline,
                  children: [
                    _buildDetailRow('Part Number', spare['partNumber'] ?? '-'),
                    _buildDetailRow('Quantity', '${spare['quantity'] ?? 1} units'),
                  ],
                ),
                if ((spare['description'] != null && spare['description'].toString().isNotEmpty) ||
                    (spare['gritSize'] != null && spare['gritSize'].toString().isNotEmpty) ||
                    (spare['personResponsible'] != null && spare['personResponsible'].toString().isNotEmpty))
                  _buildSectionCard(
                    title: 'Specifications & Assignment',
                    icon: Icons.build_circle_outlined,
                    children: [
                      if (spare['description'] != null && spare['description'].toString().isNotEmpty)
                        _buildDetailRow('Description', spare['description'].toString()),
                      if (spare['gritSize'] != null && spare['gritSize'].toString().isNotEmpty)
                        _buildDetailRow('Diamond Powder Grit Size', spare['gritSize'].toString()),
                      if (spare['personResponsible'] != null && spare['personResponsible'].toString().isNotEmpty)
                        _buildDetailRow('Person Responsible', spare['personResponsible'].toString()),
                    ],
                  ),
                if (spare['expectedCompletionDate'] != null || 
                    spare['extractionSentDate'] != null || 
                    spare['expectedExtractionDate'] != null || 
                    spare['extractionCompletedDate'] != null || 
                    spare['productionDate'] != null || 
                    spare['expectedProductionDate'] != null)
                  _buildSectionCard(
                    title: 'Timeline & Status',
                    icon: Icons.timeline,
                    children: [
                      if (spare['expectedCompletionDate'] != null && spare['expectedCompletionDate'].toString().isNotEmpty)
                        _buildDetailRow('Expected Completion', spare['expectedCompletionDate'].toString()),
                      if (spare['extractionSentDate'] != null)
                        _buildDetailRow('Extraction Sent', spare['extractionSentDate'].toString()),
                      if (spare['expectedExtractionDate'] != null)
                        _buildDetailRow('Expected Extraction', spare['expectedExtractionDate'].toString()),
                      if (spare['extractionCompletedDate'] != null)
                        _buildDetailRow('Extraction Completed', spare['extractionCompletedDate'].toString()),
                      if (spare['productionDate'] != null)
                        _buildDetailRow('Production Date', spare['productionDate'].toString()),
                      if (spare['expectedProductionDate'] != null)
                        _buildDetailRow('Expected Production', spare['expectedProductionDate'].toString()),
                    ],
                  ),
                const SizedBox(height: 32),
                _buildHistoryTimeline(),
              ],
            ),
          ),
      bottomNavigationBar: _buildBottomBar(isFinished, isAtEdp),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
