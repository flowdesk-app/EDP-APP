import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job_model.dart';
import 'job_timeline_screen.dart';

class CalendarHistoryScreen extends StatefulWidget {
  const CalendarHistoryScreen({super.key});

  @override
  State<CalendarHistoryScreen> createState() => _CalendarHistoryScreenState();
}

class _CalendarHistoryScreenState extends State<CalendarHistoryScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  List<JobModel> _allJobs = [];
  List<JobModel> _filteredJobs = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    final jobs = await _api.getJobsForOwner();
    if (mounted) {
      setState(() {
        _allJobs = jobs;
        _loading = false;
        _filterJobs();
      });
    }
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = _allJobs.where((j) {
        final matchesDate = j.createdDate.year == _selectedDate.year &&
            j.createdDate.month == _selectedDate.month &&
            j.createdDate.day == _selectedDate.day;

        if (!matchesDate) return false;

        if (query.isEmpty) return true;

        return (j.partDescription ?? j.partNumber ?? '').toLowerCase().contains(query) ||
            (j.destinationName ?? '').toLowerCase().contains(query) ||
            (j.customerName ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF29B6F6),
            colorScheme: const ColorScheme.light(primary: Color(0xFF29B6F6)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterJobs();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = _filteredJobs.where((j) => j.status == 'Delivered').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF202124))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Color(0xFF29B6F6)),
            onPressed: _pickDate,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF202124)),
                              ),
                              const Icon(Icons.edit_calendar, color: Color(0xFF5F6368), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search jobs by product or customer',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                          filled: true,
                          fillColor: const Color(0xFFF1F3F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredJobs.length} Jobs Total',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5F6368)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$completedCount Delivered',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E8E3E)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredJobs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy, size: 56, color: Color(0xFFDADCE0)),
                              const SizedBox(height: 16),
                              Text(
                                _allJobs.isEmpty ? 'No jobs available.' : 'No jobs found for this date.',
                                style: const TextStyle(color: Color(0xFF5F6368), fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  job.partNumber ?? job.customerName ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF202124)),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF5F6368)),
                                      const SizedBox(width: 4),
                                      Text(job.customerName?.isNotEmpty == true ? '${job.wheelSize ?? ""} - ${job.diamondPowderGritSize ?? ""}' : '${job.quantity ?? 0} units', style: const TextStyle(color: Color(0xFF5F6368))),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF5F6368)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(job.customerName?.isNotEmpty == true ? 'Assigned: ${job.assignedWorker ?? "None"}' : (job.destinationName ?? ''), overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Color(0xFF5F6368))),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (job.status == 'Delivered' || job.status == 'Delivered' || job.status == 'Closed') ? Icons.check_circle : Icons.pending_actions,
                                      color: (job.status == 'Delivered' || job.status == 'Delivered' || job.status == 'Closed') ? const Color(0xFF1E8E3E) : const Color(0xFFF9AB00),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, color: Color(0xFF5F6368)),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JobTimelineScreen(job: job),
                                    ),
                                  );
                                },
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
