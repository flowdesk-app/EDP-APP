import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class SpareToExtractionScreen extends StatefulWidget {
  final Map<String, dynamic> spare;

  const SpareToExtractionScreen({super.key, required this.spare});

  @override
  State<SpareToExtractionScreen> createState() => _SpareToExtractionScreenState();
}

class _SpareToExtractionScreenState extends State<SpareToExtractionScreen> {
  final _extractionSentDateCtrl = TextEditingController();
  final _expectedExtractionDateCtrl = TextEditingController();
  final ApiService _api = ApiService();

  bool _isLoading = false;

  @override
  void dispose() {
    _extractionSentDateCtrl.dispose();
    _expectedExtractionDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_extractionSentDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extraction Sent Date is required')));
      return;
    }
    if (_expectedExtractionDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expected Extraction Date is required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'extractionSentDate': _extractionSentDateCtrl.text,
        'expectedExtractionDate': _expectedExtractionDateCtrl.text,
      };

      await _api.updateSpareToExtraction(widget.spare['_id'], payload);
      
      if (!mounted) return;
      Navigator.pop(context, true);
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
        title: const Text('Move to Extraction', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Job Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Divider(height: 32),
                        _buildInfoRow('Part Number', spare['partNumber']?.toString() ?? ''),
                        _buildInfoRow('Quantity', '${spare['quantity'] ?? 1}'),
                        _buildInfoRow('Description', spare['description']?.toString() ?? ''),
                        _buildInfoRow('Grit Size', spare['gritSize']?.toString() ?? ''),
                        _buildInfoRow('Person Responsible', spare['personResponsible']?.toString() ?? ''),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text('Extraction Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: _extractionSentDateCtrl,
                  readOnly: true,
                  onTap: () => _selectDate(_extractionSentDateCtrl),
                  decoration: const InputDecoration(
                    labelText: 'Extraction Sent Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _expectedExtractionDateCtrl,
                  readOnly: true,
                  onTap: () => _selectDate(_expectedExtractionDateCtrl),
                  decoration: const InputDecoration(
                    labelText: 'Expected Extraction Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
