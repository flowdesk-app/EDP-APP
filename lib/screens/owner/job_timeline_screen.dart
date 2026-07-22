import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

class JobTimelineScreen extends StatefulWidget {
  final JobModel job;

  const JobTimelineScreen({super.key, required this.job});

  @override
  State<JobTimelineScreen> createState() => _JobTimelineScreenState();
}

class _JobTimelineScreenState extends State<JobTimelineScreen> {
  bool _isUpdating = false;
  late JobModel _currentJob;
  List<String> _suppliers = [];
  bool _isAdmin = false;
  
  bool _extractionProcessYes = false;
  DateTime? _extractionDate;
  DateTime? _expectedExtractionDate;
  
  bool _extractionCompletedYes = false;
  DateTime? _extractionCompletedDate;
  DateTime? _productionDate;
  DateTime? _expectedProductionDate;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    _isAdmin = ApiService().currentUser?.role == UserRole.admin;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final s = await ApiService().getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = s.map((e) => e.supplierName).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load data: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() => _isUpdating = true);
    try {
      final allJobs = await ApiService().getFilteredJobs();
      final updatedJob = allJobs.firstWhere((j) => j.jobId == _currentJob.jobId, orElse: () => _currentJob);
      if (mounted) setState(() => _currentJob = updatedJob);
    } catch (e) {
      debugPrint('Error refreshing job: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStatus(String newStatus, {String? location, int? quantity}) async {
    setState(() => _isUpdating = true);
    try {
      await ApiService().updateJobStatus(_currentJob.jobId, newStatus, location: location, quantity: quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showReturnDialog() async {
    final ctrl = TextEditingController();
    final available = (_currentJob.status == 'Completed') 
        ? (_currentJob.quantity ?? 0) - (_currentJob.deliveredQuantity ?? 0) 
        : (_currentJob.deliveredQuantity ?? 0);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return Quantity'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Enter amount (Max: $available)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text);
              if (val == null || val <= 0 || val > available) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              try {
                await ApiService().returnPartialJob(_currentJob.jobId, val);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return processed!')));
                  _refresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  setState(() => _isUpdating = false);
                }
              }
            },
            child: const Text('Submit Return'),
          ),
        ],
      ),
    );
  }

  Future<void> _showForwardDialog() async {
    if (_suppliers.isEmpty && !_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No suppliers available')));
      return;
    }
    
    final ctrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: _currentJob.quantity?.toString() ?? '');
    final chalanCtrl = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (sbContext, setStateSB) {
          return AlertDialog(
            title: const Text('Forward to Next Supplier'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isAdmin ? Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _suppliers;
                      return _suppliers.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (selection) => ctrl.text = selection,
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      controller.addListener(() => ctrl.text = controller.text);
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Supplier Name', hintText: 'Type or select', border: OutlineInputBorder()),
                        onSubmitted: (_) => onFieldSubmitted(),
                      );
                    },
                  ) : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder()),
                    items: ['EDP Production', ..._suppliers].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) ctrl.text = val;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: chalanCtrl,
                    decoration: const InputDecoration(labelText: 'Delivery Chalan Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: sbContext,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (dt != null) setStateSB(() => selectedDate = dt);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Delivery Chalan Date', border: OutlineInputBorder()),
                      child: Text(selectedDate != null ? DateFormat('dd-MM-yyyy').format(selectedDate!) : 'Select Date'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  String val = ctrl.text.trim();
                  if (val.isEmpty) return;
                  
                  if (val.toLowerCase() == 'edp production' || val.toLowerCase() == 'edp') {
                    val = 'EDP';
                  }
                  
                  int? qty = int.tryParse(qtyCtrl.text);
                  
                  Navigator.pop(ctx);
                  setState(() => _isUpdating = true);
                  try {
                    if (_isAdmin && val != 'EDP' && !_suppliers.contains(val)) {
                      await ApiService().addSupplier(val);
                    }
                    await ApiService().forwardJob(
                      _currentJob.jobId, 
                      val,
                      forwardQuantity: qty,
                      deliveryChalanNumber: chalanCtrl.text.isEmpty ? null : chalanCtrl.text,
                      deliveryChalanDate: selectedDate,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Forwarded to $val!')));
                    _refresh();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    setState(() => _isUpdating = false);
                  }
                },
                child: const Text('Forward'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showConfirmDeliveryDialog() async {
    final qtyCtrl = TextEditingController();
    final inspectionCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();
    final available = (_currentJob.quantity ?? 0) - (_currentJob.deliveredQuantity ?? 0) - (_currentJob.returnedQuantity ?? 0);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (Max: $available)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inspectionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Inspection Report Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: invoiceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Invoice Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qtyStr = qtyCtrl.text.trim();
              if (qtyStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide quantity')));
                return;
              }
              final qty = int.tryParse(qtyStr);
              if (qty == null || qty <= 0 || qty > available) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
                return;
              }
              Navigator.pop(ctx);
              setState(() => _isUpdating = true);
              try {
                final val = _currentJob.customerName ?? 'Unknown';
                await ApiService().updateJobStatus(
                  _currentJob.jobId,
                  'Delivered',
                  location: val,
                  quantity: qty,
                  inspectionReportNumber: inspectionCtrl.text.trim().isEmpty ? null : inspectionCtrl.text.trim(),
                  invoiceNumber: invoiceCtrl.text.trim().isEmpty ? null : invoiceCtrl.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated to Delivered')));
                _refresh();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8E3E), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _currentJob.partNumber ?? _currentJob.customerName ?? 'Job Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isUpdating ? null : _refresh),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'General Information',
              icon: Icons.info_outline,
              children: [
                _row('Part Number', _currentJob.partNumber ?? _currentJob.customerName ?? 'N/A'),
                _row('Customer Name', _currentJob.customerName ?? 'N/A'),
                _row('Quantity', '${_currentJob.quantity ?? 0} units'),
                _row('Status', (_currentJob.jobType == 'Re-coating' && _currentJob.status == 'Created') ? 'Arrived' : _currentJob.status),
                _row('Location', _currentJob.currentLocation),
                if (_currentJob.negotiationDone != null && _currentJob.jobType != 'Re-coating')
                  _row('Negotiation', _currentJob.negotiationDone! ? 'Yes' : 'No'),
              ],
            ),

            if (_currentJob.jobType == 'New' || _currentJob.poNotGiven == true || (_currentJob.purchaseOrderNumber != null && _currentJob.purchaseOrderNumber!.isNotEmpty) || (_currentJob.edpPurchaseOrderNumber != null && _currentJob.edpPurchaseOrderNumber!.isNotEmpty) || (_currentJob.supplierPurchaseOrderNumber != null && _currentJob.supplierPurchaseOrderNumber!.isNotEmpty) || (_currentJob.deliveryChalanNumber != null && _currentJob.deliveryChalanNumber!.isNotEmpty)) ...[
              _buildSectionCard(
                title: 'Order Details',
                icon: Icons.receipt_long,
                children: [
                  if (_currentJob.jobType == 'New' && _currentJob.customerOrderDate != null)
                    _row('Order Date', DateFormat('dd-MM-yyyy').format(_currentJob.customerOrderDate!)),
                  if (_currentJob.jobType == 'New' && _currentJob.receivedDate != null)
                    _row('Blank Order Received Date', DateFormat('dd-MM-yyyy').format(_currentJob.receivedDate!)),
                  if (_currentJob.jobType == 'New' && _currentJob.productionDate != null)
                    _row('Production Date', DateFormat('dd-MM-yyyy').format(_currentJob.productionDate!)),
                  if (_currentJob.jobType == 'New' && _currentJob.expectedProductionDate != null)
                    _row('Expected Production Date', DateFormat('dd-MM-yyyy').format(_currentJob.expectedProductionDate!)),
                  if (_currentJob.poNotGiven == true)
                    _row('Purchase Order', 'Not Given')
                  else if (_currentJob.purchaseOrderNumber != null && _currentJob.purchaseOrderNumber!.isNotEmpty)
                    _row('Purchase Order', _currentJob.purchaseOrderNumber!),
                  if (_currentJob.purchaseOrderDate != null)
                    _row('Purchase Order Date', DateFormat('dd-MM-yyyy').format(_currentJob.purchaseOrderDate!)),
                  if (_currentJob.edpPurchaseOrderNumber != null && _currentJob.edpPurchaseOrderNumber!.isNotEmpty)
                    _row('EDP Purchase Order', _currentJob.edpPurchaseOrderNumber!),
                  if (_currentJob.edpPurchaseOrderDate != null)
                    _row('EDP PO Date', DateFormat('dd-MM-yyyy').format(_currentJob.edpPurchaseOrderDate!)),
                  if (_currentJob.supplierPurchaseOrderNumber != null && _currentJob.supplierPurchaseOrderNumber!.isNotEmpty)
                    _row('Supplier PO', _currentJob.supplierPurchaseOrderNumber!),
                  if (_currentJob.supplierPurchaseOrderDate != null)
                    _row('Supplier PO Date', DateFormat('dd-MM-yyyy').format(_currentJob.supplierPurchaseOrderDate!)),
                  if (_currentJob.forwardQuantity != null && _currentJob.supplierMovements.isEmpty)
                    _row('Forward Quantity', _currentJob.forwardQuantity.toString()),
                  if (_currentJob.deliveryChalanNumber != null && _currentJob.deliveryChalanNumber!.isNotEmpty && _currentJob.supplierMovements.isEmpty)
                    _row('Delivery Chalan Number', _currentJob.deliveryChalanNumber!),
                  if (_currentJob.deliveryChalanDate != null && _currentJob.supplierMovements.isEmpty)
                    _row('Delivery Chalan Date', DateFormat('dd-MM-yyyy').format(_currentJob.deliveryChalanDate!)),
                  ...(_currentJob.supplierMovements.where((m) => m['deliveryChalanNumber'] != null && m['deliveryChalanNumber'].toString().isNotEmpty).expand((m) {
                    String sender = m['senderName']?.toString() ?? 'EDP';
                    if (sender.toLowerCase() == 'edp' || sender.toLowerCase() == 'edp production') sender = 'EDP';
                    final chalan = m['deliveryChalanNumber'].toString();
                    final qty = m['forwardQuantity'];
                    final dateStr = m['deliveryChalanDate'];
                    final date = dateStr != null ? DateTime.tryParse(dateStr.toString()) : null;
                    return [
                      if (qty != null)
                        _row('$sender Forward Quantity', qty.toString()),
                      _row('$sender Delivery Chalan Number', chalan),
                      if (date != null)
                        _row('$sender Delivery Chalan Date', DateFormat('dd-MM-yyyy').format(date)),
                    ];
                  })),
                ],
              ),
              if ((_currentJob.wheelSize != null && _currentJob.wheelSize!.isNotEmpty) || 
                  (_currentJob.diamondPowderGritSize != null && _currentJob.diamondPowderGritSize!.isNotEmpty) || 
                  (_currentJob.assignedWorker != null && _currentJob.assignedWorker!.isNotEmpty))
                _buildSectionCard(
                  title: 'Specifications & Assignment',
                  icon: Icons.build_circle_outlined,
                  children: [
                    if (_currentJob.wheelSize != null && _currentJob.wheelSize!.isNotEmpty)
                      _row('Description', _currentJob.wheelSize!),
                    if (_currentJob.diamondPowderGritSize != null && _currentJob.diamondPowderGritSize!.isNotEmpty)
                      _row('Diamond Powder Grit Size', _currentJob.diamondPowderGritSize!),
                    if (_currentJob.assignedWorker != null && _currentJob.assignedWorker!.isNotEmpty)
                      _row('Person Responsible', _currentJob.assignedWorker!),
                  ],
                ),
            ],

            if (_currentJob.jobType == 'Re-coating' || _currentJob.returnableGatePassNumber != null)
              _buildSectionCard(
                title: 'Timeline & Gate Pass',
                icon: Icons.timeline,
                children: [
                  if (_currentJob.returnableGatePassNumber != null)
                    _row('Returnable Gate Pass No.', _currentJob.returnableGatePassNumber ?? 'N/A'),
                  if (_currentJob.returnableGatePassDate != null)
                    _row('Returnable Gate Pass Date', DateFormat('dd-MM-yyyy').format(_currentJob.returnableGatePassDate!)),
                  if (_currentJob.receivedDate != null)
                    _row('Received Date', DateFormat('dd-MM-yyyy').format(_currentJob.receivedDate!)),
                  if (_currentJob.extractionDate != null)
                    _row('Extraction Date', DateFormat('dd-MM-yyyy').format(_currentJob.extractionDate!)),
                  if (_currentJob.extractionCompletedDate != null)
                    _row('Extraction Completed Date', DateFormat('dd-MM-yyyy').format(_currentJob.extractionCompletedDate!)),
                  if (_currentJob.productionDate != null)
                    _row('Production Date', DateFormat('dd-MM-yyyy').format(_currentJob.productionDate!)),
                ],
              ),
            if (_currentJob.supplierMovements.isNotEmpty)
              _buildSectionCard(
                title: 'Supplier Tracking',
                icon: Icons.sync_alt,
                children: _currentJob.supplierMovements.expand<Widget>((movement) {
                  final supplierName = movement['supplierName'] ?? 'Unknown';
                  final sentDateStr = movement['sentDate'];
                  final sentDate = sentDateStr != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(sentDateStr.toString()).toLocal()) : null;
                  return [
                    if (sentDate != null)
                      _row(supplierName.toLowerCase() == 'edp' ? 'Sent to EDP Production' : 'Sent to $supplierName', sentDate),
                  ];
                }).toList(),
              ),
            if (_currentJob.expectedExtractionDate != null || _currentJob.expectedProductionDate != null)
              _buildSectionCard(
                title: 'Expected',
                icon: Icons.event,
                children: [
                  if (_currentJob.expectedExtractionDate != null)
                    _row('Expected Extraction Date', DateFormat('dd-MM-yyyy').format(_currentJob.expectedExtractionDate!)),
                  if (_currentJob.expectedProductionDate != null)
                    _row('Expected Production Date', DateFormat('dd-MM-yyyy').format(_currentJob.expectedProductionDate!)),
                ],
              ),
            if (_currentJob.status == 'Delivered' || _currentJob.status == 'Closed')
              _buildSectionCard(
                title: 'Delivery Information',
                icon: Icons.local_shipping,
                children: [
                  if (_currentJob.invoiceNumber != null && _currentJob.invoiceNumber!.isNotEmpty)
                    _row('Invoice Number', _currentJob.invoiceNumber!),
                  if (_currentJob.inspectionReportNumber != null && _currentJob.inspectionReportNumber!.isNotEmpty)
                    _row('Inspection Report', _currentJob.inspectionReportNumber!),
                  _row('Delivered Quantity', '${_currentJob.deliveredQuantity ?? 0} units'),
                ],
              ),
            if (_currentJob.jobType == 'Re-coating' && _currentJob.status == 'Created')
              _buildExtractionProcessUI(),
            if (_currentJob.jobType == 'Re-coating' && _currentJob.status == 'Extracted')
              _buildExtractionCompletedUI(),
            if ((_currentJob.jobType != 'Re-coating' || (_currentJob.status != 'Created' && _currentJob.status != 'Extracted')) && _currentJob.status != 'Delivered' && _currentJob.status != 'Closed' && _currentJob.status != 'Completed' && (_currentJob.status != 'Returned' || ((_currentJob.quantity ?? 0) - (_currentJob.deliveredQuantity ?? 0) - (_currentJob.returnedQuantity ?? 0) > 0)))
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8E3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                        label: const Text('Ready for delivery'),
                        onPressed: _isUpdating ? null : () => _updateStatus('Completed'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.forward_to_inbox),
                        label: const Text('Next Supplier'),
                        onPressed: _isUpdating ? null : _showForwardDialog,
                      ),
                    ),
                  ],
                ),
              ),
            if (_currentJob.status == 'Completed')
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8E3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.local_shipping),
                    label: const Text('Confirm Delivery'),
                    onPressed: _isUpdating ? null : _showConfirmDeliveryDialog,
                  ),
                ),
              ),
            if ((_currentJob.jobType != 'Re-coating' || (_currentJob.status != 'Created' && _currentJob.status != 'Extracted')) && ((_currentJob.status == 'Completed' && (_currentJob.quantity ?? 0) - (_currentJob.deliveredQuantity ?? 0) > 0) || (_currentJob.deliveredQuantity ?? 0) > 0))
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E24AA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.assignment_return),
                    label: const Text('Return Material'),
                    onPressed: _isUpdating ? null : _showReturnDialog,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateExtractionStatus() async {
    if (_extractionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Extraction Sent Date')));
      return;
    }
    if (_expectedExtractionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Expected Extraction Date')));
      return;
    }
    setState(() => _isUpdating = true);
    try {
      await ApiService().updateJobStatus(_currentJob.jobId, 'Extracted', extractionDate: _extractionDate, expectedExtractionDate: _expectedExtractionDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated to Extracted')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _isUpdating = false);
      }
    }
  }

  Widget _buildExtractionProcessUI() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send to Extraction Process', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (!_extractionProcessYes)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.green),
                        foregroundColor: Colors.green,
                      ),
                      onPressed: () => setState(() => _extractionProcessYes = true),
                      child: const Text('Yes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {},
                      child: const Text('No'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Extraction Sent Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _extractionDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_extractionDate == null ? 'Select Date' : DateFormat('dd-MM-yyyy').format(_extractionDate!)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Expected Extraction Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _expectedExtractionDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_expectedExtractionDate == null ? 'Select Date' : DateFormat('dd-MM-yyyy').format(_expectedExtractionDate!)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isUpdating ? null : _updateExtractionStatus,
                      child: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateExtractionCompletedStatus() async {
    if (_extractionCompletedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Extraction Completed Date')));
      return;
    }
    if (_productionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Production Date')));
      return;
    }
    if (_expectedProductionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Expected Production Date')));
      return;
    }
    setState(() => _isUpdating = true);
    try {
      // NOTE: We need to pass expectedProductionDate. But wait, updateJobStatus might not have it yet.
      // Wait, we need to make sure expectedProductionDate is available in ApiService updateJobStatus!
      // But for now let's just try to call it and if we get an error we fix it. Let's add it:
      // Oh actually, we didn't add expectedProductionDate to ApiService().updateJobStatus yet?
      // No wait, I checked earlier, I need to add expectedProductionDate to ApiService updateJobStatus. 
      // Let's do that below.
      // Assuming I'll update ApiService right after this.
      await ApiService().updateJobStatus(_currentJob.jobId, 'Production', extractionCompletedDate: _extractionCompletedDate, productionDate: _productionDate, expectedProductionDate: _expectedProductionDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated to Production')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _sendToSpare() async {
    setState(() => _isUpdating = true);
    try {
      await ApiService().createSpare(
        _currentJob.partNumber ?? '',
        _currentJob.quantity ?? 1,
        _currentJob.partDescription,
        _currentJob.diamondPowderGritSize,
        _currentJob.jobId,
        _currentJob.jobType ?? 'Re-coating',
        null,
        null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to Spare at EDP as Blank')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send to spare: $e')));
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _undoSendToSpare() async {
    setState(() => _isUpdating = true);
    try {
      await ApiService().undoSendToSpare(_currentJob.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undo Send to Spare successful')));
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to undo: $e')));
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showUseSpareDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final spares = await ApiService().getSpares();
      final finishedSpares = spares.where((s) {
        if (s['status'] != 'Finished') return false;
        
        final samePartNo = (s['partNumber'] ?? '').toString().toLowerCase().trim() == (_currentJob.partNumber ?? '').toLowerCase().trim();
        final currentDesc = (_currentJob.partDescription != null && _currentJob.partDescription!.isNotEmpty) ? _currentJob.partDescription : _currentJob.wheelSize;
        final sameDesc = (s['description'] ?? '').toString().toLowerCase().trim() == (currentDesc ?? '').toString().toLowerCase().trim();
        final sameGrit = (s['gritSize'] ?? '').toString().toLowerCase().trim() == (_currentJob.diamondPowderGritSize ?? '').toLowerCase().trim();
        
        return samePartNo && sameDesc && sameGrit;
      }).toList();
      if (!mounted) return;
      Navigator.pop(context); // hide loading

      showDialog(
        context: context,
        builder: (ctx) => _UseSpareDialog(
          finishedSpares: finishedSpares,
          onUseSpare: (spare) async {
            Navigator.pop(ctx);
            setState(() => _isUpdating = true);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ApiService().consumeSpare(spare['_id'], _currentJob.quantity ?? 1, _currentJob.jobId);
              if (mounted) {
                _refresh();
              }
              messenger.showSnackBar(const SnackBar(content: Text('Used spare successfully! Job is now complete.')));
            } catch (e) {
              if (mounted) {
                setState(() => _isUpdating = false);
              }
              messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load spares: $e')));
      }
    }
  }

  Widget _buildExtractionCompletedUI() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentJob.jobType != 'Re-coating') ...[
              const Text('Extraction Complete Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_isUpdating || _currentJob.sentToSpare)
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: (_isUpdating || _currentJob.sentToSpare) ? [] : [
                          BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.white),
                        label: const Text('Send to Spare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: (_isUpdating || _currentJob.sentToSpare) ? null : _sendToSpare,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_isUpdating || _currentJob.usedSpareId != null)
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: (_isUpdating || _currentJob.usedSpareId != null) ? [] : [
                          BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.handyman, size: 20, color: Colors.white),
                        label: const Text('Use from Spare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: (_isUpdating || _currentJob.usedSpareId != null) ? null : _showUseSpareDialog,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 1),
              ),
            ],
            if (_currentJob.jobType != 'Re-coating' && _currentJob.sentToSpare && _currentJob.usedSpareId == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('You have sent the extracted blank to Spare. You must select a finished spare to continue to Production.', style: TextStyle(color: Colors.deepOrange))),
                    if (_isUpdating)
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      TextButton(
                        onPressed: _undoSendToSpare,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Undo', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              )
            else ...[
              const Text('Continue to Production', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
            if (!_extractionCompletedYes)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.green),
                        foregroundColor: Colors.green,
                      ),
                      onPressed: () => setState(() => _extractionCompletedYes = true),
                      child: const Text('Yes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {},
                      child: const Text('No'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Enter Production Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        onPressed: () => setState(() => _extractionCompletedYes = false),
                        icon: const Icon(Icons.undo, size: 16, color: Colors.red),
                        label: const Text('Undo', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _extractionCompletedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_extractionCompletedDate == null ? 'Select Extraction Completed Date' : DateFormat('dd-MM-yyyy').format(_extractionCompletedDate!)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _productionDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_productionDate == null ? 'Select Production Date' : DateFormat('dd-MM-yyyy').format(_productionDate!)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _expectedProductionDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_expectedProductionDate == null ? 'Select Expected Production Date' : DateFormat('dd-MM-yyyy').format(_expectedProductionDate!)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isUpdating ? null : _updateExtractionCompletedStatus,
                      child: _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _UseSpareDialog extends StatefulWidget {
  final List<dynamic> finishedSpares;
  final Function(dynamic) onUseSpare;

  const _UseSpareDialog({required this.finishedSpares, required this.onUseSpare});

  @override
  State<_UseSpareDialog> createState() => _UseSpareDialogState();
}

class _UseSpareDialogState extends State<_UseSpareDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredSpares = widget.finishedSpares.where((spare) {
      final partNo = (spare['partNumber'] ?? '').toString().toLowerCase();
      final desc = (spare['description'] ?? '').toString().toLowerCase();
      final grit = (spare['gritSize'] ?? '').toString().toLowerCase();
      final qty = (spare['quantity'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return partNo.contains(q) || desc.contains(q) || grit.contains(q) || qty.contains(q);
    }).toList();

    return AlertDialog(
      title: const Text('Use from Spare', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search part no, description, grit, qty...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredSpares.isEmpty
                  ? const Center(child: Text('No spares found.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filteredSpares.length,
                      itemBuilder: (context, index) {
                        final spare = filteredSpares[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Part No: ${spare['partNumber'] ?? 'Unknown'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1976D2)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text('Qty: ${spare['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (spare['description'] != null && spare['description'].toString().isNotEmpty)
                                  Text('Desc: ${spare['description']}', style: const TextStyle(fontSize: 14)),
                                if (spare['gritSize'] != null && spare['gritSize'].toString().isNotEmpty)
                                  Text('Grit: ${spare['gritSize']}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (confirmCtx) => AlertDialog(
                                          title: const Text('Confirm Usage'),
                                          content: Text('Are you sure you want to use part ${spare['partNumber']}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(confirmCtx), child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                              onPressed: () {
                                                Navigator.pop(confirmCtx);
                                                widget.onUseSpare(spare);
                                              },
                                              child: const Text('Confirm & Use'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Text('Use this Spare', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
