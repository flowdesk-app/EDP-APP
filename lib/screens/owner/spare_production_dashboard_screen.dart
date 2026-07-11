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
    return _spares.where((s) => s['currentSupplier'] == null || s['currentSupplier'] == 'EDP').length;
  }

  int getSupplierCount(String supplierName) {
    return _spares.where((s) => s['currentSupplier'] == supplierName).length;
  }

  void _navToTabs(String? supplierName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SpareAtEdpTabsScreen(supplierName: supplierName)))
      .then((_) => _fetchData());
  }

  Widget _buildStatCard(BuildContext context, String title, int count, IconData icon, Color color, VoidCallback onTap, {bool isSelectable = false, bool isSelected = false}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide(color: Colors.red, width: 2) : BorderSide.none,
      ),
      color: const Color(0xFFF1F5F9),
      child: InkWell(
        onTap: isSelectable ? onTap : onTap,
        onLongPress: isSelectable ? null : () {},
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202124),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelectable)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: Colors.red,
                ),
              ),
          ],
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
