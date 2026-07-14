import 'package:flutter/material.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import '../../models/lead_model.dart';
import 'package:intl/intl.dart';
import 'spare_at_edp_tabs_screen.dart';

enum FlowType { none, newJob, recoating }

class CreateJobScreen extends StatefulWidget {
  final String? initialCustomerName;
  final String? leadId; // Not strictly needed anymore from New Status, but kept for signature
  final VoidCallback? onNavigateToDashboard;

  const CreateJobScreen({super.key, this.initialCustomerName, this.leadId, this.onNavigateToDashboard});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  FlowType _flowType = FlowType.none;
  int _currentStep = 0;
  final ApiService _api = ApiService();

  // Shared controllers
  final _customerNameCtrl = TextEditingController();
  final _partNumberCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _wheelSizeCtrl = TextEditingController();
  final _gritSizeCtrl = TextEditingController();
  final _assignedWorkerCtrl = TextEditingController();
  DateTime? _deliveryDate;

  // New Flow specific states
  DateTime? _customerOrderDate;

  // Re-coating Flow specific states
  DateTime? _receivedDate;
  final _returnableGatePassNumberCtrl = TextEditingController();
  DateTime? _returnableGatePassDate;

  bool? _purchaseOrderReceived;
  final TextEditingController _poNumberCtrl = TextEditingController();
  DateTime? _purchaseOrderDate;

  bool _isSentToSpare = false;
  String? _createdSpareId;
  Map<String, dynamic>? _selectedSpareToUse;

