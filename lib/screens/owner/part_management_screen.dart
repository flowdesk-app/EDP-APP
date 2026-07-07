import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PartManagementScreen extends StatefulWidget {
  const PartManagementScreen({super.key});

  @override
  State<PartManagementScreen> createState() => _PartManagementScreenState();
}

class _PartManagementScreenState extends State<PartManagementScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _masterData = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMasterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getMasterData();
      setState(() => _masterData = data);
    } catch (e) {
      debugPrint('Error loading master data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to delete this option?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _api.deleteMasterData(id);
        await _loadMasterData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSection(String jobType, String fieldTitle, String fieldKey) {
    final items = _masterData.where((m) => m['jobType'] == jobType && m['field'] == fieldKey).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Text(
            fieldTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF29B6F6)),
          ),
        ),
        ...items.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(item['value'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(item['_id']),
            ),
          ),
        )),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildTabContent(String jobType) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasAny = _masterData.any((m) => m['jobType'] == jobType);
    if (!hasAny) {
      return const Center(child: Text('No saved data yet.', style: TextStyle(color: Colors.grey, fontSize: 16)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(jobType, 'Customer Names', 'Customer Name'),
        _buildSection(jobType, 'Part Numbers', 'Part Number'),
        _buildSection(jobType, 'Descriptions', 'Description'),
        if (jobType == 'New') _buildSection(jobType, 'Diamond Powder Grit Sizes', 'Grit Size'),
        if (jobType == 'Re-coating') _buildSection(jobType, 'Grit Sizes', 'Grit Size'),
        _buildSection(jobType, 'Persons Responsible', 'Person Responsible'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Job Master', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF29B6F6),
          unselectedLabelColor: const Color(0xFF5F6368),
          indicatorColor: const Color(0xFF29B6F6),
          tabs: const [
            Tab(text: 'New Jobs'),
            Tab(text: 'Re-coating Jobs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('New'),
          _buildTabContent('Re-coating'),
        ],
      ),
    );
  }
}
