import 'package:flutter/material.dart';
import '../../models/item_database_model.dart';
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
  List<ItemDatabaseModel> _allItems = [];
  List<ItemDatabaseModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
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

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _items = List.from(_allItems));
      return;
    }
    
    final q = query.toLowerCase();
    setState(() {
      _items = _allItems.where((item) =>
        item.itemName.toLowerCase().contains(q) ||
        ((item.sku ?? "").toLowerCase().contains(q)) ||
        (item.itemId.isNotEmpty && item.itemId.toLowerCase().contains(q)) ||
        ((item.description ?? "").toLowerCase().contains(q))
      ).toList();
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
                Container(
                  width: 300,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
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
                                childAspectRatio: 1.6, // Adjust card height
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
    return InkWell(
      onTap: () => _showItemDetails(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
              ],
            ),
            const SizedBox(height: 16),
            // Info Rows
            _buildInfoRow(Icons.tag, 'ID: ${item.itemId}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.inventory_2_outlined, 'Vendor: ${item.vendor ?? 'N/A'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.pin_drop_outlined, 'SKU: ${item.sku ?? 'N/A'}'),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
