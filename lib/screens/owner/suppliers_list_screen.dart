import 'package:flutter/material.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../models/supplier_model.dart';

import '../../services/api_service.dart';
import 'supplier_detail_screen.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<SupplierModel> _suppliers = [];
  Map<String, int> _pendingJobCounts = {};
  bool _isEditing = false;
  final Set<String> _selectedSupplierIds = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final suppliers = await _api.getSuppliers();
      final allJobs = await _api.getJobsForOwner();

      Map<String, int> counts = {};
      for (var s in suppliers) {
        counts[s.supplierName] = 0;
      }

      for (var job in allJobs) {
        if (job.status != 'Delivered' && job.status != 'Closed' && job.status != 'Returned' && job.status != 'Removed' && job.status != 'Completed') {
          if (job.destinationName != null && counts.containsKey(job.destinationName)) {
            counts[job.destinationName!] = counts[job.destinationName]! + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _pendingJobCounts = counts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showAddSupplierDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplier'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter Supplier Name', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && ctrl.text.trim().isNotEmpty) {
      setState(() => _loading = true);
      await _api.addSupplier(ctrl.text.trim());
      await _fetchData();
    }
  }

  Future<void> _removeSelectedSuppliers() async {
    if (_selectedSupplierIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Suppliers?'),
        content: Text('Are you sure you want to permanently delete ${_selectedSupplierIds.length} supplier(s)? This action cannot be undone.'),
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
      setState(() => _loading = true);
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await Future.wait(_selectedSupplierIds.map((id) async {
        try {
          await _api.deleteSupplier(id);
        } catch (e) {
          debugPrint('Failed to delete $id: $e');
        }
      }));
      if (!mounted) return;
      Navigator.pop(context); // close progress
      setState(() {
        _isEditing = false;
        _selectedSupplierIds.clear();
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: _isEditing
            ? IconButton(icon: const Icon(Icons.close, color: Color(0xFF202124)), onPressed: () => setState(() { _isEditing = false; _selectedSupplierIds.clear(); }))
            : const DrawerMenuButton(),
        title: Text(_isEditing ? '${_selectedSupplierIds.length} Selected' : 'Supplier Management', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          if (_isEditing && _selectedSupplierIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _removeSelectedSuppliers),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {
              setState(() => _loading = true);
              _fetchData();
            })
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? const Center(child: Text('No suppliers found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suppliers.length,
                  itemBuilder: (ctx, i) {
                    final s = _suppliers[i];
                    final pending = _pendingJobCounts[s.supplierName] ?? 0;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: s)),
                        ).then((_) => _fetchData());
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: _selectedSupplierIds.contains(s.supplierId) ? const BorderSide(color: Color(0xFF29B6F6), width: 2) : BorderSide.none,
                        ),
                        child: Row(
                          children: [
                            if (_isEditing)
                              Checkbox(
                                value: _selectedSupplierIds.contains(s.supplierId),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedSupplierIds.add(s.supplierId);
                                    } else {
                                      _selectedSupplierIds.remove(s.supplierId);
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
                                      children: [
                                        const CircleAvatar(backgroundColor: Color(0xFFE8F0FE), child: Icon(Icons.factory, color: Color(0xFF29B6F6))),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(s.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                                          const SizedBox(width: 8),
                                          Text('$pending Pending Jobs', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showAddSupplierDialog,
        backgroundColor: const Color(0xFF29B6F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

