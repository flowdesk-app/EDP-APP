import 'package:flutter/material.dart';

class CustomerDeliveryScreen extends StatefulWidget {
  const CustomerDeliveryScreen({super.key});

  @override
  State<CustomerDeliveryScreen> createState() => _CustomerDeliveryScreenState();
}

class _CustomerDeliveryScreenState extends State<CustomerDeliveryScreen> {
  final _customerCtrl = TextEditingController();
  final _partCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  void _deliverMaterial() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer Delivery Recorded!')));
    setState(() {
      _customerCtrl.clear();
      _partCtrl.clear();
      _qtyCtrl.clear();
      _vehicleCtrl.clear();
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Customer Delivery', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
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
                const Text('Final Dispatch to Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _customerCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Name (e.g. INEL)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _partCtrl,
                  decoration: const InputDecoration(labelText: 'Part Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _vehicleCtrl,
                  decoration: const InputDecoration(labelText: 'Vehicle Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Delivery Note Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const TextField(
                  enabled: false,
                  decoration: InputDecoration(labelText: 'Dispatch Date (Auto-filled current)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _deliverMaterial,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF29B6F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('RECORD DELIVERY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
