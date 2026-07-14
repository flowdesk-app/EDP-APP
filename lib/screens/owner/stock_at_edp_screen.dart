import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'spare_details_screen.dart';

class StockAtEdpScreen extends StatefulWidget {
  final String jobType;
  final String? supplierName;
  const StockAtEdpScreen({super.key, required this.jobType, this.supplierName});

  @override
  State<StockAtEdpScreen> createState() => _StockAtEdpScreenState();
}

class _StockAtEdpScreenState extends State<StockAtEdpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  
  List<Map<String, dynamic>> _spares = [];
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final isRecoating = widget.jobType == 'Re-coating';
    _tabController = TabController(length: isRecoating ? 4 : 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadSpares();
  }

  Future<void> _loadSpares() async {
    setState(() => _isLoading = true);
    try {
      final spares = await _api.getSpares();
      if (mounted) {
        setState(() {
          _spares = spares.where((s) {
            final jobType = s['jobType'] ?? 'Re-coating';
            final matchesJobType = jobType == widget.jobType;
            final matchesSupplier = (widget.supplierName == null) 
              ? (s['currentSupplier'] == null || s['currentSupplier'] == 'EDP')
              : (s['currentSupplier'] == widget.supplierName);
            return matchesJobType && matchesSupplier;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading spares: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _deleteSpare(String id) async {
    try {
      await _api.deleteSpare(id);
      _loadSpares();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Widget _buildSpareCard(Map<String, dynamic> spare, bool isBlank) {
    final date = spare['createdAt'] != null ? DateTime.parse(spare['createdAt']) : null;
    final cardContent = Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    spare['partNumber'] ?? 'Unknown Part',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1976D2)),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSpare(spare['_id']),
                  )
                else
                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Qty: ${spare['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (spare['description'] != null && spare['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Description: ${spare['description']}'),
              ),
            if (spare['gritSize'] != null && spare['gritSize'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Grit Size: ${spare['gritSize']}'),
              ),
            if (spare['personResponsible'] != null && spare['personResponsible'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Person Responsible: ${spare['personResponsible']}'),
              ),
            if (spare['expectedCompletionDate'] != null && spare['expectedCompletionDate'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('Expected Completion: ${spare['expectedCompletionDate']}'),
              ),
            if (spare['lastSentDate'] != null && spare['currentSupplier'] != null && spare['currentSupplier'] != 'EDP')
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Sent to ${spare['currentSupplier']} on: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(spare['lastSentDate']))}', 
                  style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
            if (date != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Added: ${DateFormat('dd-MM-yyyy').format(date)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
    
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SpareDetailsScreen(spare: spare)));
        if (result == true) {
          _loadSpares();
        }
      },
      child: cardContent,
    );
  }

  Widget _buildList(String? status) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    final filtered = _spares.where((s) {
      if (status == null) return true;
      final sStatus = s['status'] ?? 'Blank';
      return sStatus == status;
    }).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          status == null ? 'No jobs found.' : 'No $status jobs found.',
          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildSpareCard(filtered[index], status == 'Blank' || status == null);
      },
    );
  }

  void _showAddSpareDialog() {
    final parentContext = context;
    final partCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final descCtrl = TextEditingController();
    final gritCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Blank Spare'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: partCtrl, decoration: const InputDecoration(labelText: 'Part Number')),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: gritCtrl, decoration: const InputDecoration(labelText: 'Grit Size')),
              TextField(controller: personCtrl, decoration: const InputDecoration(labelText: 'Person Responsible')),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Expected Completion Date', suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (partCtrl.text.trim().isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              try {
                await _api.createSpare(partCtrl.text.trim(), qty, descCtrl.text.trim(), gritCtrl.text.trim(), null, widget.jobType, personCtrl.text.trim(), dateCtrl.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadSpares();
              } catch (e) {
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Confirm'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSupplier = widget.supplierName != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isEditing)
                  IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true))
                else
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditing = false)),
              ],
            ),
          ),
          if (!isSupplier)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF29B6F6),
                unselectedLabelColor: const Color(0xFF5F6368),
                indicatorColor: const Color(0xFF29B6F6),
                tabs: widget.jobType == 'Re-coating' ? const [
                  Tab(text: 'Finished'),
                  Tab(text: 'Production'),
                  Tab(text: 'Extraction'),
                  Tab(text: 'Blank'),
                ] : const [
                  Tab(text: 'Finished'),
                  Tab(text: 'Blank'),
                ],
              ),
            ),
          Expanded(
            child: isSupplier
                ? _buildList(null)
                : TabBarView(
                    controller: _tabController,
                    children: widget.jobType == 'Re-coating' ? [
                      _buildList('Finished'),
                      _buildList('Production'),
                      _buildList('Extraction'),
                      _buildList('Blank'),
                    ] : [
                      _buildList('Finished'),
                      _buildList('Blank'),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: (isSupplier || (_tabController.index == (widget.jobType == 'Re-coating' ? 3 : 1))) ? FloatingActionButton.extended(
        onPressed: _showAddSpareDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Job'),
        backgroundColor: const Color(0xFF29B6F6),
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}
