import 'package:flutter/material.dart';
import '../../models/company_storage.dart';
import '../../models/item_database_model.dart';
import '../../services/api_service.dart';

class StorageSelectionDialog extends StatefulWidget {
  const StorageSelectionDialog({Key? key}) : super(key: key);

  @override
  State<StorageSelectionDialog> createState() => _StorageSelectionDialogState();
}

class _StorageSelectionDialogState extends State<StorageSelectionDialog> {
  CompanyStorage? _selectedCompany;
  List<ItemDatabaseModel> _items = [];
  List<ItemDatabaseModel> _filteredItems = [];
  bool _isLoading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchItems(CompanyStorage company) async {
    setState(() {
      _selectedCompany = company;
      _isLoading = true;
      _searchCtrl.clear();
    });

    try {
      final items = await ApiService().getDatabaseItems();
      setState(() {
        _items = items.where((i) {
          final upperName = i.itemName.toUpperCase();
          if (company.name == 'Breaks India Limited' && (upperName.contains('SRIC') || upperName.contains('SRI CITY') || upperName.contains('SRI-CITY') || upperName.contains('BILSRI'))) {
             return false;
          }
          if (company.name == 'Brakes india limited SRICITY' && upperName.startsWith('BIL') && (upperName.contains('SRIC') || upperName.contains('SRI CITY') || upperName.contains('SRI-CITY') || upperName.contains('BILSRI'))) {
             return true;
          }
          if (company.name == 'Lapping Compound' && upperName.startsWith('LC')) {
             return true;
          }
          if (company.name == 'Rane Brake Lining Limited Trichy' && upperName.startsWith('RBL') && upperName.contains('TRICHY')) {
            return true;
          }
          if (company.name == 'Rane Brakelining Limited Pondicherry' && upperName.startsWith('RBL') && upperName.contains('PONDY')) {
            return true;
          }
          if (company.name == 'Rane Brake Lining Limited Ambattur' && upperName.startsWith('RBL') && upperName.contains('AMB')) {
            return true;
          }
          if (company.name == 'Rane Brakelining Limited Medak' && upperName.startsWith('RBL') && upperName.contains('MEDAK')) {
            return true;
          }
          if (company.name == 'Breaks India Limited' && upperName.startsWith('BIL')) return true;
          
          final parts = upperName.split(RegExp(r'[\s-]'));
          final firstPart = parts.isNotEmpty ? parts[0] : upperName;
          
          return company.prefixes.any((prefix) => firstPart.startsWith(prefix));
        }).toList();
        _filteredItems = List.from(_items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_items);
      } else {
        _filteredItems = _items.where((item) =>
          item.itemName.toLowerCase().contains(query.toLowerCase()) ||
          ((item.sku ?? "").toLowerCase().contains(query.toLowerCase())) ||
          (item.itemId.isNotEmpty && item.itemId.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }
    });
  }

  void _confirmSelection(ItemDatabaseModel item) {
    Navigator.of(context).pop({
      'company': _selectedCompany!.name,
      'item': item,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_selectedCompany != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedCompany = null;
                        _items = [];
                        _filteredItems = [];
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _selectedCompany == null ? 'Select Company Storage' : _selectedCompany!.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _selectedCompany == null ? _buildCompanyGrid() : _buildItemsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: kCompanyStorages.length,
      itemBuilder: (context, index) {
        final company = kCompanyStorages[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: InkWell(
            onTap: () => _fetchItems(company),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 32, color: Color(0xFF29B6F6)),
                  const SizedBox(height: 12),
                  Text(
                    company.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterItems,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                  ? const Center(child: Text('No items found.'))
                  : ListView.separated(
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${item.itemId} | SKU: ${item.sku ?? "N/A"}'),
                          trailing: ElevatedButton(
                            onPressed: () => _confirmSelection(item),
                            child: const Text('Confirm'),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
