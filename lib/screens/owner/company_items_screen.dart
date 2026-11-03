import 'package:flutter/material.dart';
import '../../models/item_database_model.dart';
import '../../models/user_model.dart';
import '../../utils/company_utils.dart';

import '../../services/api_service.dart';

import '../../models/company_storage.dart';

class CompanyItemsScreen extends StatefulWidget {
  final CompanyStorage company;
  const CompanyItemsScreen({super.key, required this.company});

  @override
  State<CompanyItemsScreen> createState() => _CompanyItemsScreenState();
}

class _CompanyItemsScreenState extends State<CompanyItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _descSearchController = TextEditingController();
  List<ItemDatabaseModel> _allItems = [];
  List<ItemDatabaseModel> _items = [];
  final Set<String> _selectedItemIds = {};
  bool _isLoading = true;
  bool _isDeleteMode = false;

  bool get _isOwner => ApiService().currentUser?.role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _confirmDeleteSelectedItems() async {
    if (_selectedItemIds.isEmpty) return;

    final selectedItems = _items
        .where((i) => _selectedItemIds.contains(i.itemId.isNotEmpty ? i.itemId : i.itemName))
        .toList();

    final count = selectedItems.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Confirm Delete Items'),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete $count selected item${count == 1 ? '' : 's'} from the database?\n\nThis action cannot be undone.',
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
                  itemCount: selectedItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 10),
                  itemBuilder: (_, idx) {
                    final item = selectedItems[idx];
                    return Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.itemName} (${item.itemId.isNotEmpty ? item.itemId : 'No ID'})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
      for (final item in selectedItems) {
        final identifier = item.itemId.isNotEmpty ? item.itemId : item.itemName;
        final ok = await ApiService().deleteDatabaseItem(identifier);
        if (ok) deletedCount++;
      }
      if (mounted) {
        setState(() {
          _allItems.removeWhere((i) => _selectedItemIds.contains(i.itemId.isNotEmpty ? i.itemId : i.itemName));
          _items.removeWhere((i) => _selectedItemIds.contains(i.itemId.isNotEmpty ? i.itemId : i.itemName));
          _selectedItemIds.clear();
          _isDeleteMode = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $deletedCount of $count item${count == 1 ? '' : 's'}.'),
            backgroundColor: deletedCount > 0 ? Colors.green[700] : Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService().getDatabaseItems('');
      final unassignedItems = items.where((i) => getCompaniesForPrefix(i.itemName).contains(widget.company.name)).toList();
      
      if (mounted) {
        setState(() {
          _allItems = unassignedItems;
          _items = List.from(_allItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }
  }

  void _filterItems() {
    final query = _searchController.text.trim();
    final descQuery = _descSearchController.text.trim();

    setState(() {
      _items = _allItems.where((item) {
        bool matchesItem = true;
        if (query.isNotEmpty) {
          matchesItem = smartMatch(item.itemName, query) ||
              smartMatch(item.sku, query) ||
              smartMatch(item.itemId, query) ||
              smartMatch(item.description, query);
        }

        bool matchesDesc = true;
        if (descQuery.isNotEmpty) {
          matchesDesc = smartMatch(item.description, descQuery);
        }

        return matchesItem && matchesDesc;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.company.name), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.company.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse items in this company storage.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Container(
                      width: 230,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _filterItems(),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterItems();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    Container(
                      width: 230,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _descSearchController,
                        onChanged: (_) => _filterItems(),
                        decoration: InputDecoration(
                          hintText: 'Search by description...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: Icon(Icons.description_outlined, size: 18, color: Colors.grey[400]),
                          suffixIcon: _descSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _descSearchController.clear();
                                    _filterItems();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    if (_isOwner)
                      OutlinedButton.icon(
                        icon: Icon(
                          _isDeleteMode ? Icons.close : Icons.delete_outline,
                          size: 16,
                          color: _isDeleteMode ? Colors.white : Colors.red[700],
                        ),
                        label: Text(
                          _isDeleteMode ? 'Exit Delete Mode' : 'Delete Option',
                          style: TextStyle(
                            color: _isDeleteMode ? Colors.white : Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isDeleteMode ? Colors.red[700] : Colors.red[50],
                          side: BorderSide(color: _isDeleteMode ? Colors.red[800]! : Colors.red[300]!),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() {
                            _isDeleteMode = !_isDeleteMode;
                            if (!_isDeleteMode) _selectedItemIds.clear();
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (widget.company.gstin.isNotEmpty || widget.company.billingAddress.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF0288D1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.company.billingAddress.isNotEmpty)
                            Text(
                              widget.company.billingAddress,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (widget.company.gstin.isNotEmpty)
                                Text('GSTIN: ${widget.company.gstin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              if (widget.company.placeOfSupply.isNotEmpty)
                                Text('Place of Supply: ${widget.company.placeOfSupply}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              if (widget.company.vendorCode.isNotEmpty)
                                Text('Vendor Code: ${widget.company.vendorCode}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isOwner && _isDeleteMode) ...[
              const SizedBox(height: 14),
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
                      'Select items to delete (${_selectedItemIds.length} selected)',
                      style: TextStyle(color: Colors.red[900], fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedItemIds.length == _items.length && _items.isNotEmpty) {
                            _selectedItemIds.clear();
                          } else {
                            _selectedItemIds.addAll(
                              _items.map((i) => i.itemId.isNotEmpty ? i.itemId : i.itemName),
                            );
                          }
                        });
                      },
                      child: Text(
                        _selectedItemIds.length == _items.length && _items.isNotEmpty ? 'Deselect All' : 'Select All',
                        style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: Text('Delete Selected (${_selectedItemIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _selectedItemIds.isEmpty ? null : _confirmDeleteSelectedItems,
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
                          _selectedItemIds.clear();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(child: Text('No items found.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 1;
                            if (constraints.maxWidth > 1200) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth > 800) {
                              crossAxisCount = 3;
                            } else if (constraints.maxWidth > 600) {
                              crossAxisCount = 2;
                            }
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.35, // Adjust card height
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                return _buildItemCard(_items[index]);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemDatabaseModel item) {
    final itemKey = item.itemId.isNotEmpty ? item.itemId : item.itemName;
    final isSelected = _selectedItemIds.contains(itemKey);

    return InkWell(
      onTap: () {
        if (_isDeleteMode) {
          setState(() {
            if (isSelected) {
              _selectedItemIds.remove(itemKey);
            } else {
              _selectedItemIds.add(itemKey);
            }
          });
        } else {
          _showItemDetails(item);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[50]?.withAlpha(140) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.red[600]!
                : (_isDeleteMode ? Colors.red[200]! : Colors.grey[200]!),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.02 * 255).toInt()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.itemType != null && item.itemType!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.itemType!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_isDeleteMode) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20,
                    color: isSelected ? Colors.red[700] : Colors.grey[400],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Info Rows
            _buildInfoRow(Icons.tag, 'ID: ${item.itemId}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.inventory_2_outlined, 'Vendor: ${item.vendor ?? 'N/A'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.pin_drop_outlined, 'SKU: ${item.sku ?? 'N/A'}'),
            if (item.description != null && item.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.description_outlined, 'Desc: ${item.description!.replaceAll('\n', ' ').trim()}', maxLines: 2),
            ],
          ],
        ),
      ),
    );
  }

  void _showItemDetails(ItemDatabaseModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Item Type', item.itemType ?? 'N/A'),
                  _buildDetailRow('HSN Code', item.hsnSac ?? 'N/A'),
                  _buildDetailRow('Unit', item.usageUnit ?? item.unitName ?? 'N/A'),
                  _buildDetailRow('Tax Preference', item.taxable ?? 'N/A'),
                  _buildDetailRow('Intra State Tax Rate', '${item.intraStateTaxRate ?? '0'} %'),
                  _buildDetailRow('Inter State Tax Rate', '${item.interStateTaxRate ?? '0'} %'),
                  _buildDetailRow('Status', item.status ?? 'N/A'),
                  const SizedBox(height: 24),
                  Text('Sales Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Selling Price', (item.rate ?? '0.00').replaceAll('INR ', '')),
                  _buildDetailRow('Description', item.description ?? 'N/A'),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 2.0 : 0.0),
          child: Icon(icon, size: 14, color: Colors.grey[400]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
