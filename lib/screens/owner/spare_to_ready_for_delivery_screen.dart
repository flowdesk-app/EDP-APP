import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class SpareToReadyForDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> spare;

  const SpareToReadyForDeliveryScreen({super.key, required this.spare});

  @override
  State<SpareToReadyForDeliveryScreen> createState() => _SpareToReadyForDeliveryScreenState();
}

class _SpareToReadyForDeliveryScreenState extends State<SpareToReadyForDeliveryScreen> {
  final _customerNameCtrl = TextEditingController();
  final _poNumberCtrl = TextEditingController();
  final _deliveryDateCtrl = TextEditingController();
  final _poDateCtrl = TextEditingController();
  final ApiService _api = ApiService();

  bool _poReceived = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _poNumberCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _poDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_customerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Name is required')));
      return;
    }
    if (_deliveryDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expected Delivery Date is required')));
      return;
    }
    if (_poReceived && _poNumberCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Order Number is required')));
      return;
    }
    if (_poReceived && _poDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Order Date is required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'customerName': _customerNameCtrl.text.trim(),
        'expectedDeliveryDate': _deliveryDateCtrl.text,
        'poReceived': _poReceived,
        'poNumber': _poReceived ? _poNumberCtrl.text.trim() : null,
        'poDate': _poReceived ? _poDateCtrl.text : null,
      };

      await _api.createJobFromSpareToDelivery(widget.spare['_id'], payload);
      
      if (!mounted) return;
      Navigator.pop(context, true); // Pop back with true to refresh list
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spare = widget.spare;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Move to Ready for Delivery', style: TextStyle(color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Spare Details (Read-only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Job Details (From Spare)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                      const SizedBox(height: 12),
                      _buildInfoRow('Part Number', spare['partNumber']?.toString() ?? ''),
                      _buildInfoRow('Quantity', '${spare['quantity'] ?? 1}'),
                      _buildInfoRow('Description', spare['description']?.toString() ?? ''),
                      _buildInfoRow('Grit Size', spare['gritSize']?.toString() ?? ''),
                      _buildInfoRow('Person Responsible', spare['personResponsible']?.toString() ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Inputs
                const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _deliveryDateCtrl,
                  readOnly: true,
                  onTap: () => _selectDate(_deliveryDateCtrl),
                  decoration: const InputDecoration(
                    labelText: 'Expected Delivery Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text('Purchase order received?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _poReceived = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _poReceived ? Colors.green : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('Yes', style: TextStyle(color: _poReceived ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _poReceived = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_poReceived ? Colors.red : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('No', style: TextStyle(color: !_poReceived ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_poReceived) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _poNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Order Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _poDateCtrl,
                    readOnly: true,
                    onTap: () => _selectDate(_poDateCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Purchase Order Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
      bottomNavigationBar: _isLoading ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
        ),
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