  List<Map<String, dynamic>> _masterData = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerName != null) {
      _flowType = FlowType.recoating;
      _customerNameCtrl.text = widget.initialCustomerName!;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final masterData = await _api.getMasterData();
      if (mounted) {
        setState(() {
          _masterData = masterData;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  List<String> _getSuggestions(String field) {
    final jobType = _flowType == FlowType.newJob ? 'New' : 'Re-coating';
    return _masterData
        .where((m) => m['jobType'] == jobType && m['field'] == field)
        .map((m) => m['value'].toString())
        .toList();
  }

  Future<void> _showLoadingDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showSuccessPopupAndNavigate(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Success!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      if (widget.onNavigateToDashboard != null) {
        widget.onNavigateToDashboard!();
        setState(() {
          _flowType = FlowType.none;
          _currentStep = 0;
          _customerNameCtrl.clear();
          _wheelSizeCtrl.clear();
          _gritSizeCtrl.clear();
          _assignedWorkerCtrl.clear();
          _deliveryDate = null;
        });
      } else {
        Navigator.pop(context); // Go back to dashboard
      }
    }
  }

  Future<void> _createJob() async {
    if (_customerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Name is required')));
      return;
    }
    if (_wheelSizeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description is required')));
      return;
    }
    if (_gritSizeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grit Size is required')));
      return;
    }
    if (_assignedWorkerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Person Responsible is required')));
      return;
    }
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery Date is required')));
      return;
    }

    if (_partNumberCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Part Number is required')));
      return;
    }
    if (_quantityCtrl.text.trim().isEmpty || int.tryParse(_quantityCtrl.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid Quantity is required')));
      return;
    }
    
    // Additional fields for recoating
    if (_flowType == FlowType.recoating || widget.initialCustomerName != null) {
      if (_receivedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Received Date is required')));
        return;
      }
      if (_returnableGatePassNumberCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Returnable Gate Pass Number is required')));
        return;
      }
      if (_returnableGatePassDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Returnable Gate Pass Date is required')));
        return;
      }
      if (_purchaseOrderReceived == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select whether Purchase Order was received')));
        return;
      }
      if (_purchaseOrderReceived == true && (_purchaseOrderDate == null || _poNumberCtrl.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all PO fields')));
        return;
      }
    }

    _showLoadingDialog();
    try {
      final generatedJobId = 'JOB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final job = JobModel(
        jobId: generatedJobId,
        partNumber: _partNumberCtrl.text.trim(),
        quantity: int.tryParse(_quantityCtrl.text.trim()),
        jobType: widget.initialCustomerName != null ? 'New' : (_flowType == FlowType.newJob ? 'New' : 'Re-coating'),
        customerName: _customerNameCtrl.text.trim(),
        wheelSize: _wheelSizeCtrl.text.trim(),
        diamondPowderGritSize: _gritSizeCtrl.text.trim(),
        assignedWorker: _assignedWorkerCtrl.text.trim(),
        deliveryDate: _deliveryDate,
        customerOrderDate: _customerOrderDate,
        receivedDate: _receivedDate,
        negotiationDone: false,
        purchaseOrderReceived: _purchaseOrderReceived,
        purchaseOrderNumber: _poNumberCtrl.text.trim().isEmpty ? null : _poNumberCtrl.text.trim(),
        purchaseOrderDate: _purchaseOrderDate,
        poNotGiven: _purchaseOrderReceived == false,
        returnableGatePassNumber: _returnableGatePassNumberCtrl.text.trim().isEmpty ? null : _returnableGatePassNumberCtrl.text.trim(),
        returnableGatePassDate: _returnableGatePassDate,
        status: 'Created',
        currentLocation: 'EDP',
        createdDate: DateTime.now(),
        destinationType: 'Customer',
        destinationName: _customerNameCtrl.text.trim(),
      );

      await _api.createJob(job);

      if (widget.leadId != null) {
        // Update the lead to Converted
        final existingLead = LeadModel(
          id: widget.leadId!,
          customerName: widget.initialCustomerName!,
          wheelSize: _wheelSizeCtrl.text.trim(),
          diamondPowderGritSize: _gritSizeCtrl.text.trim(),
          assignedWorker: _assignedWorkerCtrl.text.trim(),
          quotationGiven: true,
          negotiationDone: false,
          outcome: 'Accepted',
          status: 'Converted',
          createdAt: DateTime.now(),
        );
        await _api.updateLead(existingLead);
      } else if (_flowType == FlowType.newJob) {
        // Create the converted lead for tracking
        final lead = LeadModel(
          id: '',
          customerName: _customerNameCtrl.text.trim(),
          wheelSize: _wheelSizeCtrl.text.trim(),
          diamondPowderGritSize: _gritSizeCtrl.text.trim(),
          assignedWorker: _assignedWorkerCtrl.text.trim(),
          quotationGiven: true,
          negotiationDone: false,
          outcome: 'Accepted',
          status: 'Converted',
          createdAt: DateTime.now(),
        );
        await _api.createLead(lead);
      }

      if (mounted) {
        _hideLoadingDialog();
        await _showSuccessPopupAndNavigate('Job Created Successfully!');
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate, Function(DateTime) onPicked) async {
    FocusScope.of(context).unfocus(); // Force dismiss keyboard/autocomplete
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Widget _buildAutocomplete(TextEditingController ctrl, String label, List<String> options, {bool enabled = true}) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (!enabled) return const Iterable<String>.empty();
        if (textEditingValue.text.isEmpty) return options;
        return options.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: enabled ? (String selection) {
        ctrl.text = selection;
      } : null,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.addListener(() {
          if (ctrl.text != textEditingController.text) {
             ctrl.text = textEditingController.text;
          }
        });
        if (textEditingController.text.isEmpty && ctrl.text.isNotEmpty) {
           textEditingController.text = ctrl.text;
        }
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (String value) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _buildInitialSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('What type of job is this?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _flowType = FlowType.newJob),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.fiber_new, size: 48, color: Colors.blue.shade700),
                          const SizedBox(height: 16),
                          Text('New', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _flowType = FlowType.recoating),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.build, size: 48, color: Colors.orange.shade700),
                          const SizedBox(height: 16),
                          Text('Re-coating', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SpareAtEdpTabsScreen()));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  border: Border.all(color: Colors.purple.shade200, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: Colors.purple.shade700),
                    const SizedBox(height: 16),
                    Text('Use from Spare', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBlankOrder() async {
    if (_customerNameCtrl.text.trim().isEmpty || _partNumberCtrl.text.trim().isEmpty || _quantityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Customer, Part Number, and Quantity')));
      return;
    }
    if (_wheelSizeCtrl.text.trim().isEmpty || _gritSizeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Description and Grit Size')));
      return;
    }
    if (_assignedWorkerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Person Responsible')));
      return;
    }
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Expected Delivery Date')));
      return;
    }
    if (!_isSentToSpare && _selectedSpareToUse == null && _customerOrderDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Blank Order Date')));
      return;
    }
    if (_purchaseOrderReceived == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select whether Purchase Order was received')));
      return;
    }
    if (_purchaseOrderReceived == true && (_purchaseOrderDate == null || _poNumberCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all PO fields')));
      return;
    }

    _showLoadingDialog();
    try {
      final generatedJobId = 'JOB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      final job = JobModel(
        jobId: generatedJobId,
        jobType: 'New',
        customerName: _customerNameCtrl.text.trim(),
        partNumber: _partNumberCtrl.text.trim(),
        quantity: int.tryParse(_quantityCtrl.text.trim()),
        wheelSize: _wheelSizeCtrl.text.trim().isEmpty ? null : _wheelSizeCtrl.text.trim(),
        diamondPowderGritSize: _gritSizeCtrl.text.trim().isEmpty ? null : _gritSizeCtrl.text.trim(),
        assignedWorker: _assignedWorkerCtrl.text.trim().isEmpty ? null : _assignedWorkerCtrl.text.trim(),
        deliveryDate: _deliveryDate,
        customerOrderDate: _customerOrderDate,
        purchaseOrderReceived: _purchaseOrderReceived,
        purchaseOrderDate: _purchaseOrderDate,
        purchaseOrderNumber: _poNumberCtrl.text.trim().isEmpty ? null : _poNumberCtrl.text.trim(),
        poNotGiven: _purchaseOrderReceived == false,
        status: 'Blank Order',
        currentLocation: 'EDP',
        createdDate: DateTime.now(),
        sentToSpare: false,
        usedSpareId: null,
      );

      await _api.createJob(job);

      if (mounted) {
        _hideLoadingDialog();
        await _showSuccessPopupAndNavigate('Job Created Successfully');
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }



  Widget _buildNewFlow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAutocomplete(_customerNameCtrl, 'Customer Name', _getSuggestions('Customer Name')),
          const SizedBox(height: 12),
          _buildAutocomplete(_partNumberCtrl, 'Part Number', _getSuggestions('Part Number')),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          _buildAutocomplete(_wheelSizeCtrl, 'Description', _getSuggestions('Description')),
          const SizedBox(height: 12),
          _buildAutocomplete(_gritSizeCtrl, 'Diamond Powder Grit Size', _getSuggestions('Grit Size')),
          const SizedBox(height: 12),
          _buildAutocomplete(_assignedWorkerCtrl, 'Person Responsible', _getSuggestions('Person Responsible')),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickDate(context, _deliveryDate, (d) => setState(() => _deliveryDate = d)),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Expected Delivery Date', border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
              child: Text(_deliveryDate != null ? DateFormat('dd-MM-yyyy').format(_deliveryDate!) : 'Select Date'),
            ),
          ),
          const SizedBox(height: 36),

          const Text('Purchase order received?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purchaseOrderReceived == true ? Colors.green.shade700 : Colors.green.shade400, 
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: _purchaseOrderReceived == true ? 4 : 0,
                ),
                onPressed: () => setState(() => _purchaseOrderReceived = true),
                child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purchaseOrderReceived == false ? Colors.red.shade700 : Colors.red.shade400, 
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: _purchaseOrderReceived == false ? 4 : 0,
                ),
                onPressed: () => setState(() => _purchaseOrderReceived = false),
                child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
            ],
          ),

          if (_purchaseOrderReceived == true) ...[
            const SizedBox(height: 24),
            const Text('Purchase Order Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: _poNumberCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true)),
            const SizedBox(height: 24),
            const Text('Purchase Order Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _purchaseOrderDate, (d) => setState(() => _purchaseOrderDate = d)),
              child: InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                child: Text(_purchaseOrderDate != null ? DateFormat('dd-MM-yyyy').format(_purchaseOrderDate!) : 'Select Date'),
              ),
            ),
          ],
          
          if (_purchaseOrderReceived != null) ...[
            const SizedBox(height: 24),
            const Text('Blank Order Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _customerOrderDate, (d) => setState(() => _customerOrderDate = d)),
              child: InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                child: Text(_customerOrderDate != null ? DateFormat('dd-MM-yyyy').format(_customerOrderDate!) : 'Select Date'),
              ),
            ),

            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createBlankOrder,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Create Job', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  List<Step> _getRecoatingSteps() {
    return [
      Step(
        title: const Text('Customer Details'),
        isActive: _currentStep >= 0,
        content: Column(
          children: [
            _buildAutocomplete(_customerNameCtrl, 'Customer Name', _getSuggestions('Customer Name')),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _receivedDate, (d) => setState(() => _receivedDate = d)),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Received Date', border: OutlineInputBorder()),
                child: Text(_receivedDate != null ? DateFormat('dd-MM-yyyy').format(_receivedDate!) : 'Select Date'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _returnableGatePassNumberCtrl,
              decoration: const InputDecoration(labelText: 'Returnable Gate Pass Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _returnableGatePassDate, (d) => setState(() => _returnableGatePassDate = d)),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Returnable Gate Pass Date', border: OutlineInputBorder()),
                child: Text(_returnableGatePassDate != null ? DateFormat('dd-MM-yyyy').format(_returnableGatePassDate!) : 'Select Date'),
              ),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Wheel Details'),
        isActive: _currentStep >= 1,
        content: Column(
          children: [
            _buildAutocomplete(_partNumberCtrl, 'Part Number', _getSuggestions('Part Number')),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _buildAutocomplete(_wheelSizeCtrl, 'Description', _getSuggestions('Description')),
            const SizedBox(height: 12),
            _buildAutocomplete(_gritSizeCtrl, 'Grit Size', _getSuggestions('Grit Size')),
          ],
        ),
      ),
      Step(
        title: const Text('Assignment & Delivery'),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            _buildAutocomplete(_assignedWorkerCtrl, 'Person Responsible', _getSuggestions('Person Responsible')),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _deliveryDate, (d) => setState(() => _deliveryDate = d)),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Delivery Date', border: OutlineInputBorder()),
                child: Text(_deliveryDate != null ? DateFormat('dd-MM-yyyy').format(_deliveryDate!) : 'Select Date'),
              ),
            ),
            const SizedBox(height: 36),

            const Text('Purchase order received?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purchaseOrderReceived == true ? Colors.green.shade700 : Colors.green.shade400, 
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: _purchaseOrderReceived == true ? 4 : 0,
                  ),
                  onPressed: () => setState(() => _purchaseOrderReceived = true),
                  child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purchaseOrderReceived == false ? Colors.red.shade700 : Colors.red.shade400, 
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: _purchaseOrderReceived == false ? 4 : 0,
                  ),
                  onPressed: () => setState(() => _purchaseOrderReceived = false),
                  child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ],
            ),

            if (_purchaseOrderReceived == true) ...[
              const SizedBox(height: 24),
              const Text('Purchase Order Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _poNumberCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true)),
              const SizedBox(height: 24),
              const Text('Purchase Order Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDate(context, _purchaseOrderDate, (d) => setState(() => _purchaseOrderDate = d)),
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                  child: Text(_purchaseOrderDate != null ? DateFormat('dd-MM-yyyy').format(_purchaseOrderDate!) : 'Select Date'),
                ),
              ),
            ],
          ],
        ),
      ),
      Step(
        title: const Text('Confirmation'),
        isActive: _currentStep >= 3,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${_customerNameCtrl.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Description: ${_wheelSizeCtrl.text} | Grit Size: ${_gritSizeCtrl.text}'),
              const SizedBox(height: 8),
              Text('Person Responsible: ${_assignedWorkerCtrl.text}'),
              const SizedBox(height: 8),
              Text('Delivery Date: ${_deliveryDate != null ? DateFormat('dd-MM-yyyy').format(_deliveryDate!) : "Not Set"}'),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
        leading: widget.initialCustomerName == null ? const DrawerMenuButton() : BackButton(color: const Color(0xFF202124)),
        title: const Text('Create Job', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_flowType != FlowType.none && widget.initialCustomerName == null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: () => setState(() {
                _flowType = FlowType.none;
                _currentStep = 0;
                _customerNameCtrl.clear();
                _wheelSizeCtrl.clear();
                _gritSizeCtrl.clear();
                _assignedWorkerCtrl.clear();
                _deliveryDate = null;
              }),
            )
        ],
      ),
      body: _flowType == FlowType.none 
        ? _buildInitialSelection()
        : _flowType == FlowType.newJob 
            ? _buildNewFlow()
            : Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep == 0) {
                    if (_customerNameCtrl.text.trim().isEmpty || _receivedDate == null || _returnableGatePassNumberCtrl.text.trim().isEmpty || _returnableGatePassDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields in this step')));
                      return;
                    }
                  } else if (_currentStep == 1) {
                    if (_partNumberCtrl.text.trim().isEmpty || _quantityCtrl.text.trim().isEmpty || _wheelSizeCtrl.text.trim().isEmpty || _gritSizeCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields in this step')));
                      return;
                    }
                  } else if (_currentStep == 2) {
                    if (_assignedWorkerCtrl.text.trim().isEmpty || _deliveryDate == null || _purchaseOrderReceived == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields in this step')));
                      return;
                    }
                    if (_purchaseOrderReceived == true && (_poNumberCtrl.text.trim().isEmpty || _purchaseOrderDate == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all PO fields')));
                      return;
                    }
                  }

                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                    _createJob();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  } else if (widget.initialCustomerName == null) {
                    setState(() => _flowType = FlowType.none);
                  } else {
                    Navigator.pop(context);
                  }
                },
                controlsBuilder: (context, details) {
                  final isLast = _currentStep == 3;
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF29B6F6),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isLast ? 'CONFIRM JOB' : 'Next'),
                        ),
                        if (_currentStep > 0 || widget.initialCustomerName != null || _flowType != FlowType.none) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ]
                      ],
                    ),
                  );
                },
                steps: _getRecoatingSteps(),
              ),
      ),
    );
  }
}
