import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'warehouse_item_detail.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _api.getWarehouseItems();
    if (mounted) {
      setState(() {
        _items = items;
        _filteredItems = items;
        _loading = false;
        _filterItems();
      });
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) {
          final itemName = (item['itemName'] ?? '').toString().toLowerCase();
          return itemName.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFFF8F9FA), body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Warehouse', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search warehouse items',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No items found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (ctx, i) {
                      final item = _filteredItems[i];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(item['itemName'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF1E8E3E)),
                                const SizedBox(width: 4),
                                Text('Delivered: ${item['quantity'] ?? 0}', style: const TextStyle(color: Color(0xFF1E8E3E), fontWeight: FontWeight.w500)),
                                const SizedBox(width: 16),
                                const Icon(Icons.pending_actions_outlined, size: 14, color: Color(0xFFF9AB00)),
                                const SizedBox(width: 4),
                                Text('Pending: ${item['pendingQuantity'] ?? 0}', style: const TextStyle(color: Color(0xFFF9AB00), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WarehouseItemDetailScreen(item: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ),
        ],
      ),
    );
  }
}
