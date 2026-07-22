import 'package:flutter/material.dart';
import '../../models/raw_material_model.dart';
import '../../services/api_service.dart';

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  State<RawMaterialsScreen> createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<RawMaterialModel> _materials = [];

  bool _isEditing = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRawMaterials();
  }

  Future<void> _fetchRawMaterials() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _api.getRawMaterials();
      setState(() {
        _materials = materials;
      });
    } catch (e) {
      debugPrint('Error fetching raw materials: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} raw material(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      for (final id in _selectedIds) {
        await _api.deleteRawMaterial(id);
      }
      _selectedIds.clear();
      _isEditing = false;
      await _fetchRawMaterials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected raw materials deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddRawMaterialModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const _AddRawMaterialForm(),
        ),
      ),
    ).then((added) {
      if (added == true) {
        _fetchRawMaterials();
      }
    });
  }

  Widget _buildMaterialCard(RawMaterialModel material) {
    final bool isSelected = _selectedIds.contains(material.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
      ),
      elevation: 2,
      child: InkWell(
        onTap: _isEditing && material.id != null
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(material.id!);
                  } else {
                    _selectedIds.add(material.id!);
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (_isEditing && material.id != null) ...[
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(material.id!);
                                } else {
                                  _selectedIds.remove(material.id!);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            material.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Raw Material', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Qty', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${material.availableQuantity} ${material.availableUnit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Minimum Qty', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${material.minimumQuantity} ${material.minimumUnit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allSelected = _materials.isNotEmpty && _selectedIds.length == _materials.where((m) => m.id != null).length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Raw Materials', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(_materials.where((m) => m.id != null).map((m) => m.id!));
                  }
                });
              },
              child: Text(allSelected ? 'Deselect All' : 'Select All'),
            ),
            if (_selectedIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelected,
                tooltip: 'Delete Selected',
              ),
          ],
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: _isEditing ? Colors.red : Colors.grey[700]),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _selectedIds.clear();
              });
            },
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? const Center(
                  child: Text('No raw materials found.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _materials.length,
                  itemBuilder: (context, index) => _buildMaterialCard(_materials[index]),
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: _showAddRawMaterialModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF29B6F6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Add Raw Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}

class _AddRawMaterialForm extends StatefulWidget {
  const _AddRawMaterialForm();

  @override
  State<_AddRawMaterialForm> createState() => _AddRawMaterialFormState();
}

class _AddRawMaterialFormState extends State<_AddRawMaterialForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _availQtyCtrl = TextEditingController();
  final TextEditingController _minQtyCtrl = TextEditingController();

  String _availUnit = 'Kg';
  String _minUnit = 'Kg';
  bool _isSaving = false;

  final List<String> _units = ['Kg', 'Liter', 'Numbers', 'Carat'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newMaterial = RawMaterialModel(
        name: _nameCtrl.text.trim(),
        availableQuantity: double.parse(_availQtyCtrl.text.trim()),
        availableUnit: _availUnit,
        minimumQuantity: double.parse(_minQtyCtrl.text.trim()),
        minimumUnit: _minUnit,
      );

      await _api.addRawMaterial(newMaterial);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raw material added successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Raw Material', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Raw Material Name', border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _availQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Available Quantity', border: OutlineInputBorder()),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _availUnit,
                    decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _availUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _minQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minimum Quantity', border: OutlineInputBorder()),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _minUnit,
                    decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _minUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
