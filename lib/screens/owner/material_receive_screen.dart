import 'package:flutter/material.dart';

class MaterialReceiveScreen extends StatefulWidget {
  const MaterialReceiveScreen({super.key});

  @override
  State<MaterialReceiveScreen> createState() => _MaterialReceiveScreenState();
}

class _MaterialReceiveScreenState extends State<MaterialReceiveScreen> {
  final _jobIdCtrl = TextEditingController();
  final _receivedQtyCtrl = TextEditingController();
  final _rejectedQtyCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _selectedSupplier = 'VRS';
  final List<String> _suppliers = ['VRS', 'Sai', 'Star', 'Lak Eng', 'Veers'];

  void _receiveMaterial() async {
    // API logic will go here
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material Received Successfully!')));
    setState(() {
      _jobIdCtrl.clear();
      _receivedQtyCtrl.clear();
      _rejectedQtyCtrl.clear();
      _remarksCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Material Receive', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Receive from Supplier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _jobIdCtrl,
                  decoration: const InputDecoration(labelText: 'Job ID (Scan or Type)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code_scanner)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSupplier,
                  decoration: const InputDecoration(labelText: 'Supplier', border: OutlineInputBorder()),
                  items: _suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSupplier = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _receivedQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Received Qty', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _rejectedQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Rejected Qty', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const TextField(
                  enabled: false,
                  decoration: InputDecoration(labelText: 'Received Date (Auto-filled current)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _remarksCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Remarks / Rejection Reason', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _receiveMaterial,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF1E8E3E), // Green for receive
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('CONFIRM RECEIPT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
