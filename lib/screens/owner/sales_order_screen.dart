import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../models/company_storage.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../utils/pdf_invoice_api.dart';
import '../../widgets/global_logout_button.dart';

class SalesOrderScreen extends StatefulWidget {
  final JobModel? initialJob;

  const SalesOrderScreen({super.key, this.initialJob});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _masterData = [];

  // Controllers
  final _invoiceTitleCtrl = TextEditingController(text: 'SALES ORDER');
  final _salesOrderNoCtrl = TextEditingController();
  final DateTime _salesOrderDate = DateTime.now();

  final _billToNameCtrl = TextEditingController();
  final _billToAddressCtrl = TextEditingController();
  final _billToGstinCtrl = TextEditingController();
  final _billToVendorCodeCtrl = TextEditingController();

  final _shipToNameCtrl = TextEditingController();
  final _shipToAddressCtrl = TextEditingController();
  final _shipToGstinCtrl = TextEditingController();
  final _shipToVendorCodeCtrl = TextEditingController();

  final _placeOfSupplyCtrl = TextEditingController();
  final DateTime _orderDate = DateTime.now();
  final _referenceCtrl = TextEditingController();

  final _taxPercentageCtrl = TextEditingController(text: '18');
  final _taxLabelCtrl = TextEditingController(text: 'IGST (18%)');

  final List<InvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initDefaultOrderNo();
    _loadMasterData();

