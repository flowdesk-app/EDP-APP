import 'package:flutter/material.dart';
import '../../models/item_database_model.dart';
import '../../utils/company_utils.dart';

import '../../services/api_service.dart';

class ItemDatabaseScreen extends StatefulWidget {
  const ItemDatabaseScreen({super.key});

  @override
  State<ItemDatabaseScreen> createState() => _ItemDatabaseScreenState();
}

class _ItemDatabaseScreenState extends State<ItemDatabaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemDatabaseModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems([String search = '']) async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService().getDatabaseItems(search);
      final unassignedItems = items.where((i) => getCompaniesForPrefix(i.itemName).isEmpty).toList();
      
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        final escapedQ = RegExp.escape(q);
        
        int getScore(ItemDatabaseModel item) {
          final name = item.itemName.toLowerCase();
          final desc = (item.description ?? '').toLowerCase();
          
          if (name == q) return 100;
          if (name.startsWith(q)) return 90;
          if (name.contains(RegExp('\\b$escapedQ\\b'))) return 80;
          if (name.contains(RegExp('\\b$escapedQ'))) return 70;
          if (name.contains(q)) return 60;
          
          if (desc == q) return 50;
          if (desc.startsWith(q)) return 40;
          if (desc.contains(RegExp('\\b$escapedQ\\b'))) return 30;
          if (desc.contains(RegExp('\\b$escapedQ'))) return 20;
          if (desc.contains(q)) return 10;
          
          return 0;
        }
        
        unassignedItems.sort((a, b) => getScore(b).compareTo(getScore(a)));
      }

      if (mounted) {
        setState(() {
          _items = unassignedItems;
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
    _fetchItems(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const Text(
                      'Item Database',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse and manage item master records.',
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
                    onSubmitted: _onSearchChanged,
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
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Item Type', item.itemType ?? 'N/A'),
                  _buildDetailRow('HSN Code', item.hsnSac ?? 'N/A'),
                  _buildDetailRow('Unit', item.usageUnit ?? item.unitName ?? 'N/A'),
                  _buildDetailRow('Tax Preference', item.taxable ?? 'N/A'),
                  _buildDetailRow('Intra State Tax Rate', '${item.intraStateTaxRate ?? '0'} %'),
                  _buildDetailRow('Inter State Tax Rate', '${item.interStateTaxRate ?? '0'} %'),
                  _buildDetailRow('Status', item.status ?? 'N/A'),
                  const SizedBox(height: 24),
                  const Text('Sales Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
