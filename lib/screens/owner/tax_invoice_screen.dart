import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../models/company_storage.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../utils/pdf_tax_invoice_api.dart';
import '../../widgets/global_logout_button.dart';

class TaxInvoiceScreen extends StatefulWidget {
  final JobModel? initialJob;

  const TaxInvoiceScreen({super.key, this.initialJob});

  @override
  State<TaxInvoiceScreen> createState() => _TaxInvoiceScreenState();
}

class _TaxInvoiceScreenState extends State<TaxInvoiceScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _masterData = [];

  // Controllers - Meta Info
  final _invoiceNoCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  final _poNoCtrl = TextEditingController();
  final _placeOfSupplyCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _docRefCtrl = TextEditingController();
  final _deliveryRefCtrl = TextEditingController();

  // Controllers - Bill To
  final _billToNameCtrl = TextEditingController();
  final _billToAddressCtrl = TextEditingController();
  final _billToGstinCtrl = TextEditingController();
  final _billToVendorCodeCtrl = TextEditingController();

  // Controllers - Ship To
  bool _sameAsBillTo = true;
  final _shipToNameCtrl = TextEditingController();
  final _shipToAddressCtrl = TextEditingController();
  final _shipToGstinCtrl = TextEditingController();
  final _shipToVendorCodeCtrl = TextEditingController();

  // Tax and Items
  TaxType _taxType = TaxType.igst18;
  final _customTaxRateCtrl = TextEditingController(text: '18');
  final _manualRoundingCtrl = TextEditingController();
  bool _useManualRounding = false;

  final List<TaxInvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initDefaultInvoiceNumber();
    _loadMasterData();

    if (widget.initialJob != null) {
      _populateFromJob(widget.initialJob!);
    }
  }

  void _initDefaultInvoiceNumber() {
    final now = DateTime.now();
    final yearSuffix = '${now.year % 100}${(now.year + 1) % 100}';
    _invoiceNoCtrl.text = '$yearSuffix-${now.millisecondsSinceEpoch.toString().substring(7, 13)}';
  }

  Future<void> _loadMasterData() async {
    try {
      final data = await _api.getMasterData();
      if (mounted) setState(() => _masterData = data);
    } catch (e) {
      debugPrint('Error loading master data: $e');
    }
  }

  void _populateFromJob(JobModel job) {
    // 1. Check if customer name matches a company in kCompanyStorages
    CompanyStorage? matchedCompany;
    if (job.customerName != null && job.customerName!.trim().isNotEmpty) {
      final nameLower = job.customerName!.trim().toLowerCase();
      try {
        matchedCompany = kCompanyStorages.firstWhere(
          (c) =>
              c.name.toLowerCase() == nameLower ||
              c.aliases.any((a) => a.toLowerCase() == nameLower) ||
              c.prefixes.any((p) => nameLower.startsWith(p.toLowerCase())),
        );
      } catch (_) {
        matchedCompany = null;
      }
    }

    if (matchedCompany != null) {
      _applyCompany(matchedCompany);
    } else if (job.customerName != null) {
      _billToNameCtrl.text = job.customerName!;
    }

    // 2. PO Number
    if (job.purchaseOrderNumber != null && job.purchaseOrderNumber!.trim().isNotEmpty) {
      String po = job.purchaseOrderNumber!.trim();
      if (job.purchaseOrderDate != null) {
        po += ' DT ${DateFormat('dd MMM yyyy').format(job.purchaseOrderDate!).toUpperCase()}';
      }
      _poNoCtrl.text = po;
    }

    // 3. Reference
    if (job.returnableGatePassNumber != null && job.returnableGatePassNumber!.trim().isNotEmpty) {
      String ref = 'Rgp:${job.returnableGatePassNumber!.trim()}';
      if (job.returnableGatePassDate != null) {
        ref += ' DT ${DateFormat('dd.MM.yyyy').format(job.returnableGatePassDate!)}';
      }
      _referenceCtrl.text = ref;
    } else {
      _referenceCtrl.text = 'Job #${job.jobId}';
    }

    // 4. DOC Ref
    if (job.deliveryChalanNumber != null && job.deliveryChalanNumber!.trim().isNotEmpty) {
      String doc = 'DC NO: ${job.deliveryChalanNumber!.trim()}';
      if (job.deliveryChalanDate != null) {
        doc += ' DT ${DateFormat('dd.MM.yyyy').format(job.deliveryChalanDate!)}';
      }
      _docRefCtrl.text = doc;
    }

    // 5. Item
    final descParts = <String>[];
    if (job.wheelSize != null && job.wheelSize!.trim().isNotEmpty) {
      descParts.add('EDP - ${job.wheelSize!.trim()}');
    } else if (job.partDescription != null && job.partDescription!.trim().isNotEmpty) {
      descParts.add('EDP - ${job.partDescription!.trim()}');
    } else {
      descParts.add('EDP Grinding Wheel');
    }

    if (job.partNumber != null && job.partNumber!.trim().isNotEmpty) {
      descParts.add('Drg no :${job.partNumber!.trim()}');
    }
    if (job.diamondPowderGritSize != null && job.diamondPowderGritSize!.trim().isNotEmpty) {
      descParts.add('Grit: ${job.diamondPowderGritSize!.trim()}');
    }

    _items.clear();
    _items.add(TaxInvoiceItem(
      description: descParts.join('\n'),
      hsnCode: '68042110',
      quantity: job.quantity ?? 1,
      rate: 0.0,
    ));
  }

  void _applyCompany(CompanyStorage company) {
    _billToNameCtrl.text = company.name;
    _billToAddressCtrl.text = company.billingAddress.isNotEmpty ? company.billingAddress : company.shippingAddress;
    _billToGstinCtrl.text = company.gstin;
    _billToVendorCodeCtrl.text = company.vendorCode;

    _shipToNameCtrl.text = company.name;
    _shipToAddressCtrl.text = company.shippingAddress.isNotEmpty ? company.shippingAddress : company.billingAddress;
    _shipToGstinCtrl.text = company.gstin;
    _shipToVendorCodeCtrl.text = company.vendorCode;

    if (company.placeOfSupply.isNotEmpty) {
      _placeOfSupplyCtrl.text = company.placeOfSupply;
    } else if (company.state.isNotEmpty) {
      _placeOfSupplyCtrl.text = company.state;
    }

    _detectTaxType();
  }

  void _detectTaxType() {
    final pos = _placeOfSupplyCtrl.text.toLowerCase();
    final billAddr = _billToAddressCtrl.text.toLowerCase();
    final docRef = _docRefCtrl.text.toLowerCase();

    if (docRef.contains('lut') || billAddr.contains('sez') || pos.contains('sez')) {
      _taxType = TaxType.lutExempt;
    } else if (pos.contains('tamil nadu') || pos.contains('tamilnadu') || pos.contains('(33)') || pos.endsWith('33')) {
      _taxType = TaxType.cgstSgst9;
    } else {
      _taxType = TaxType.igst18;
    }
  }

  List<String> _getSuggestions(String fieldKey) {
    return _masterData
        .where((m) => (m['jobType'] == 'Invoice' || m['jobType'] == 'TaxInvoice') && m['field'] == fieldKey)
        .map((m) => m['value'].toString())
        .toSet()
        .toList();
  }

  Future<void> _saveMasterDataField(String field, String value) async {
    if (value.trim().isEmpty) return;
    try {
      await _api.saveMasterData('TaxInvoice', field, value.trim());
    } catch (e) {
      debugPrint('Error saving $field: $e');
    }
  }

  Future<void> _saveAllMasterData() async {
    await _saveMasterDataField('Customer Name', _billToNameCtrl.text);
    await _saveMasterDataField('Billing Address', _billToAddressCtrl.text);
    await _saveMasterDataField('Shipping Address', _shipToAddressCtrl.text);
    await _saveMasterDataField('GSTIN', _billToGstinCtrl.text);
    await _saveMasterDataField('Place Of Supply', _placeOfSupplyCtrl.text);

    for (var item in _items) {
      await _saveMasterDataField('Item Description', item.description);
      await _saveMasterDataField('HSN Code', item.hsnCode);
    }

    _loadMasterData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved fields to Job Master successfully!')),
      );
    }
  }

  void _showItemDialog({TaxInvoiceItem? existingItem, int? index}) {
    final descCtrl = TextEditingController(text: existingItem?.description ?? '');
    final hsnCtrl = TextEditingController(text: existingItem?.hsnCode ?? '68042110');
    final qtyCtrl = TextEditingController(text: existingItem != null ? '${existingItem.quantity}' : '1');
    final unitCtrl = TextEditingController(text: existingItem?.unit ?? 'No(s)');
    final rateCtrl = TextEditingController(text: existingItem != null && existingItem.rate > 0 ? '${existingItem.rate}' : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(existingItem == null ? 'Add Item' : 'Edit Item'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: descCtrl.text),
                  optionsBuilder: (textVal) {
                    final query = textVal.text.toLowerCase();
                    final suggestions = _getSuggestions('Item Description');
                    if (query.isEmpty) return suggestions;
                    return suggestions.where((s) => s.toLowerCase().contains(query));
                  },
                  onSelected: (val) => descCtrl.text = val,
                  fieldViewBuilder: (ctx, textCtrl, fNode, onSubmit) {
                    textCtrl.addListener(() => descCtrl.text = textCtrl.text);
                    return TextField(
                      controller: textCtrl,
                      focusNode: fNode,
                      decoration: const InputDecoration(
                        labelText: 'Item & Description',
                        border: OutlineInputBorder(),
                        helperText: 'e.g. EDP - Dia 150mm peripheral wheel...\nDrg no ;BP50011',
                      ),
                      maxLines: 4,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: hsnCtrl,
                        decoration: const InputDecoration(labelText: 'HSN/SAC Code', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  decoration: const InputDecoration(labelText: 'Rate (Rs.)', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
              final newItem = TaxInvoiceItem(
                description: descCtrl.text.trim(),
                hsnCode: hsnCtrl.text.trim().isEmpty ? '68042110' : hsnCtrl.text.trim(),
                quantity: qty,
                unit: unitCtrl.text.trim().isEmpty ? 'No(s)' : unitCtrl.text.trim(),
                rate: rate,
              );

              setState(() {
                if (index != null && index >= 0 && index < _items.length) {
                  _items[index] = newItem;
                } else {
                  _items.add(newItem);
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(existingItem == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  TaxInvoiceData _buildTaxInvoiceData() {
    double? manualRound;
    if (_useManualRounding) {
      manualRound = double.tryParse(_manualRoundingCtrl.text.trim());
    }

    final customRate = double.tryParse(_customTaxRateCtrl.text.trim()) ?? 18.0;

    return TaxInvoiceData(
      invoiceNo: _invoiceNoCtrl.text.trim(),
      invoiceDate: _invoiceDate,
      poNo: _poNoCtrl.text.trim(),
      placeOfSupply: _placeOfSupplyCtrl.text.trim(),
      reference: _referenceCtrl.text.trim(),
      docRef: _docRefCtrl.text.trim(),
      deliveryRef: _deliveryRefCtrl.text.trim(),
      billToName: _billToNameCtrl.text.trim(),
      billToAddress: _billToAddressCtrl.text.trim(),
      billToGstin: _billToGstinCtrl.text.trim(),
      billToVendorCode: _billToVendorCodeCtrl.text.trim(),
      shipToName: _sameAsBillTo ? _billToNameCtrl.text.trim() : _shipToNameCtrl.text.trim(),
      shipToAddress: _sameAsBillTo ? _billToAddressCtrl.text.trim() : _shipToAddressCtrl.text.trim(),
      shipToGstin: _sameAsBillTo ? _billToGstinCtrl.text.trim() : _shipToGstinCtrl.text.trim(),
      shipToVendorCode: _sameAsBillTo ? _billToVendorCodeCtrl.text.trim() : _shipToVendorCodeCtrl.text.trim(),
      items: _items,
      taxType: _taxType,
      customTaxRate: customRate,
      manualRounding: manualRound,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewData = _buildTaxInvoiceData();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Generate Tax Invoice', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 1,
        actions: [
          const GlobalLogoutButton(),
          TextButton.icon(
            onPressed: _saveAllMasterData,
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text('Save to Master'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Form Panel
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Quick Company Search Card
                  Card(
                    elevation: 0,
                    color: const Color(0xFFE8F0FE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFC2E7FF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.business, size: 20, color: Color(0xFF1A73E8)),
                              SizedBox(width: 8),
                              Text('Select Company from Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A73E8))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Autocomplete<CompanyStorage>(
                            displayStringForOption: (c) => c.name,
                            optionsBuilder: (textVal) {
                              if (textVal.text.trim().isEmpty) return const Iterable<CompanyStorage>.empty();
                              final query = textVal.text.trim().toLowerCase();
                              return kCompanyStorages.where((c) =>
                                  c.name.toLowerCase().contains(query) ||
                                  c.aliases.any((a) => a.toLowerCase().contains(query)) ||
                                  c.prefixes.any((p) => p.toLowerCase().contains(query)));
                            },
                            onSelected: (company) {
                              setState(() {
                                _applyCompany(company);
                              });
                            },
                            fieldViewBuilder: (ctx, ctrl, fNode, onSubmit) {
                              return TextField(
                                controller: ctrl,
                                focusNode: fNode,
                                decoration: InputDecoration(
                                  hintText: 'Type to search 58 official companies...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  isDense: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. General Metadata Section
                  _buildSectionHeader('Invoice & Supply Details', Icons.receipt_long),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _invoiceNoCtrl,
                          decoration: const InputDecoration(labelText: 'Invoice#', border: OutlineInputBorder(), isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _invoiceDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) setState(() => _invoiceDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Invoice Date',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(DateFormat('dd MMM yyyy').format(_invoiceDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _poNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'P.O.#',
                      border: OutlineInputBorder(),
                      isDense: true,
                      helperText: 'e.g. 3100-5700010615 DT02 AUG 2025',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _placeOfSupplyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Place Of Supply',
                            border: OutlineInputBorder(),
                            isDense: true,
                            helperText: 'e.g. Telangana (36) or Tamil Nadu (33)',
                          ),
                          onChanged: (_) {
                            _detectTaxType();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _referenceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Reference',
                            border: OutlineInputBorder(),
                            isDense: true,
                            helperText: 'e.g. Rgp:AH3260000324 DT. 25.08.2026',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _docRefCtrl,
                          decoration: const InputDecoration(
                            labelText: 'DOC Ref',
                            border: OutlineInputBorder(),
                            isDense: true,
                            helperText: 'e.g. LUT NO; AD330326082684X DT 26.03.2026',
                          ),
                          onChanged: (_) {
                            _detectTaxType();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _deliveryRefCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Ref',
                            border: OutlineInputBorder(),
                            isDense: true,
                            helperText: 'e.g. TPNO 4971939707 DT 25.08.2026',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Bill To Section
                  _buildSectionHeader('Bill To (Customer Details)', Icons.location_city),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _billToNameCtrl,
                    decoration: const InputDecoration(labelText: 'Company / Customer Name', border: OutlineInputBorder(), isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _billToAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Billing Address', border: OutlineInputBorder(), isDense: true),
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _billToGstinCtrl,
                          decoration: const InputDecoration(labelText: 'GSTIN', border: OutlineInputBorder(), isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _billToVendorCodeCtrl,
                          decoration: const InputDecoration(labelText: 'Vendor Code', border: OutlineInputBorder(), isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Ship To Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Ship To', Icons.local_shipping_outlined),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _sameAsBillTo,
                            onChanged: (v) => setState(() => _sameAsBillTo = v ?? true),
                          ),
                          const Text('Same as Bill To', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  if (!_sameAsBillTo) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _shipToNameCtrl,
                      decoration: const InputDecoration(labelText: 'Ship To Customer Name', border: OutlineInputBorder(), isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _shipToAddressCtrl,
                      decoration: const InputDecoration(labelText: 'Shipping Address', border: OutlineInputBorder(), isDense: true),
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _shipToGstinCtrl,
                            decoration: const InputDecoration(labelText: 'Ship To GSTIN', border: OutlineInputBorder(), isDense: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _shipToVendorCodeCtrl,
                            decoration: const InputDecoration(labelText: 'Ship To Vendor Code', border: OutlineInputBorder(), isDense: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 4. Line Items Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Items (${_items.length})', Icons.format_list_numbered),
                      ElevatedButton.icon(
                        onPressed: () => _showItemDialog(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('No items added yet. Click "Add Item" to add invoice items.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFE8F0FE),
                            child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
                          ),
                          title: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('HSN: ${item.hsnCode} | Qty: ${item.quantity} ${item.unit} | Rate: Rs. ${item.rate.toStringAsFixed(2)} | Total: Rs. ${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                onPressed: () => _showItemDialog(existingItem: item, index: idx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => setState(() => _items.removeAt(idx)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // 5. Tax & Total Settings
                  _buildSectionHeader('Taxation & Calculations', Icons.calculate_outlined),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaxType>(
                    initialValue: _taxType,
                    decoration: const InputDecoration(labelText: 'Tax Mode', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(
                        value: TaxType.igst18,
                        child: Text('IGST (18%) - Inter-State Supply'),
                      ),
                      DropdownMenuItem(
                        value: TaxType.cgstSgst9,
                        child: Text('CGST (9%) + SGST (9%) - Intra-State (Tamil Nadu)'),
                      ),
                      DropdownMenuItem(
                        value: TaxType.lutExempt,
                        child: Text('LUT / SEZ Exempt (0% Tax)'),
                      ),
                      DropdownMenuItem(
                        value: TaxType.custom,
                        child: Text('Custom Tax Rate'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _taxType = v);
                    },
                  ),
                  if (_taxType == TaxType.custom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customTaxRateCtrl,
                      decoration: const InputDecoration(labelText: 'Custom Tax Rate (%)', border: OutlineInputBorder(), isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _useManualRounding,
                        onChanged: (v) => setState(() => _useManualRounding = v ?? false),
                      ),
                      const Text('Manual Rounding Override', style: TextStyle(fontSize: 13)),
                      if (_useManualRounding) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _manualRoundingCtrl,
                            decoration: const InputDecoration(labelText: 'Rounding', border: OutlineInputBorder(), isDense: true),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Sub Total', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.subTotal)}'),
                        if (!previewData.isLutExempt && previewData.taxableAmount > 0) ...[
                          const SizedBox(height: 4),
                          _summaryRow('Taxable Amount', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.taxableAmount)}'),
                        ],
                        if (previewData.taxType == TaxType.igst18 || previewData.taxType == TaxType.custom) ...[
                          const SizedBox(height: 4),
                          _summaryRow('IGST (${previewData.igstRate}%)', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.igstAmount)}'),
                        ] else if (previewData.taxType == TaxType.cgstSgst9) ...[
                          const SizedBox(height: 4),
                          _summaryRow('CGST (9%)', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.cgstAmount)}'),
                          const SizedBox(height: 4),
                          _summaryRow('SGST (9%)', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.sgstAmount)}'),
                        ],
                        if (previewData.rounding != 0.0) ...[
                          const SizedBox(height: 4),
                          _summaryRow('Rounding', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.rounding)}'),
                        ],
                        const Divider(height: 16),
                        _summaryRow('Total', 'Rs. ${PdfTaxInvoiceApi.formatIndianCurrency(previewData.grandTotal)}', isBold: true),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            PdfTaxInvoiceApi.numberToWords(previewData.grandTotal),
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF1A73E8), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Print / Save Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        try {
                          final pdfBytes = await PdfTaxInvoiceApi.generate(_buildTaxInvoiceData());
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => pdfBytes,
                            name: 'Invoice_${_invoiceNoCtrl.text.trim()}.pdf',
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print / Save Tax Invoice PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Right Live PDF Preview
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade200,
              child: PdfPreview(
                build: (format) => PdfTaxInvoiceApi.generate(_buildTaxInvoiceData()),
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: 'Tax_Invoice_${_invoiceNoCtrl.text.trim()}.pdf',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF202124))),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
