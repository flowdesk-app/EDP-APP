import 'package:flutter/material.dart';
import '../../models/company_storage.dart';
import '../../models/item_database_model.dart';
import '../../models/user_model.dart';
import 'company_items_screen.dart';
import '../../services/api_service.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  String _searchQuery = '';
  bool _isDeleteMode = false;
  bool _isLoading = false;
  final Set<String> _selectedCompanyNames = {};

  bool get _isOwner => ApiService().currentUser?.role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    _loadDynamicCompanies();
  }

  Future<void> _loadDynamicCompanies() async {
    setState(() => _isLoading = true);
    await ApiService().fetchAndMergeDynamicCompanies();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _confirmDeleteSelectedCompanies() async {
    if (_selectedCompanyNames.isEmpty) return;

    final selectedCompanies = kCompanyStorages
        .where((c) => _selectedCompanyNames.contains(c.name))
        .toList();

    final count = selectedCompanies.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[700]),
            const SizedBox(width: 10),
            const Text('Confirm Delete Companies'),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete $count selected compan${count == 1 ? 'y' : 'ies'} from the database?\n\nThis will remove the selected company storage records.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedCompanies.length,
                  separatorBuilder: (context, index) => const Divider(height: 10),
                  itemBuilder: (_, idx) {
                    final comp = selectedCompanies[idx];
                    return Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            comp.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm Delete ($count)'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      int deletedCount = 0;
      for (final comp in selectedCompanies) {
        removeCompanyFromStorage(comp.name);
        final success = await ApiService().deleteCompanyStorage(comp.name);
        if (success) deletedCount++;
      }
      if (mounted) {
        setState(() {
          _selectedCompanyNames.clear();
          _isDeleteMode = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $deletedCount of $count compan${count == 1 ? 'y' : 'ies'} from database.'),
            backgroundColor: deletedCount > 0 ? Colors.green[700] : Colors.red[700],
          ),
        );
      }
    }
  }

  void _showDeleteItemDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _DeleteItemFromDatabaseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCompanies = kCompanyStorages
        .where((company) => company.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Database',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Browse and manage items assigned to specific companies.',
                        style: TextStyle(color: Color(0xFF757575)),
                      ),
                    ],
                  ),
                ),
                // Search Field
                SizedBox(
                  width: 260,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search companies...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (_isOwner) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddCompanyDialog,
                    icon: const Icon(Icons.add_business, size: 18),
                    label: const Text('Add Company', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete Option at the top (Owner only)
                  _buildTopDeleteOption(),
                ],
              ],
            ),

            // Active Delete Mode banner (Owner only)
            if (_isOwner && _isDeleteMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_box_outlined, color: Colors.red[700], size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Select companies to delete (${_selectedCompanyNames.length} selected)',
                      style: TextStyle(color: Colors.red[900], fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedCompanyNames.length == filteredCompanies.length && filteredCompanies.isNotEmpty) {
                            _selectedCompanyNames.clear();
                          } else {
                            _selectedCompanyNames.addAll(filteredCompanies.map((c) => c.name));
                          }
                        });
                      },
                      child: Text(
                        _selectedCompanyNames.length == filteredCompanies.length && filteredCompanies.isNotEmpty
                            ? 'Deselect All'
                            : 'Select All',
                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: Text('Delete Selected (${_selectedCompanyNames.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _selectedCompanyNames.isEmpty ? null : _confirmDeleteSelectedCompanies,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = false;
                          _selectedCompanyNames.clear();
                        });
                      },
                      child: const Text('Exit Delete Mode'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Grid of Company Cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredCompanies.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? 'No companies in database.' : 'No companies matching "$_searchQuery"',
                            style: TextStyle(color: Colors.grey[600], fontSize: 15),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            childAspectRatio: 1.35,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredCompanies.length,
                          itemBuilder: (context, index) {
                            final company = filteredCompanies[index];
                            return _buildCompanyCard(company);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDeleteOption() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete Mode toggle button
        OutlinedButton.icon(
          icon: Icon(
            _isDeleteMode ? Icons.check_circle : Icons.delete_outline,
            size: 18,
            color: _isDeleteMode ? Colors.white : Colors.red[700],
          ),
          label: Text(
            _isDeleteMode ? 'Done' : 'Delete Option',
            style: TextStyle(
              color: _isDeleteMode ? Colors.white : Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: _isDeleteMode ? Colors.red[700] : Colors.red[50],
            side: BorderSide(color: _isDeleteMode ? Colors.red[800]! : Colors.red[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            setState(() {
              _isDeleteMode = !_isDeleteMode;
              if (!_isDeleteMode) _selectedCompanyNames.clear();
            });
          },
        ),
        const SizedBox(width: 8),
        // Dropdown menu for additional delete actions
        PopupMenuButton<String>(
          tooltip: 'Delete options',
          icon: Icon(Icons.more_vert, color: Colors.grey[700]),
          onSelected: (val) {
            if (val == 'toggle_mode') {
              setState(() {
                _isDeleteMode = !_isDeleteMode;
                if (!_isDeleteMode) _selectedCompanyNames.clear();
              });
            } else if (val == 'delete_item') {
              _showDeleteItemDialog();
            } else if (val == 'refresh') {
              _loadDynamicCompanies();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_mode',
              child: Row(
                children: [
                  Icon(_isDeleteMode ? Icons.check : Icons.delete_sweep_outlined, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Text(_isDeleteMode ? 'Exit Delete Mode' : 'Toggle Delete Mode'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_item',
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text('Delete an Item from Database...'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Reload Companies'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyCard(CompanyStorage company) {
    final isSelected = _selectedCompanyNames.contains(company.name);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.red[600]!
              : (_isDeleteMode ? Colors.red[200]! : Colors.grey[200]!),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      color: isSelected ? Colors.red[50]?.withAlpha(140) : Colors.white,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (_isDeleteMode) {
                setState(() {
                  if (isSelected) {
                    _selectedCompanyNames.remove(company.name);
                  } else {
                    _selectedCompanyNames.add(company.name);
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyItemsScreen(company: company),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            hoverColor: _isDeleteMode ? Colors.red[50] : Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF29B6F6).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.business,
                          size: 24,
                          color: _isDeleteMode ? Colors.red[400] : const Color(0xFF0288D1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (company.gstin.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blueGrey[100]!),
                                ),
                                child: Text(
                                  'GSTIN: ${company.gstin}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blueGrey[800], letterSpacing: 0.3),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 28), // Reserve space for top-right menu
                    ],
                  ),
                  const Spacer(),
                  if (company.billingAddress.isNotEmpty) ...[
                    Text(
                      company.billingAddress.replaceAll('\n', ', '),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      if (company.placeOfSupply.isNotEmpty) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              company.placeOfSupply,
                              style: TextStyle(fontSize: 10, color: Colors.indigo[800], fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (company.vendorCode.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'VC: ${company.vendorCode}',
                            style: TextStyle(fontSize: 10, color: Colors.amber[900], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                      const Spacer(),
                      InkWell(
                        onTap: () => _showCompanyDetailsDialog(company),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Top right action
          Positioned(
            top: 6,
            right: 6,
            child: _isDeleteMode
              ? InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCompanyNames.remove(company.name);
                      } else {
                        _selectedCompanyNames.add(company.name);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 22,
                      color: isSelected ? Colors.red[700] : Colors.grey[400],
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'View & Edit Details',
                  icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey[500]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showCompanyDetailsDialog(company),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompanyDetailsDialog(CompanyStorage company) async {
    final nameCtrl = TextEditingController(text: company.name);
    final gstinCtrl = TextEditingController(text: company.gstin);
    final vendorCodeCtrl = TextEditingController(text: company.vendorCode);
    final posCtrl = TextEditingController(text: company.placeOfSupply);
    final stateCtrl = TextEditingController(text: company.state);
    final pinCtrl = TextEditingController(text: company.pincode);
    final billingCtrl = TextEditingController(text: company.billingAddress);
    final shippingCtrl = TextEditingController(text: company.shippingAddress);
    final prefixCtrl = TextEditingController(text: company.prefixes.join(', '));
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_note, color: Color(0xFF0288D1), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Edit Company Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Update GST, addresses, and identifiers for automatic invoicing.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDialogTextField('Company Official Name *', nameCtrl, hint: 'e.g. Excel Diamond Tools'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogTextField('GSTIN / Tax ID', gstinCtrl, hint: 'e.g. 33AEZPL6819D1Z5', textCapitalization: TextCapitalization.characters),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogTextField('Vendor Code', vendorCodeCtrl, hint: 'e.g. 100362'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDialogTextField('Place of Supply', posCtrl, hint: 'e.g. Tamil Nadu (33)'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogTextField('Pincode', pinCtrl, hint: 'e.g. 641001'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField('Prefixes (comma separated)', prefixCtrl, hint: 'e.g. EDT, EXCEL'),
                    const SizedBox(height: 12),
                    _buildDialogTextField('Billing Address', billingCtrl, hint: 'Full street address, city, state, pin', maxLines: 3),
                    const SizedBox(height: 12),
                    _buildDialogTextField('Shipping Address (leave empty if same)', shippingCtrl, hint: 'Consignee / delivery address if different', maxLines: 2),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save, size: 18),
                          label: Text(isSaving ? 'Saving...' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isSaving ? null : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            final newName = nameCtrl.text.trim();
                            if (newName.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Company name cannot be empty.'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            setDialogState(() => isSaving = true);
                            final prefixesList = prefixCtrl.text
                                .split(',')
                                .map((s) => s.trim().toUpperCase())
                                .where((s) => s.isNotEmpty)
                                .toList();
                            if (prefixesList.isEmpty) {
                              prefixesList.add(newName.split(' ')[0].toUpperCase());
                            }
                            final updated = company.copyWith(
                              name: newName,
                              prefixes: prefixesList,
                              gstin: gstinCtrl.text.trim().toUpperCase(),
                              vendorCode: vendorCodeCtrl.text.trim(),
                              placeOfSupply: posCtrl.text.trim(),
                              state: stateCtrl.text.trim().isNotEmpty
                                  ? stateCtrl.text.trim()
                                  : (posCtrl.text.contains('(') ? posCtrl.text.split('(')[0].trim() : posCtrl.text.trim()),
                              pincode: pinCtrl.text.trim(),
                              billingAddress: billingCtrl.text.trim(),
                              shippingAddress: shippingCtrl.text.trim(),
                            );
                            final ok = await ApiService().updateCompanyStorage(updated, oldName: company.name);
                            if (mounted) {
                              nav.pop();
                              setState(() {});
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ok ? 'Successfully updated "${updated.name}".' : 'Saved locally; server update failed.'),
                                  backgroundColor: ok ? Colors.green[700] : Colors.orange[700],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddCompanyDialog() async {
    final nameCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final vendorCodeCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final billingCtrl = TextEditingController();
    final shippingCtrl = TextEditingController();
    final prefixCtrl = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_business, color: Colors.green, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Add New Company', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Register a new company with full address and tax details.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDialogTextField('Company Official Name *', nameCtrl, hint: 'e.g. New Engineering Works Ltd'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogTextField('GSTIN / Tax ID', gstinCtrl, hint: 'e.g. 33AAAAA0000A1Z5', textCapitalization: TextCapitalization.characters),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogTextField('Vendor Code', vendorCodeCtrl, hint: 'e.g. 100999'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDialogTextField('Place of Supply', posCtrl, hint: 'e.g. Tamil Nadu (33)'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogTextField('Pincode', pinCtrl, hint: 'e.g. 600001'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDialogTextField('Prefix (e.g. NEW, ENG)', prefixCtrl, hint: 'Identifier prefix for item barcodes / IDs'),
                    const SizedBox(height: 12),
                    _buildDialogTextField('Billing Address', billingCtrl, hint: 'Street, area, city, state, pin', maxLines: 3),
                    const SizedBox(height: 12),
                    _buildDialogTextField('Shipping Address (optional)', shippingCtrl, hint: 'Consignee / delivery address if different', maxLines: 2),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check, size: 18),
                          label: Text(isSaving ? 'Creating...' : 'Create Company'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isSaving ? null : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Company name is required.'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            setDialogState(() => isSaving = true);
                            final pref = prefixCtrl.text.trim().isNotEmpty
                                ? prefixCtrl.text.trim().toUpperCase()
                                : name.split(' ')[0].toUpperCase();
                            final pList = prefixCtrl.text
                                .split(',')
                                .map((s) => s.trim().toUpperCase())
                                .where((s) => s.isNotEmpty)
                                .toList();
                            if (pList.isEmpty) pList.add(pref);

                            await ApiService().createCompanyStorage(
                              name,
                              pref,
                              prefixes: pList,
                              gstin: gstinCtrl.text.trim().toUpperCase(),
                              vendorCode: vendorCodeCtrl.text.trim(),
                              placeOfSupply: posCtrl.text.trim(),
                              pincode: pinCtrl.text.trim(),
                              billingAddress: billingCtrl.text.trim(),
                              shippingAddress: shippingCtrl.text.trim(),
                            );
                            if (mounted) {
                              nav.pop();
                              setState(() {});
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Company "$name" created successfully.'),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}

// Dialog to search and delete any item from the database
class _DeleteItemFromDatabaseDialog extends StatefulWidget {
  const _DeleteItemFromDatabaseDialog();

  @override
  State<_DeleteItemFromDatabaseDialog> createState() => _DeleteItemFromDatabaseDialogState();
}

class _DeleteItemFromDatabaseDialogState extends State<_DeleteItemFromDatabaseDialog> {
  final TextEditingController _queryCtrl = TextEditingController();
  List<ItemDatabaseModel> _results = [];
  bool _searching = false;
  String _statusMsg = '';

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _statusMsg = '';
    });
    try {
      final items = await ApiService().getDatabaseItems(q);
      if (mounted) {
        setState(() {
          _results = items;
          _searching = false;
          if (items.isEmpty) {
            _statusMsg = 'No items found matching "$q".';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _statusMsg = 'Error searching items: $e';
        });
      }
    }
  }

  Future<void> _deleteItem(ItemDatabaseModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item from Database'),
        content: Text('Are you sure you want to delete "${item.itemName}" (${item.itemId}) permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final identifier = item.itemId.isNotEmpty ? item.itemId : item.itemName;
      final success = await ApiService().deleteDatabaseItem(identifier);
      if (mounted) {
        if (success) {
          setState(() {
            _results.removeWhere((i) => i.itemId == item.itemId && i.itemName == item.itemName);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${item.itemName}" from database.'),
              backgroundColor: Colors.green[700],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete item from database.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red[700], size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Delete Item from Database',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Search by Item Name, ID, or Description to permanently remove an item from the database.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. RBL-Model1, Gangsaw, 713621...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _search,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_searching)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_statusMsg.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(_statusMsg, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ),
              )
            else if (_results.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Search for items above to delete them.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        item.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        'ID: ${item.itemId}${item.sku != null && item.sku!.isNotEmpty ? ' | SKU: ${item.sku}' : ''}${item.description != null && item.description!.isNotEmpty ? ' | ${item.description!.replaceAll('\n', ' ')}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Delete item',
                        onPressed: () => _deleteItem(item),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
