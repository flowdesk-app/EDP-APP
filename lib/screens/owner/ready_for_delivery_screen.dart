import 'package:flutter/material.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import 'job_timeline_screen.dart';
class ReadyForDeliveryScreen extends StatefulWidget {
  const ReadyForDeliveryScreen({super.key});

  @override
  State<ReadyForDeliveryScreen> createState() => _ReadyForDeliveryScreenState();
}

class _ReadyForDeliveryScreenState extends State<ReadyForDeliveryScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _aggregatedParts = [];
  
  bool _isEditing = false;
  final Set<String> _selectedPartNumbers = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final parts = await _api.getReadyForDelivery();
      if (mounted) {
        setState(() {
          _aggregatedParts = parts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeSelectedParts() async {
    if (_selectedPartNumbers.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Jobs?'),
        content: Text('Are you sure you want to remove all delivered jobs for ${_selectedPartNumbers.length} part number(s)?'),
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
      try {
        await _api.removeAggregatedParts(_selectedPartNumbers.toList());
        setState(() {
          _isEditing = false;
          _selectedPartNumbers.clear();
        });
        await _fetchData();
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeliverDialog(Map<String, dynamic> partData) async {
    final ctrl = TextEditingController();
    final available = partData['totalQuantity'] as int;
    final partNum = partData['partNumber'] as String;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deliver $partNum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Quantity: $available'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Deliver',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0 && val <= available) {
                Navigator.pop(ctx, val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), foregroundColor: Colors.white),
            child: const Text('Deliver'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await _api.deliverPartial(partNum, result);
        await _fetchData();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showJobHistoryDialog(Map<String, dynamic> partData) {
    final partNum = partData['partNumber'] as String;
    final jobs = List<Map<String, dynamic>>.from(partData['jobs'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('History: Part #$partNum', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: jobs.isEmpty
                      ? const Center(child: Text('No job history available (older jobs may not have this tracking)', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          controller: controller,
                          itemCount: jobs.length,
                          itemBuilder: (ctx, i) {
                            final job = jobs[i];
                            final dateStr = job['date'] as String?;
                            String displayDate = 'Unknown Date';
                            if (dateStr != null) {
                               try {
                                 final date = DateTime.parse(dateStr);
                                 displayDate = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
                               } catch (_) {}
                            }

                            return ListTile(
                              onTap: () {
                                if (job['job'] != null) {
                                  Navigator.pop(ctx);
                                  final jobModel = JobModel.fromJson(job['job']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => JobTimelineScreen(job: jobModel)),
                                  ).then((_) => _fetchData());
                                }
                              },
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE1F5FE),
                                child: Icon(Icons.assignment, color: Color(0xFF29B6F6)),
                              ),
                              title: Text(job['jobId']?.toString() ?? 'Unknown Job', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Added on: $displayDate'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+${job['availableQuantity']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('of ${job['originalQuantity']} orig.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: _isEditing 
            ? IconButton(icon: const Icon(Icons.close, color: Color(0xFF202124)), onPressed: () => setState(() { _isEditing = false; _selectedPartNumbers.clear(); }))
            : const DrawerMenuButton(),
        title: Text(_isEditing ? '${_selectedPartNumbers.length} Selected' : 'Ready for Delivery', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing && _selectedPartNumbers.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _removeSelectedParts),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _aggregatedParts.isEmpty
                  ? const Center(child: Text('No available stocks', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _aggregatedParts.length,
                      itemBuilder: (ctx, i) {
                        final part = _aggregatedParts[i];
                        final partNum = part['partNumber'] as String;
                        final totalQty = part['totalQuantity'] as int;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _selectedPartNumbers.contains(partNum) ? const BorderSide(color: Color(0xFF29B6F6), width: 2) : BorderSide.none,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isEditing ? null : () => _showJobHistoryDialog(part),
                            child: Row(
                              children: [
                                if (_isEditing)
                                  Checkbox(
                                    value: _selectedPartNumbers.contains(partNum),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedPartNumbers.add(partNum);
                                        } else {
                                          _selectedPartNumbers.remove(partNum);
                                        }
                                      });
                                    },
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Part #$partNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$totalQty Available',
                                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!_isEditing)
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // Prevent the InkWell tap from also firing when tapping the button
                                              _showDeliverDialog(part);
                                            },
                                            icon: const Icon(Icons.local_shipping, size: 18),
                                            label: const Text('Deliver'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF29B6F6),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
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
    );
  }
}
