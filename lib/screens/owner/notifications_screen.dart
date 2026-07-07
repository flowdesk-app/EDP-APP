import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/notification_model.dart';

import 'job_timeline_screen.dart';
import '../../models/job_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _filteredNotifications = [];
  List<JobModel> _allJobs = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchCtrl.addListener(_filterNotifications);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await _api.getNotifications();
      final jobs = await _api.getFilteredJobs(); // active jobs
      if (mounted) {
        setState(() {
          _allNotifications = notifs;
          _filteredNotifications = notifs;
          _allJobs = jobs;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterNotifications() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNotifications = _allNotifications;
      } else {
        _filteredNotifications = _allNotifications.where((n) {
          return n.message.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _handleTap(NotificationModel n) {
    // Try to find matching job by part number in the message
    JobModel? matchedJob;
    for (final job in _allJobs) {
      if ((job.partNumber?.isNotEmpty == true && n.message.contains(job.partNumber!)) || 
          (job.customerName?.isNotEmpty == true && n.message.contains(job.customerName!))) {
        matchedJob = job;
        break;
      }
    }
    
    if (matchedJob != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => JobTimelineScreen(job: matchedJob!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find active job for this notification.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search notifications',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                filled: true,
                fillColor: const Color(0xFFF1F3F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 56,
                              color: Color(0xFF5F6368),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No notifications found.',
                              style: TextStyle(color: Color(0xFF5F6368)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredNotifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final n = _filteredNotifications[i];
                          final isCompleted = n.type == 'completed';
                          return InkWell(
                            onTap: () => _handleTap(n),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFF1E8E3E).withValues(alpha: 0.3)
                                      : const Color(0xFFD93025).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCompleted
                                        ? Icons.check_circle_outline
                                        : Icons.warning_amber_rounded,
                                    color: isCompleted
                                        ? const Color(0xFF1E8E3E)
                                        : const Color(0xFFD93025),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.message,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')} — ${n.timestamp.day}/${n.timestamp.month}/${n.timestamp.year}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF5F6368),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
