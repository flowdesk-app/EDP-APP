import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/delivery_challan_model.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../utils/pdf_delivery_challan_api.dart';

class DeliveryChallanEditDialog extends StatefulWidget {
  final DeliveryChallanModel? existingChallan;
  final JobModel? initialJob;
  final String? initialSupplierName;
  final int? initialQuantity;

  const DeliveryChallanEditDialog({
    super.key,
    this.existingChallan,
    this.initialJob,
    this.initialSupplierName,
    this.initialQuantity,
  });

  @override
  State<DeliveryChallanEditDialog> createState() => _DeliveryChallanEditDialogState();
}

class _DeliveryChallanEditDialogState extends State<DeliveryChallanEditDialog> {
  final ApiService _api = ApiService();
  bool _loading = false;
  bool _saving = false;

  late TextEditingController _dcNumberCtrl;
  late DateTime _date;
  late TextEditingController _supplierNameCtrl;
  late TextEditingController _supplierAddressCtrl;
  late TextEditingController _supplierGstinCtrl;
  late TextEditingController _placeOfSupplyCtrl;
  late TextEditingController _referenceCtrl;
  late TextEditingController _challanTypeCtrl;

  List<DeliveryChallanItem> _items = [];

  @override
  void initState() {
    super.initState();
    final c = widget.existingChallan;
    final job = widget.initialJob;

    _dcNumberCtrl = TextEditingController(text: c?.dcNumber ?? '');
    _date = c?.date ?? DateTime.now();

    final supplier = c?.supplierName ?? widget.initialSupplierName ?? job?.supplier ?? 'SKMT Engineering Enerprises';
    _supplierNameCtrl = TextEditingController(text: supplier);

    String address = c?.supplierAddress ?? '';
    String gstin = c?.supplierGstin ?? '';

    if (address.isEmpty && supplier.toUpperCase().contains('SKMT')) {
      address = '63, Sarangapani Street, Sivabootham\nVanagaram, Chennai - 600095,\n-';
      gstin = 'GSTIN 33AFFPV1640H1ZK';
    }

    _supplierAddressCtrl = TextEditingController(text: address);
    _supplierGstinCtrl = TextEditingController(text: gstin);
    _placeOfSupplyCtrl = TextEditingController(text: c?.placeOfSupply ?? 'Tamil Nadu (33)');
    _referenceCtrl = TextEditingController(text: c?.reference ?? 'sent for grinding polishing return');
    _challanTypeCtrl = TextEditingController(text: c?.challanType ?? 'Job Work');

    if (c != null && c.items.isNotEmpty) {
      _items = List.from(c.items);
    } else if (job != null) {
      // Build smart initial description from job details
      String desc = '';
      if (job.wheelSize != null && job.wheelSize!.trim().isNotEmpty) {
        final lines = job.wheelSize!.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).toList();
        desc = lines.isNotEmpty ? lines.first : job.wheelSize!;
      } else if (job.partDescription != null && job.partDescription!.isNotEmpty) {
        desc = job.partDescription!;
      } else if (job.partNumber != null) {
        desc = job.partNumber!;
      }

      if (!desc.toUpperCase().startsWith('EDP')) {
        desc = 'EDP- $desc';
      }

      final op = ' for Grinding and polishing and return.';
      if (!desc.toLowerCase().contains('grinding') && !desc.toLowerCase().contains('return')) {
        desc = '$desc$op';
      }

      final qty = widget.initialQuantity ?? job.quantity ?? 1;

      _items = [
        DeliveryChallanItem(
          itemNumber: 1,
          jobId: job.jobId,
          description: desc,
          quantity: qty > 0 ? qty : 1,
          unit: 'No(s)',
          approxValue: 1.00,
        ),
      ];
    } else {
      _items = [
        DeliveryChallanItem(
          itemNumber: 1,
          description: 'EDP- Grinding Wheel for Job Work and return',
          quantity: 1,
          unit: 'No(s)',
          approxValue: 1.00,
        ),
      ];
    }

