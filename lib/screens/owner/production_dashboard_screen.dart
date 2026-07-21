import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../models/supplier_model.dart';
import '../../services/api_service.dart';
import 'filtered_jobs_screen.dart';
import 'active_jobs_screen.dart';

class ProductionDashboardScreen extends StatefulWidget {
  final List<JobModel> productionJobs;
  final String? month;
  final String? date;

  const ProductionDashboardScreen({
    super.key, 
    required this.productionJobs,
    this.month,
    this.date,
  });

  @override
  State<ProductionDashboardScreen> createState() => _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState extends State<ProductionDashboardScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  final Set<String> _selectedSupplierIds = {};
  List<SupplierModel> _suppliers = [];

  List<JobModel> _currentJobs = [];

  @override
  void initState() {
    super.initState();
    _currentJobs = widget.productionJobs;
    _fetchSuppliers();
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await ApiService().getFilteredJobs(month: widget.month, date: widget.date);
      if (mounted) {
        setState(() {
          _currentJobs = jobs.where((j) => j.status != 'Removed' && j.status != 'Closed' && j.status != 'Delivered' && j.status != 'Returned' && j.status != 'Completed' && j.jobType != 'New' && !(j.jobType == 'Re-coating' && (j.status == 'Created' || j.status == 'Arrived' || j.status == 'Extracted'))).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final suppliers = await ApiService().getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading suppliers: $e')));
      }
    }
  }

  void _navToFiltered(BuildContext context, String title, List<JobModel> jobs, {bool Function(JobModel)? filter}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredJobsScreen(title: title, jobs: jobs, filter: filter, month: widget.month, date: widget.date)))
        .then((_) => _fetchJobs());
  }

  Future<void> _showAddSupplierDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplier'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              
              try {
                if (!_suppliers.any((s) => s.supplierName.toLowerCase() == name.toLowerCase())) {
                  await ApiService().addSupplier(name);
                }
                await _fetchSuppliers();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add supplier: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedSuppliers() async {
    if (_selectedSupplierIds.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Suppliers?'),
        content: Text('Are you sure you want to remove ${_selectedSupplierIds.length} supplier(s)?'),
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
        for (final id in _selectedSupplierIds) {
          await ApiService().deleteSupplier(id);
        }
        setState(() {
          _isEditing = false;
          _selectedSupplierIds.clear();
        });
        await _fetchSuppliers();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
        }
      }
    }
  }

  Widget _buildStatCard(BuildContext context, String title, int count, IconData icon, Color baseColor, VoidCallback onTap, {bool isSelectable = false, bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? baseColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: isSelected ? baseColor : Colors.black.withValues(alpha: 0.05), width: isSelected ? 2 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                if (!isSelected)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: baseColor,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 20.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? baseColor : baseColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isSelected ? Icons.check_circle : icon, color: isSelected ? Colors.white : baseColor, size: 24),
                          ),
                          if (!isSelectable)
                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                          if (isSelectable && !isSelected)
                            Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 24),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$count',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    double childAspectRatio = 1.15;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 2.0;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 1.5;
    }

    final edpJobs = _currentJobs.where((j) => j.currentLocation == 'EDP' || j.currentLocation.toLowerCase() == 'edp production' || j.currentLocation.isEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Production Dashboard', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        leading: _isEditing 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isEditing = false;
                  _selectedSupplierIds.clear();
                }),
              )
            : null,
        actions: _isEditing 
            ? [
                if (_selectedSupplierIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelectedSuppliers,
                  ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchSuppliers,
                ),
              ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatCard(context, 'EDP Production', edpJobs.length, Icons.precision_manufacturing, Colors.purple, () {
                          if (_isEditing) return;
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveJobsScreen(showBackButton: true)))
                              .then((_) => _fetchJobs());
                        }),
                  
                  for (final supplier in _suppliers.where((s) => s.supplierName.toLowerCase() != 'edp' && s.supplierName.toLowerCase() != 'edp production')) ...[
                    Builder(builder: (context) {
                      final supplierJobs = _currentJobs.where((j) => j.currentLocation == supplier.supplierName).toList();
                      final isSelected = _selectedSupplierIds.contains(supplier.supplierId);
                      return _buildStatCard(
                        context, 
                        supplier.supplierName, 
                        supplierJobs.length, 
                        Icons.business, 
                        Colors.blue, 
                        () {
                          if (_isEditing) {
                            setState(() {
                              if (isSelected) {
                                _selectedSupplierIds.remove(supplier.supplierId);
                              } else {
                                _selectedSupplierIds.add(supplier.supplierId);
                              }
                            });
                          } else {
                            _navToFiltered(context, supplier.supplierName, supplierJobs, filter: (j) => j.currentLocation == supplier.supplierName);
                          }
                        },
                        isSelectable: _isEditing,
                        isSelected: isSelected,
                      );
                    }),
                  ]
                ],
              ),
            ),
      floatingActionButton: _isEditing 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _showAddSupplierDialog,
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_business),
              label: const Text('Add Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }
}
