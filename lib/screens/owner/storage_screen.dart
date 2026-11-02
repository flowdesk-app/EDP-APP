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

  Future<void> _confirmDeleteCompany(CompanyStorage company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[700]),
            const SizedBox(width: 10),
            const Text('Delete Company'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${company.name}" from the database?\n\nThis will remove the company from the company storage list.',
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
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        removeCompanyFromStorage(company.name);
      });
      final success = await ApiService().deleteCompanyStorage(company.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Deleted "${company.name}" from database.' : 'Failed to delete company from server.'),
            backgroundColor: success ? Colors.green[700] : Colors.red[700],
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
                  width: 280,
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
                  const SizedBox(width: 12),
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
                    Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Delete Mode Active: Click the red trash icon on any company card to delete it from the database.',
                        style: TextStyle(color: Colors.red[900], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined, size: 16),
                      label: const Text('Delete Specific Item...'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[800],
                        side: BorderSide(color: Colors.red[300]!),
                      ),
                      onPressed: _showDeleteItemDialog,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _isDeleteMode = false),
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
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 1.5,
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
              setState(() => _isDeleteMode = !_isDeleteMode);
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isDeleteMode ? Colors.red[200]! : Colors.grey[200]!,
          width: _isDeleteMode ? 1.5 : 1.0,
        ),
      ),
      color: Colors.white,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (_isDeleteMode) {
                _confirmDeleteCompany(company);
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
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business,
                      size: 32,
                      color: _isDeleteMode ? Colors.red[400] : const Color(0xFF29B6F6),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      company.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Delete trash button (top right of each card, owner only)
          if (_isOwner)
            Positioned(
              top: 6,
              right: 6,
              child: _isDeleteMode
                ? InkWell(
                    onTap: () => _confirmDeleteCompany(company),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(76),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                    ),
                  )
                : PopupMenuButton<String>(
                    tooltip: 'Options',
                    icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey[400]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 140),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDeleteCompany(company);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text('Delete Company', style: TextStyle(color: Colors.red[700], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
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
