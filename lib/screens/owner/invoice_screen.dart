import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../services/api_service.dart';
import '../../utils/pdf_invoice_api.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
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
    _loadMasterData();
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
    final hsnCtrl = TextEditingController();
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
                  hsnCode: hsnCtrl.text,
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
        setState(() {}); // trigger rebuild for pdf preview
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
    
    // Reload master data to update autocomplete
    _loadMasterData();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Job Master successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice / Sales Order', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
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
                            name: 'Invoice.pdf',
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
