import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _alerts = [];
  bool _isEditing = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notifications = await _api.getNotifications();
      setState(() => _alerts = notifications);
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSelectedAlerts() async {
    if (_selectedIds.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alerts?'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} alert(s)?'),
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
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      try {
        await _api.deleteNotifications(_selectedIds.toList());
        if (!mounted) return;
        Navigator.pop(context); // close progress
        setState(() {
          _alerts.removeWhere((a) => _selectedIds.contains(a.id));
          _isEditing = false;
          _selectedIds.clear();
        });
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // close progress
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: _isEditing 
            ? IconButton(icon: const Icon(Icons.close, color: Color(0xFF202124)), onPressed: () => setState(() { _isEditing = false; _selectedIds.clear(); }))
            : const BackButton(color: Color(0xFF202124)),
        title: Text(_isEditing ? '${_selectedIds.length} Selected' : 'All Alerts', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(
                _selectedIds.length == _alerts.length && _alerts.isNotEmpty ? Icons.deselect : Icons.select_all,
                color: const Color(0xFF202124),
              ),
              tooltip: _selectedIds.length == _alerts.length && _alerts.isNotEmpty ? 'Deselect All' : 'Select All',
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == _alerts.length && _alerts.isNotEmpty) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(_alerts.map((a) => a.id));
                  }
                });
              },
            ),
          if (_isEditing && _selectedIds.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelectedAlerts),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF202124)), onPressed: () => setState(() => _isEditing = true)),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF202124)), onPressed: _fetchAlerts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
              : _alerts.isEmpty
                  ? const Center(child: Text('No active alerts.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _selectedIds.contains(alert.id) ? const BorderSide(color: Color(0xFF29B6F6), width: 2) : const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isEditing ? () {
                              setState(() {
                                if (_selectedIds.contains(alert.id)) {
                                  _selectedIds.remove(alert.id);
                                } else {
                                  _selectedIds.add(alert.id);
                                }
                              });
                            } : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    alert.type == 'delayed' ? Icons.warning_amber_rounded : Icons.info_outline,
                                    color: alert.type == 'delayed' ? Colors.orange : Colors.blue,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(alert.message, style: const TextStyle(fontSize: 14, color: Color(0xFF202124), fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(alert.createdAt.toLocal()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