    if (_dcNumberCtrl.text.isEmpty) {
      _fetchNextDcNumber();
    }
  }

  Future<void> _fetchNextDcNumber() async {
    setState(() => _loading = true);
    try {
      final next = await _api.getNextDeliveryChallanNumber();
      if (mounted && _dcNumberCtrl.text.isEmpty) {
        setState(() {
          _dcNumberCtrl.text = next;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSupplierChanged(String name) {
    if (name.toUpperCase().contains('SKMT')) {
      if (_supplierAddressCtrl.text.isEmpty || _supplierAddressCtrl.text.contains('Vanagaram')) {
        _supplierAddressCtrl.text = '63, Sarangapani Street, Sivabootham\nVanagaram, Chennai - 600095,\n-';
      }
      if (_supplierGstinCtrl.text.isEmpty || _supplierGstinCtrl.text.contains('33AFFPV1640H1ZK')) {
        _supplierGstinCtrl.text = 'GSTIN 33AFFPV1640H1ZK';
      }
    }
  }

  @override
  void dispose() {
    _dcNumberCtrl.dispose();
    _supplierNameCtrl.dispose();
    _supplierAddressCtrl.dispose();
    _supplierGstinCtrl.dispose();
    _placeOfSupplyCtrl.dispose();
    _referenceCtrl.dispose();
    _challanTypeCtrl.dispose();
    super.dispose();
  }

  DeliveryChallanModel _buildCurrentModel() {
    return DeliveryChallanModel(
      id: widget.existingChallan?.id,
      dcNumber: _dcNumberCtrl.text.trim().isNotEmpty ? _dcNumberCtrl.text.trim() : 'DC2627-00232',
      date: _date,
      supplierName: _supplierNameCtrl.text.trim(),
      supplierAddress: _supplierAddressCtrl.text.trim(),
      supplierGstin: _supplierGstinCtrl.text.trim().isNotEmpty ? _supplierGstinCtrl.text.trim() : null,
      placeOfSupply: _placeOfSupplyCtrl.text.trim().isNotEmpty ? _placeOfSupplyCtrl.text.trim() : 'Tamil Nadu (33)',
      reference: _referenceCtrl.text.trim().isNotEmpty ? _referenceCtrl.text.trim() : null,
      challanType: _challanTypeCtrl.text.trim().isNotEmpty ? _challanTypeCtrl.text.trim() : 'Job Work',
      items: _items,
      jobIds: _items.map((i) => i.jobId).where((id) => id != null && id.isNotEmpty).cast<String>().toSet().toList(),
    );
  }

  Future<DeliveryChallanModel?> _saveChallan() async {
    if (_supplierNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Supplier Name'), backgroundColor: Colors.red),
      );
      return null;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the Delivery Challan'), backgroundColor: Colors.red),
      );
      return null;
    }

    setState(() => _saving = true);
    try {
      final model = _buildCurrentModel();
      final saved = await _api.saveDeliveryChallan(model);
      return saved;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Delivery Challan: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addItem() {
    setState(() {
      final nextNum = _items.length + 1;
      _items.add(
        DeliveryChallanItem(
          itemNumber: nextNum,
          description: '',
          quantity: 1,
          unit: 'No(s)',
          approxValue: 1.00,
        ),
      );
    });
  }

  void _editItem(int index) async {
    final item = _items[index];
    final descCtrl = TextEditingController(text: item.description);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final valCtrl = TextEditingController(text: item.approxValue.toStringAsFixed(2));

    final updated = await showDialog<DeliveryChallanItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Item #${item.itemNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: valCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Approx Value (₹)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              final v = double.tryParse(valCtrl.text.trim()) ?? 1.00;
              Navigator.pop(
                ctx,
                item.copyWith(
                  description: descCtrl.text.trim(),
                  quantity: q,
                  approxValue: v,
                ),
              );
            },
            child: const Text('Save Item'),
          ),
        ],
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _items[index] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF0288D1), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingChallan != null ? 'Edit Delivery Challan' : 'Generate Delivery Challan',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Official Returnable Delivery Challan for job work & supplier movements',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DC Number & Date
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dcNumberCtrl,
                              decoration: InputDecoration(
                                labelText: 'Delivery Challan Number',
                                hintText: 'DC2627-00232',
                                border: const OutlineInputBorder(),
                                suffixIcon: _loading
                                    ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _date = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Challan Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                                ),
                                child: Text(DateFormat('dd MMM yyyy').format(_date)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Deliver To (Supplier Name)
                      TextField(
                        controller: _supplierNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Deliver To (Supplier Name)',
                          hintText: 'SKMT Engineering Enerprises',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _onSupplierChanged,
                      ),
                      const SizedBox(height: 12),

                      // Address
                      TextField(
                        controller: _supplierAddressCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Supplier Address',
                          hintText: '63, Sarangapani Street, Sivabootham\nVanagaram, Chennai - 600095,',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // GSTIN & Place of Supply
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supplierGstinCtrl,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN (Optional)',
                                hintText: 'GSTIN 33AFFPV1640H1ZK',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _placeOfSupplyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Place Of Supply',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reference & Challan Type
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _referenceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Reference (e.g. sizing, grinding polishing return)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _challanTypeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Challan Type',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Items Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Challan Items',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Another Item'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0288D1),
                              side: const BorderSide(color: Color(0xFF0288D1)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Items List Card
                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final it = entry.value;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF0288D1),
                                  child: Text('${it.itemNumber}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.description.isNotEmpty ? it.description : 'No Description',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Qty: ${it.quantity} ${it.unit}  •  Approx Value: ₹${it.approxValue.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF0288D1)),
                                  tooltip: 'Edit item',
                                  onPressed: () => _editItem(idx),
                                ),
                                if (_items.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'Remove item',
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(idx);
                                        // Re-number
                                        for (int i = 0; i < _items.length; i++) {
                                          _items[i] = _items[i].copyWith(itemNumber: i + 1);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final model = _buildCurrentModel();
                      await PdfDeliveryChallanApi.printOrShare(model);
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Preview / Print'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0288D1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : () async {
                                final nav = Navigator.of(context);
                                final saved = await _saveChallan();
                                if (saved != null && mounted) {
                                  nav.pop(saved);
                                  await PdfDeliveryChallanApi.printOrShare(saved);
                                }
                              },
                        icon: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Save & Download DC PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      ),
    );
  }
}
