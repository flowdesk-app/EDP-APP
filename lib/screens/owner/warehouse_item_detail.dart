import 'package:flutter/material.dart';

class WarehouseItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const WarehouseItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final history = (item['processHistory'] as List<dynamic>?) ?? [];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(item['itemName'] ?? 'Item Details', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Inventory Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _row('Product', item['itemName']?.toString() ?? 'N/A'),
                  _row('Delivered Quantity', '${item['quantity'] ?? 0} units'),
                  _row('Pending Quantity', '${item['pendingQuantity'] ?? 0} units'),
                  _row('Material Type', item['material']?.toString() ?? 'N/A'),
                  _row('Last Updated', _fmt(item['updatedAt']?.toString())),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Receiving History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (history.isEmpty)
               const Text('No receiving history found.', style: TextStyle(color: Colors.grey))
            else
               ...history.map((h) => _historyRow(h.toString())),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(String event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFF29B6F6), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(event, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _fmt(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
