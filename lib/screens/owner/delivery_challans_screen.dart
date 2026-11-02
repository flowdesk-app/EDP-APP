import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_challan_model.dart';
import '../../services/api_service.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../widgets/global_logout_button.dart';
import '../../utils/pdf_delivery_challan_api.dart';
import 'delivery_challan_edit_dialog.dart';

class DeliveryChallansScreen extends StatefulWidget {
  const DeliveryChallansScreen({super.key});

  @override
  State<DeliveryChallansScreen> createState() => _DeliveryChallansScreenState();
}

class _DeliveryChallansScreenState extends State<DeliveryChallansScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<DeliveryChallanModel> _allChallans = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedSupplierFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getDeliveryChallans();
      if (mounted) {
        setState(() {
          _allChallans = list;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Delivery Challans: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _supplierNames {
    final names = <String>{'All'};
    for (final c in _allChallans) {
      if (c.supplierName.trim().isNotEmpty) {
        names.add(c.supplierName.trim());
      }
    }
    return names.toList();
  }

  List<DeliveryChallanModel> get _filteredChallans {
    return _allChallans.where((c) {
      if (_selectedSupplierFilter != 'All' &&
          !c.supplierName.toLowerCase().contains(_selectedSupplierFilter.toLowerCase())) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesDc = c.dcNumber.toLowerCase().contains(q);
        final matchesSupplier = c.supplierName.toLowerCase().contains(q);
        final matchesRef = c.reference?.toLowerCase().contains(q) ?? false;
        final matchesJob = c.jobIds.any((id) => id.toLowerCase().contains(q));
        final matchesItems = c.items.any((it) => it.description.toLowerCase().contains(q));

        if (!matchesDc && !matchesSupplier && !matchesRef && !matchesJob && !matchesItems) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _openCreateDialog() async {
    final result = await showDialog<DeliveryChallanModel>(
      context: context,
      builder: (_) => const DeliveryChallanEditDialog(),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery Challan ${result.dcNumber} created successfully!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _loadData();
    }
  }

  void _openEditDialog(DeliveryChallanModel challan) async {
    final result = await showDialog<DeliveryChallanModel>(
      context: context,
      builder: (_) => DeliveryChallanEditDialog(existingChallan: challan),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery Challan ${result.dcNumber} updated successfully!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _loadData();
    }
  }

  Future<void> _deleteChallan(DeliveryChallanModel challan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Delivery Challan?'),
        content: Text('Are you sure you want to delete ${challan.dcNumber} for ${challan.supplierName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && challan.id != null) {
      final success = await _api.deleteDeliveryChallan(challan.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery Challan deleted'), backgroundColor: Colors.red),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredChallans;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text(
          'Delivery Challan (DC)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
          const GlobalLogoutButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopFilterBar(),
                Expanded(
                  child: list.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return _buildChallanCard(list[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Make Delivery Challan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTopFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by DC Number, Supplier, Job ID, Reference...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ],
          ),
          if (_supplierNames.length > 2) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _supplierNames.map((s) {
                  final isSelected = _selectedSupplierFilter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0288D1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedSupplierFilter = s);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.receipt_long, size: 56, color: Color(0xFF0288D1)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Delivery Challans Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Delivery Challans are generated when forwarding jobs to suppliers (like SKMT) or can be created manually here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Make Delivery Challan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallanCard(DeliveryChallanModel challan) {
    final totalQty = challan.items.fold<int>(0, (sum, it) => sum + it.quantity);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF7DD3FC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long, size: 14, color: Color(0xFF0288D1)),
                          const SizedBox(width: 4),
                          Text(
                            challan.dcNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0288D1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy').format(challan.date),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        challan.challanType,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalQty units (${challan.items.length} items)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deliver To
            Text(
              challan.supplierName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            if (challan.supplierAddress.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                challan.supplierAddress.replaceAll('\n', ', '),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (challan.reference != null && challan.reference!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Reference: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  Text(challan.reference!, style: const TextStyle(fontSize: 12, color: Color(0xFF0288D1), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const Divider(height: 20),

            // Items summary preview
            ...challan.items.take(3).map((it) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${it.itemNumber} ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    Expanded(
                      child: Text(
                        it.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${it.quantity} ${it.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
              );
            }),
            if (challan.items.length > 3)
              Text('+ ${challan.items.length - 3} more item(s)...', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),

            const Divider(height: 20),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (challan.jobIds.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: challan.jobIds.map((jid) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Job #$jid', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      );
                    }).toList(),
                  )
                else
                  const Text('Independent Challan', style: TextStyle(fontSize: 11, color: Colors.grey)),

                Row(
                  children: [
                    IconButton(
                      tooltip: 'Delete Challan',
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deleteChallan(challan),
                    ),
                    IconButton(
                      tooltip: 'Print Delivery Challan',
                      icon: const Icon(Icons.print, size: 20, color: Color(0xFF475569)),
                      onPressed: () => PdfDeliveryChallanApi.printOrShare(challan),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton.icon(
                      onPressed: () => _openEditDialog(challan),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('View / Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => PdfDeliveryChallanApi.printOrShare(challan),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
