import 'package:flutter/material.dart';
import '../../models/supplier_model.dart';
import '../../services/api_service.dart';
import 'spare_at_edp_tabs_screen.dart';

class SpareProductionDashboardScreen extends StatefulWidget {
  const SpareProductionDashboardScreen({super.key});

  @override
  State<SpareProductionDashboardScreen> createState() => _SpareProductionDashboardScreenState();
}

class _SpareProductionDashboardScreenState extends State<SpareProductionDashboardScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  final Set<String> _selectedSupplierIds = {};
  List<SupplierModel> _suppliers = [];
  List<dynamic> _spares = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final suppliers = await ApiService().getSpareSuppliers();
      final spares = await ApiService().getSpares();
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _spares = spares;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
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
                  await ApiService().addSpareSupplier(name);
                }
                await _fetchData();
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
          await ApiService().deleteSpareSupplier(id);
        }
        setState(() {
          _isEditing = false;
          _selectedSupplierIds.clear();
        });
        await _fetchData();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
        }
      }
    }
  }

  int getEdpCount() {
    return _spares.where((s) => (s['currentSupplier'] == null || s['currentSupplier'] == 'EDP') && s['status'] == 'Production').length;
  }

  int getSupplierCount(String supplierName) {
    return _spares.where((s) => s['currentSupplier'] == supplierName && s['status'] == 'Production').length;
  }

  void _navToTabs(String? supplierName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SpareAtEdpTabsScreen(supplierName: supplierName)))
      .then((_) => _fetchData());
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
            onTap: isSelectable ? onTap : onTap,
            onLongPress: isSelectable ? null : () {},
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
                            child: Icon(icon, color: isSelected ? Colors.white : baseColor, size: 24),
                          ),
                          if (!isSelectable)
                            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                          if (isSelectable && !isSelected)
                            Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 24),
                          if (isSelectable && isSelected)
                            Icon(Icons.check_circle, color: baseColor, size: 24),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Spare Production Dashboard', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 1,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedSuppliers,
            ),
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                _selectedSupplierIds.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : MediaQuery.of(context).size.width > 800 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    'EDP Spare Production',
                    getEdpCount(),
                    Icons.precision_manufacturing,
                    const Color(0xFF9C27B0),
                    () => _navToTabs(null),
                  ),
                  ..._suppliers.where((s) => s.supplierName.toLowerCase() != 'edp' && s.supplierName.toLowerCase() != 'edp production').map((s) {
                    final isSelected = _selectedSupplierIds.contains(s.supplierId);
                    return _buildStatCard(
                      context,
                      s.supplierName,
                      getSupplierCount(s.supplierName),
                      Icons.business,
                      const Color(0xFF2196F3),
                      () {
                        if (_isEditing) {
                          setState(() {
                            if (isSelected) {
                              _selectedSupplierIds.remove(s.supplierId);
                            } else {
                              _selectedSupplierIds.add(s.supplierId);
                            }
                          });
                        } else {
                          _navToTabs(s.supplierName);
                        }
                      },
                      isSelectable: _isEditing,
                      isSelected: isSelected,
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSupplierDialog,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Supplier'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
    );
  }
}
