import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/bin_box_balance_model.dart';
import '../../models/bin_box_return_model.dart';
import '../../widgets/drawer_menu_button.dart';

class BinBoxScreen extends StatefulWidget {
  const BinBoxScreen({super.key});

  @override
  State<BinBoxScreen> createState() => _BinBoxScreenState();
}

class _BinBoxScreenState extends State<BinBoxScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _errorMessage;
  
  bool _isEditing = false;
  List<BinBoxBalance> _balances = [];
  List<BinBoxReturn> _history = [];
  
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _loadData();
  }

  void _generateMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('MMMM yyyy').format(m));
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (_isEditing) {
        final history = await _api.getBinBoxHistory(month: _selectedMonth);
        if (mounted) setState(() => _history = history);
      } else {
        final balances = await _api.getBinBoxBalances();
        if (mounted) setState(() => _balances = balances);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showReturnDialog(BinBoxBalance balance) {
    final binCtrl = TextEditingController();
    final boxCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Return items: ${balance.destinationName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amounts returned from this destination:'),
            const SizedBox(height: 16),
            TextField(
              controller: binCtrl,
              decoration: const InputDecoration(labelText: 'Returned Bins', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: boxCtrl,
              decoration: const InputDecoration(labelText: 'Returned Boxes', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final bins = int.tryParse(binCtrl.text.trim()) ?? 0;
              final boxes = int.tryParse(boxCtrl.text.trim()) ?? 0;

              if (bins == 0 && boxes == 0) {
                Navigator.pop(ctx);
                return;
              }

              Navigator.pop(ctx);
              setState(() => _loading = true);
              try {
                await _api.returnBinBox(balance.destinationName, bins, boxes);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Returns logged successfully!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  setState(() => _loading = false);
                }
              }
            },
            child: const Text('Submit Return'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReturn(BinBoxReturn h) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Return?'),
        content: const Text('Are you sure you want to delete this return record? Your active balances will be automatically fixed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _api.deleteBinBoxReturn(h.id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildHistoryList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter by Month:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButton<String>(
                value: _selectedMonth,
                items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedMonth) {
                    setState(() => _selectedMonth = val);
                    _loadData();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _history.isEmpty
              ? const Center(child: Text('No return history for this month.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _history.length,
                    itemBuilder: (ctx, index) {
                      final h = _history[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(h.destinationName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Returned: ${h.returnedBins} Bins, ${h.returnedBoxes} Boxes\n${DateFormat('dd MMM yyyy, hh:mm a').format(h.date)}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReturn(h),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBalancesList() {
    if (_balances.isEmpty) return const Center(child: Text('No balances found.', style: TextStyle(color: Colors.grey)));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _balances.length,
        itemBuilder: (ctx, index) {
          final b = _balances[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          b.destinationName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showReturnDialog(b),
                        icon: const Icon(Icons.keyboard_return, size: 18),
                        label: const Text('Return'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE3F2FD),
                          foregroundColor: const Color(0xFF1976D2),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(label: 'Net Bins', value: b.netBins, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(label: 'Net Boxes', value: b.netBoxes, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Total Sent: ${b.totalSentBins} Bins, ${b.totalSentBoxes} Boxes',
                    style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Returned: ${b.totalReturnedBins} Bins, ${b.totalReturnedBoxes} Boxes',
                    style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: Text(_isEditing ? 'Return History' : 'Bins & Boxes', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: const Color(0xFF202124)),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF202124)),
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _isEditing
                  ? _buildHistoryList()
                  : _buildBalancesList(),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final MaterialColor color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(color: color.shade900, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