    if (widget.initialJob != null) {
      _populateFromJob(widget.initialJob!);
    }
  }

  void _initDefaultOrderNo() {
    final now = DateTime.now();
    final yearSuffix = '${now.year % 100}${(now.year + 1) % 100}';
    _salesOrderNoCtrl.text = '$yearSuffix-${now.millisecondsSinceEpoch.toString().substring(7, 13)}';
  }

  void _populateFromJob(JobModel job) {
    // 1. Check matching company in kCompanyStorages
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
      _shipToNameCtrl.text = job.customerName!;
    }

    // 2. Reference / PO
    if (job.purchaseOrderNumber != null && job.purchaseOrderNumber!.trim().isNotEmpty) {
      String po = job.purchaseOrderNumber!.trim();
      if (job.purchaseOrderDate != null) {
        po += ' DT ${DateFormat('dd MMM yyyy').format(job.purchaseOrderDate!).toUpperCase()}';
      }
      _referenceCtrl.text = po;
    } else if (job.returnableGatePassNumber != null && job.returnableGatePassNumber!.trim().isNotEmpty) {
      _referenceCtrl.text = 'Rgp:${job.returnableGatePassNumber!.trim()}';
    } else {
      _referenceCtrl.text = 'Job #${job.jobId}';
    }

    // 3. Pre-add Item from job
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
    _items.add(InvoiceItem(
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

    final pos = _placeOfSupplyCtrl.text.toLowerCase();
    if (pos.contains('tamil nadu') || pos.contains('tamilnadu') || pos.contains('(33)') || pos.endsWith('33')) {
      _taxLabelCtrl.text = 'CGST (9%) + SGST (9%)';
      _taxPercentageCtrl.text = '18';
    } else {
      _taxLabelCtrl.text = 'IGST (18%)';
      _taxPercentageCtrl.text = '18';
    }
  }

  Future<void> _loadMasterData() async {
    try {
      final data = await _api.getMasterData();
      if (mounted) setState(() => _masterData = data);
    } catch (e) {
      debugPrint('Error loading master data: $e');
    }
  }

  List<String> _getSuggestions(String fieldKey) {
    return _masterData
        .where((m) => m['jobType'] == 'Invoice' && m['field'] == fieldKey)
        .map((m) => m['value'].toString())
        .toSet()
        .toList();
  }

  Future<void> _saveMasterDataField(String field, String value) async {
    if (value.trim().isEmpty) return;
    try {
      await _api.saveMasterData('Invoice', field, value.trim());
    } catch (e) {
      debugPrint('Error saving $field: $e');
    }
  }

  void _addItem() {
    final descCtrl = TextEditingController();
    final hsnCtrl = TextEditingController(text: '68042110');
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocomplete(descCtrl, 'Item Description', _getSuggestions('Item Description'), maxLines: 3),
              const SizedBox(height: 8),
              _buildAutocomplete(hsnCtrl, 'HSN/SAC Code', _getSuggestions('HSN Code')),
              const SizedBox(height: 8),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Rate'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final rate = double.tryParse(rateCtrl.text) ?? 0.0;
              setState(() {
                _items.add(InvoiceItem(
                  description: descCtrl.text,
                  hsnCode: hsnCtrl.text.isEmpty ? '68042110' : hsnCtrl.text,
                  quantity: qty,
                  rate: rate,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  Widget _buildAutocomplete(TextEditingController controller, String label, List<String> options, {int maxLines = 1}) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return options.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        controller.text = selection;
        setState(() {});
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (controller.text.isNotEmpty && textEditingController.text.isEmpty) {
          textEditingController.text = controller.text;
        }
        controller.addListener(() {
          if (controller.text != textEditingController.text) {
            textEditingController.text = controller.text;
          }
        });
        textEditingController.addListener(() {
          controller.text = textEditingController.text;
        });

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: 300,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((opt) => ListTile(title: Text(opt), onTap: () => onSelected(opt))).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  InvoiceData _buildInvoiceData() {
    return InvoiceData(
      invoiceTitle: _invoiceTitleCtrl.text.isEmpty ? 'SALES ORDER' : _invoiceTitleCtrl.text,
      salesOrderNo: _salesOrderNoCtrl.text,
      salesOrderDate: _salesOrderDate,
      billToName: _billToNameCtrl.text,
      billToAddress: _billToAddressCtrl.text,
      billToGstin: _billToGstinCtrl.text,
      billToVendorCode: _billToVendorCodeCtrl.text,
      shipToName: _shipToNameCtrl.text,
      shipToAddress: _shipToAddressCtrl.text,
      shipToGstin: _shipToGstinCtrl.text,
      shipToVendorCode: _shipToVendorCodeCtrl.text,
      placeOfSupply: _placeOfSupplyCtrl.text,
      orderDate: _orderDate,
      reference: _referenceCtrl.text,
      items: _items,
      taxPercentage: double.tryParse(_taxPercentageCtrl.text) ?? 0,
      taxLabel: _taxLabelCtrl.text.isEmpty ? 'Tax' : _taxLabelCtrl.text,
    );
  }

  Future<void> _saveAllMasterData() async {
    await _saveMasterDataField('Customer Name', _billToNameCtrl.text);
    await _saveMasterDataField('Billing Address', _billToAddressCtrl.text);
    await _saveMasterDataField('Shipping Address', _shipToAddressCtrl.text);
    await _saveMasterDataField('GSTIN', _billToGstinCtrl.text);

    for (var item in _items) {
      await _saveMasterDataField('Item Description', item.description);
      await _saveMasterDataField('HSN Code', item.hsnCode);
    }

    _loadMasterData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Job Master successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Sale Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          const GlobalLogoutButton(),
          TextButton.icon(
            onPressed: _saveAllMasterData,
            icon: const Icon(Icons.save),
            label: const Text('Save Fields to Master'),
          )
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: ListView(
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
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.business, size: 18, color: Color(0xFF1A73E8)),
                              SizedBox(width: 8),
                              Text('Select Company from Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A73E8))),
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
                                  prefixIcon: const Icon(Icons.search, size: 18),
                                  isDense: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text('General Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  const SizedBox(height: 12),
                  TextField(controller: _invoiceTitleCtrl, decoration: const InputDecoration(labelText: 'Document Title (e.g., SALES ORDER)', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),
                  const SizedBox(height: 12),
                  TextField(controller: _salesOrderNoCtrl, decoration: const InputDecoration(labelText: 'Sales Order No', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),
                  const SizedBox(height: 12),

                  const Text('Bill To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  const SizedBox(height: 12),
                  _buildAutocomplete(_billToNameCtrl, 'Customer / Company Name', _getSuggestions('Customer Name')),
                  const SizedBox(height: 8),
                  _buildAutocomplete(_billToAddressCtrl, 'Billing Address', _getSuggestions('Billing Address'), maxLines: 3),
                  const SizedBox(height: 8),
                  _buildAutocomplete(_billToGstinCtrl, 'GSTIN', _getSuggestions('GSTIN')),
                  const SizedBox(height: 8),
                  TextField(controller: _billToVendorCodeCtrl, decoration: const InputDecoration(labelText: 'Vendor Code', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),

                  const SizedBox(height: 24),
                  const Text('Ship To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  const SizedBox(height: 12),
                  _buildAutocomplete(_shipToNameCtrl, 'Customer / Company Name (Optional)', _getSuggestions('Customer Name')),
                  const SizedBox(height: 8),
                  _buildAutocomplete(_shipToAddressCtrl, 'Shipping Address', _getSuggestions('Shipping Address'), maxLines: 3),
                  const SizedBox(height: 8),
                  _buildAutocomplete(_shipToGstinCtrl, 'GSTIN', _getSuggestions('GSTIN')),
                  const SizedBox(height: 8),
                  TextField(controller: _shipToVendorCodeCtrl, decoration: const InputDecoration(labelText: 'Vendor Code', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),
                  const SizedBox(height: 8),
                  TextField(controller: _placeOfSupplyCtrl, decoration: const InputDecoration(labelText: 'Place of Supply', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),

                  const SizedBox(height: 24),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  const SizedBox(height: 12),
                  ..._items.asMap().entries.map((e) => Card(
                    child: ListTile(
                      title: Text(e.value.description),
                      subtitle: Text('Qty: ${e.value.quantity} | Rate: ${e.value.rate} | Amount: ${e.value.amount}'),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _items.removeAt(e.key))),
                    ),
                  )),
                  ElevatedButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add Item')),

                  const SizedBox(height: 24),
                  const Text('Tax & Extras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  const SizedBox(height: 12),
                  TextField(controller: _taxPercentageCtrl, decoration: const InputDecoration(labelText: 'Tax Percentage (e.g. 18)', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (_) => setState((){})),
                  const SizedBox(height: 8),
                  TextField(controller: _taxLabelCtrl, decoration: const InputDecoration(labelText: 'Tax Label (e.g. IGST (18%))', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),
                  const SizedBox(height: 8),
                  TextField(controller: _referenceCtrl, decoration: const InputDecoration(labelText: 'Reference', border: OutlineInputBorder(), isDense: true), onChanged: (_) => setState((){})),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final pdfBytes = await PdfInvoiceApi.generate(_buildInvoiceData());
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => pdfBytes,
                            name: 'Sales_Order_${_salesOrderNoCtrl.text.trim()}.pdf',
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print / Save PDF', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Right Panel: Live PDF Preview
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade200,
              child: PdfPreview(
                build: (format) => PdfInvoiceApi.generate(_buildInvoiceData()),
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
              ),
            ),
          )
        ],
      ),
    );
  }
}
