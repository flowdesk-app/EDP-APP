import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../widgets/job_type_badge.dart';

class OwnerEditJobDialog extends StatefulWidget {
  final JobModel job;
  final bool isPendingAccess;

  const OwnerEditJobDialog({
    super.key,
    required this.job,
    this.isPendingAccess = true,
  });

  static Future<bool?> show(BuildContext context, JobModel job, {bool isPendingAccess = true}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OwnerEditJobDialog(
        job: job,
        isPendingAccess: isPendingAccess,
      ),
    );
  }

  @override
  State<OwnerEditJobDialog> createState() => _OwnerEditJobDialogState();
}

class _OwnerEditJobDialogState extends State<OwnerEditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _saving = false;

  // Controllers for typed / non-autofilled fields
  late TextEditingController _quantityCtrl;
  late TextEditingController _numberOfSetsCtrl;
  late TextEditingController _assignedWorkerCtrl;
  late TextEditingController _gritSizeCtrl;
  late TextEditingController _poNumberCtrl;
  late TextEditingController _gatePassNumberCtrl;

  // Lapping specific controllers
  late TextEditingController _syringeQtyCtrl;
  late TextEditingController _micronSizeCtrl;
  late TextEditingController _micronColorCtrl;
  late TextEditingController _micronsCtrl;

  // State variables
  late bool _isAssembly;
  late bool _poReceived;
  String? _baseType;
  String? _concentration;

  // Dates
  DateTime? _deliveryDate;
  DateTime? _customerOrderDate;
  DateTime? _receivedDate;
  DateTime? _purchaseOrderDate;
  DateTime? _gatePassDate;

  @override
  void initState() {
    super.initState();
    final j = widget.job;

    _quantityCtrl = TextEditingController(text: j.quantity?.toString() ?? '');
    _isAssembly = j.isAssembly || (j.numberOfSets != null && j.numberOfSets! > 0);
    _numberOfSetsCtrl = TextEditingController(text: j.numberOfSets?.toString() ?? '');
    _assignedWorkerCtrl = TextEditingController(text: j.assignedWorker ?? '');
    _gritSizeCtrl = TextEditingController(text: j.diamondPowderGritSize ?? '');

    final po = j.purchaseOrderNumber ?? j.edpPurchaseOrderNumber ?? '';
    _poNumberCtrl = TextEditingController(text: po);
    _poReceived = j.purchaseOrderReceived ?? (po.isNotEmpty);

    _gatePassNumberCtrl = TextEditingController(text: j.returnableGatePassNumber ?? '');

    // Lapping
    _syringeQtyCtrl = TextEditingController(text: j.syringeQuantity?.toString() ?? '');
    _micronSizeCtrl = TextEditingController(text: j.micronSize ?? '');
    _micronColorCtrl = TextEditingController(text: j.micronColor ?? '');
    _micronsCtrl = TextEditingController(text: j.microns ?? '');
    _baseType = j.baseType;
    if (j.highConcentration == 'Yes') {
      _concentration = 'High';
    } else if (j.standardConcentration == 'Yes') {
      _concentration = 'Standard';
    }

    _deliveryDate = j.deliveryDate;
    _customerOrderDate = j.customerOrderDate;
    _receivedDate = j.receivedDate;
    _purchaseOrderDate = j.purchaseOrderDate ?? j.edpPurchaseOrderDate;
    _gatePassDate = j.returnableGatePassDate;
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _numberOfSetsCtrl.dispose();
    _assignedWorkerCtrl.dispose();
    _gritSizeCtrl.dispose();
    _poNumberCtrl.dispose();
    _gatePassNumberCtrl.dispose();
    _syringeQtyCtrl.dispose();
    _micronSizeCtrl.dispose();
    _micronColorCtrl.dispose();
    _micronsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String title, DateTime? current, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  JobModel _buildUpdatedJob() {
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? widget.job.quantity;
    final sets = _isAssembly ? int.tryParse(_numberOfSetsCtrl.text.trim()) : null;
    final poNum = _poNumberCtrl.text.trim().isEmpty ? null : _poNumberCtrl.text.trim();
    final gpNum = _gatePassNumberCtrl.text.trim().isEmpty ? null : _gatePassNumberCtrl.text.trim();
    final worker = _assignedWorkerCtrl.text.trim().isEmpty ? null : _assignedWorkerCtrl.text.trim();
    final grit = _gritSizeCtrl.text.trim().isEmpty ? null : _gritSizeCtrl.text.trim();

    return widget.job.copyWith(
      quantity: qty,
      isAssembly: _isAssembly,
      numberOfSets: sets,
      assignedWorker: worker,
      diamondPowderGritSize: grit,
      deliveryDate: _deliveryDate,
      customerOrderDate: _customerOrderDate,
      receivedDate: _receivedDate,
      purchaseOrderReceived: _poReceived,
      purchaseOrderNumber: poNum,
      purchaseOrderDate: _purchaseOrderDate,
      edpPurchaseOrderNumber: widget.job.jobType == 'New' ? poNum : widget.job.edpPurchaseOrderNumber,
      edpPurchaseOrderDate: widget.job.jobType == 'New' ? _purchaseOrderDate : widget.job.edpPurchaseOrderDate,
      poNotGiven: !_poReceived,
      returnableGatePassNumber: gpNum,
      returnableGatePassDate: _gatePassDate,
      // Lapping
      syringeQuantity: int.tryParse(_syringeQtyCtrl.text.trim()),
      baseType: _baseType,
      micronSize: _micronSizeCtrl.text.trim().isEmpty ? null : _micronSizeCtrl.text.trim(),
      micronColor: _micronColorCtrl.text.trim().isEmpty ? null : _micronColorCtrl.text.trim(),
      microns: _micronsCtrl.text.trim().isEmpty ? null : _micronsCtrl.text.trim(),
      highConcentration: _concentration == 'High' ? 'Yes' : (_concentration != null ? 'No' : null),
      standardConcentration: _concentration == 'Standard' ? 'Yes' : (_concentration != null ? 'No' : null),
    );
  }

  Future<void> _handleSave({bool andGrant = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_isAssembly) {
      final sets = int.tryParse(_numberOfSetsCtrl.text.trim());
      if (sets == null || sets <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Number of Sets for Assembly.')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final updatedJob = _buildUpdatedJob();
      await _api.updateJob(updatedJob);

      if (andGrant) {
        await _api.grantJobAccess(updatedJob.jobId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job #${widget.job.jobId} updated & access granted!'),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job #${widget.job.jobId} updated successfully.'),
              backgroundColor: const Color(0xFF1976D2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final isLapping = j.jobType == 'Lapping Compound';
    final isNew = j.jobType == 'New';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note, color: Color(0xFF1976D2), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Edit Job #${j.jobId}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                            ),
                            const SizedBox(width: 10),
                            JobTypeBadge(jobType: j.jobType ?? 'New'),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Modify non-autofilled job specifications before granting access',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Scrollable Form Body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Autofilled Read-only Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: Color(0xFF5F6368)),
                                SizedBox(width: 6),
                                Text(
                                  'Autofilled from Database (Locked)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5F6368)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 24,
                              runSpacing: 8,
                              children: [
                                _buildReadOnlyItem('Customer Name', j.customerName ?? 'N/A'),
                                _buildReadOnlyItem('Part Number', j.partNumber ?? 'N/A'),
                                _buildReadOnlyItem('Description / Wheel Size', j.wheelSize ?? j.partDescription ?? 'N/A'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 1: Quantity & Assembly
                      _buildSectionTitle('Quantity & Assembly'),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Quantity *',
                                prefixIcon: Icon(Icons.format_list_numbered, size: 20),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Quantity is required';
                                if (int.tryParse(val.trim()) == null || int.parse(val.trim()) <= 0) {
                                  return 'Enter a valid positive number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _isAssembly,
                                    onChanged: (val) => setState(() => _isAssembly = val ?? false),
                                  ),
                                  const Text('Include Assembly?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isAssembly) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _numberOfSetsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Number of Sets (Assembly) *',
                            prefixIcon: Icon(Icons.layers, size: 20),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (_isAssembly) {
                              if (val == null || val.trim().isEmpty) return 'Number of sets is required';
                              if (int.tryParse(val.trim()) == null || int.parse(val.trim()) <= 0) {
                                return 'Enter a valid positive number';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Section 2: Person Responsible & Technical Specs
                      _buildSectionTitle('Personnel & Specifications'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _assignedWorkerCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Person Responsible (Operator)',
                                prefixIcon: Icon(Icons.person_outline, size: 20),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _gritSizeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Diamond Powder Grit Size',
                                prefixIcon: Icon(Icons.grain, size: 20),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Schedule & Dates
                      _buildSectionTitle('Schedules & Important Dates'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerTile(
                              label: 'Expected Delivery Date',
                              date: _deliveryDate,
                              icon: Icons.local_shipping_outlined,
                              onTap: () => _pickDate('Expected Delivery Date', _deliveryDate, (d) => _deliveryDate = d),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: isNew
                                ? _buildDatePickerTile(
                                    label: 'Customer Order Date',
                                    date: _customerOrderDate,
                                    icon: Icons.calendar_today_outlined,
                                    onTap: () => _pickDate('Customer Order Date', _customerOrderDate, (d) => _customerOrderDate = d),
                                  )
                                : _buildDatePickerTile(
                                    label: 'Received Date',
                                    date: _receivedDate,
                                    icon: Icons.move_to_inbox_outlined,
                                    onTap: () => _pickDate('Received Date', _receivedDate, (d) => _receivedDate = d),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 4: Commercial & PO Details
                      _buildSectionTitle('Purchase Order (PO) Details'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _poReceived,
                                    onChanged: (val) => setState(() => _poReceived = val ?? false),
                                  ),
                                  const Text('PO Received?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _poNumberCtrl,
                              enabled: _poReceived,
                              decoration: InputDecoration(
                                labelText: 'PO Number',
                                prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
                                border: const OutlineInputBorder(),
                                filled: !_poReceived,
                                fillColor: !_poReceived ? Colors.grey.shade100 : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_poReceived) ...[
                        const SizedBox(height: 12),
                        _buildDatePickerTile(
                          label: 'PO Date',
                          date: _purchaseOrderDate,
                          icon: Icons.date_range_outlined,
                          onTap: () => _pickDate('PO Date', _purchaseOrderDate, (d) => _purchaseOrderDate = d),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Section 5: Returnable Gate Pass (if Re-coating/Coating)
                      if (!isNew) ...[
                        _buildSectionTitle('Returnable Gate Pass Details'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _gatePassNumberCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Returnable Gate Pass No.',
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDatePickerTile(
                                label: 'Gate Pass Date',
                                date: _gatePassDate,
                                icon: Icons.event_note_outlined,
                                onTap: () => _pickDate('Gate Pass Date', _gatePassDate, (d) => _gatePassDate = d),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Section 6: Lapping Compound Specifications
                      if (isLapping) ...[
                        _buildSectionTitle('Lapping Compound Parameters'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _syringeQtyCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Syringe Quantity / Weight',
                                  prefixIcon: Icon(Icons.colorize_outlined, size: 20),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _baseType,
                                decoration: const InputDecoration(
                                  labelText: 'Base Type',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Petroleum Jelly', child: Text('Petroleum Jelly')),
                                  DropdownMenuItem(value: 'Grease', child: Text('Grease')),
                                  DropdownMenuItem(value: 'Oil Base', child: Text('Oil Base')),
                                  DropdownMenuItem(value: 'Water Base', child: Text('Water Base')),
                                ],
                                onChanged: (val) => setState(() => _baseType = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _micronSizeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Micron Size',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _concentration,
                                decoration: const InputDecoration(
                                  labelText: 'Concentration',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'High', child: Text('High')),
                                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                ],
                                onChanged: (val) => setState(() => _concentration = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _micronColorCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Micron Colour',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _micronsCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Microns',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _handleSave(andGrant: false),
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Changes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                  if (widget.isPendingAccess) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : () => _handleSave(andGrant: true),
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.verified, size: 18),
                      label: const Text('Save & Grant Access'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
    );
  }

  Widget _buildReadOnlyItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202124))),
      ],
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date',
              style: TextStyle(
                fontSize: 14,
                color: date != null ? const Color(0xFF202124) : Colors.grey.shade600,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
