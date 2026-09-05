import 'package:flutter/material.dart';
import '../../models/raw_material_model.dart';
import '../../services/api_service.dart';

class RawMaterialsScreen extends StatefulWidget {
  const RawMaterialsScreen({super.key});

  @override
  State<RawMaterialsScreen> createState() => _RawMaterialsScreenState();
}

class _RawMaterialsScreenState extends State<RawMaterialsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<RawMaterialModel> _materials = [];

  bool _isEditing = false;
  final Set<String> _selectedIds = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRawMaterials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        content: Text('Are you sure you want to delete ${_selectedIds.length} item(s)?'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected items deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddRawMaterialModal() {
    final isLapping = _tabController.index == 1;
    final category = isLapping ? 'Lapping Compound' : 'Raw Material';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _AddRawMaterialForm(category: category),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              if (material.gritSize != null && material.gritSize!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Grit Size: ${material.gritSize}',
                                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                ),
                              ],
                            ],
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
                    child: Text(material.category ?? 'Raw Material', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
                        material.minimumQuantity != null ? '${material.minimumQuantity} ${material.minimumUnit}' : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUseMaterialDialog(material),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Use Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUseMaterialDialog(RawMaterialModel material) {
    if (material.id == null) return;
    
    final TextEditingController qtyCtrl = TextEditingController();
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use ${material.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (material.gritSize != null && material.gritSize!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Grit Size: ${material.gritSize}', style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'Available: ${material.availableQuantity} ${material.availableUnit}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity to use (${material.availableUnit})',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          final num = double.tryParse(val);
                          if (num == null) return 'Must be a number';
                          if (num <= 0) return 'Must be greater than 0';
                          if (num > material.availableQuantity) return 'Exceeds available quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            setDialogState(() => isSaving = true);
                            try {
                              await _api.useRawMaterial(material.id!, double.parse(qtyCtrl.text));
                              if (context.mounted) {
                                Navigator.pop(context, true);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material used successfully')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            } finally {
                              if (mounted) setDialogState(() => isSaving = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29B6F6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).then((used) {
      if (used == true) {
        _fetchRawMaterials();
      }
    });
  }

  Widget _buildList(List<RawMaterialModel> items) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('No items found.', style: TextStyle(color: Colors.grey, fontSize: 18)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildMaterialCard(items[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawMaterials = _materials.where((m) => m.category == 'Raw Material' || m.category == null).toList();
    final lappingCompounds = _materials.where((m) => m.category == 'Lapping Compound').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  final currentList = _tabController.index == 0 ? rawMaterials : lappingCompounds;
                  final allSelected = currentList.isNotEmpty && _selectedIds.length == currentList.where((m) => m.id != null).length;
                  if (allSelected) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(currentList.where((m) => m.id != null).map((m) => m.id!));
                  }
                });
              },
              child: const Text('Select All'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          onTap: (index) {
            setState(() {
              _isEditing = false;
              _selectedIds.clear();
            });
          },
          tabs: const [
            Tab(text: 'Diamond Powder'),
            Tab(text: 'Lapping Compound'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(rawMaterials),
          _buildList(lappingCompounds),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Container(
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
              child: Text(
                _tabController.index == 0 ? 'Add Diamond Powder' : 'Add Lapping Compound',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );
        }
      ),
    );
  }
}

class _AddRawMaterialForm extends StatefulWidget {
  final String category;
  const _AddRawMaterialForm({required this.category});

  @override
  State<_AddRawMaterialForm> createState() => _AddRawMaterialFormState();
}

class _AddRawMaterialFormState extends State<_AddRawMaterialForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _gritSizeCtrl = TextEditingController();
  final TextEditingController _availQtyCtrl = TextEditingController();
  final TextEditingController _minQtyCtrl = TextEditingController();

  late String _availUnit;
  late String _minUnit;
  bool _isSaving = false;
  bool _isLoadingMasterData = true;
  List<Map<String, dynamic>> _masterData = [];

  final List<String> _units = ['Kg', 'Litre', 'Numbers', 'Carat', 'Grams'];

  @override
  void initState() {
    super.initState();
    if (widget.category == 'Lapping Compound') {
      _availUnit = 'Numbers';
      _minUnit = 'Numbers';
    } else {
      _availUnit = 'Kg';
      _minUnit = 'Kg';
    }
    _fetchMasterData();
  }

  Future<void> _fetchMasterData() async {
    try {
      final data = await _api.getMasterData();
      if (mounted) setState(() => _masterData = data);
    } catch (e) {
      debugPrint('Error fetching master data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMasterData = false);
    }
  }

  List<String> _getSuggestions(String fieldKey) {
    if (widget.category == 'Lapping Compound' && fieldKey == 'Raw Material Name') {
      return ['Syringe', 'Petroleum Jelly', 'Grease'];
    }
    return _masterData
        .where((m) => m['jobType'] == 'Raw Material' && m['field'] == fieldKey)
        .map((m) => m['value'].toString())
        .toSet()
        .toList();
  }

  Widget _buildAutocomplete(TextEditingController ctrl, String label, List<String> options, {bool required = false}) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return options;
        return options.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        ctrl.text = selection;
        if (widget.category == 'Lapping Compound') {
          setState(() {
            if (selection == 'Syringe') {
              _availUnit = 'Numbers';
              _minUnit = 'Numbers';
            } else if (selection == 'Petroleum Jelly' || selection == 'Grease') {
              _availUnit = 'Grams';
              _minUnit = 'Grams';
            }
          });
        }
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.addListener(() {
          if (ctrl.text != textEditingController.text) {
             ctrl.text = textEditingController.text;
          }
        });
        if (textEditingController.text.isEmpty && ctrl.text.isNotEmpty) {
           textEditingController.text = ctrl.text;
        }
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newMaterial = RawMaterialModel(
        name: _nameCtrl.text.trim(),
        gritSize: _gritSizeCtrl.text.trim().isEmpty ? null : _gritSizeCtrl.text.trim(),
        availableQuantity: double.parse(_availQtyCtrl.text.trim()),
        availableUnit: _availUnit,
        minimumQuantity: _minQtyCtrl.text.trim().isEmpty ? null : double.tryParse(_minQtyCtrl.text.trim()),
        minimumUnit: _minUnit,
        category: widget.category,
      );

      await _api.addRawMaterial(newMaterial);
      if (mounted) {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.category} added successfully!')));
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
    final isLapping = widget.category == 'Lapping Compound';
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add ${widget.category}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _isLoadingMasterData
                ? const Center(child: CircularProgressIndicator())
                : _buildAutocomplete(_nameCtrl, 'Item Name', _getSuggestions('Raw Material Name'), required: true),
            const SizedBox(height: 16),
            if (!_isLoadingMasterData && !isLapping)
              _buildAutocomplete(_gritSizeCtrl, 'Grit Size (Optional)', _getSuggestions('Grit Size')),
            if (!isLapping) const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _availQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity to Add', border: OutlineInputBorder()),
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
                    value: _availUnit,
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
                      if (val != null && val.isNotEmpty) {
                        if (double.tryParse(val) == null) return 'Must be a number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _minUnit,
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
