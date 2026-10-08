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
  String _companySearchQuery = '';

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
          if (company.name == 'Lapping Compound' && (upperName.contains('LC-') || upperName.contains(' LC '))) {
             return true;
          }
          if (company.name == 'ADMAC' && (upperName.contains('ADMAC') || upperName.contains('ADMACH'))) {
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
        width: 1000,
        height: 800,
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
    final filteredCompanies = kCompanyStorages
        .where((company) => company.name.toLowerCase().contains(_companySearchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search companies...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _companySearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredCompanies.length,
            itemBuilder: (context, index) {
              final company = filteredCompanies[index];
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
          ),
        ),
      ],
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
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                  ? const Center(child: Text('No items found.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 800) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 500) {
                          crossAxisCount = 2;
                        }
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildItemCard(_filteredItems[index]);
                          },
                        );
                      },
                    ),
        ),
      ],
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Close the item details dialog
                        Navigator.pop(context);
                        // Confirm selection back to the main form
                        _confirmSelection(item);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF29B6F6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
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

}
