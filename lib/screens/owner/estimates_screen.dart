import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/estimate_model.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../widgets/drawer_menu_button.dart';
import '../../widgets/global_logout_button.dart';
import '../../widgets/job_type_badge.dart';
import '../../widgets/estimate_auth_dialog.dart';
import 'estimate_calculator_screen.dart';
import '../../utils/pdf_estimate_api.dart';

class EstimatesScreen extends StatefulWidget {
  final int initialTab;

  const EstimatesScreen({super.key, this.initialTab = 0});

  @override
  State<EstimatesScreen> createState() => _EstimatesScreenState();
}

class _EstimatesScreenState extends State<EstimatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  bool _authorized = false;
  bool _loading = true;

  List<JobModel> _allJobs = [];
  List<EstimateModel> _allEstimates = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedJobTypeFilter = 'All';

  final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _checkAuthorizationAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorizationAndLoad() async {
    if (!EstimateAuthService.isUnlocked) {
      // Delay slightly so context is available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ok = await EstimateAuthService.ensureAuthorized(
          context,
          targetDescription: 'view Estimates & Price Calculations',
        );
        if (mounted) {
          setState(() {
            _authorized = ok;
          });
          if (ok) {
            _loadData();
          } else {
            setState(() => _loading = false);
          }
        }
      });
    } else {
      _authorized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final jobsFuture = _api.getFilteredJobs();
      final estimatesFuture = _api.getEstimates();

      final results = await Future.wait([jobsFuture, estimatesFuture]);
      if (mounted) {
        setState(() {
          _allJobs = results[0] as List<JobModel>;
          _allEstimates = results[1] as List<EstimateModel>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load estimates data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _showAllGranted = false; // false = only awaiting estimate, true = all granted

  // Get only granted jobs
  List<JobModel> get _grantedJobs {
    return _allJobs.where((j) {
      if (!j.accessGranted) return false;
      if (j.grantedAt == null && j.grantedBy == null) return false;
      if (j.status == 'Removed') return false;

      // Filter by Job Type
      if (_selectedJobTypeFilter != 'All' && j.jobType != _selectedJobTypeFilter) {
        return false;
      }

      // Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = j.jobId.toLowerCase().contains(q);
        final matchesPart = j.partNumber?.toLowerCase().contains(q) ?? false;
        final matchesCust = j.customerName?.toLowerCase().contains(q) ?? false;
        final matchesDesc = j.wheelSize?.toLowerCase().contains(q) ?? false;
        final matchesGrit = j.diamondPowderGritSize?.toLowerCase().contains(q) ?? false;
        if (!matchesId && !matchesPart && !matchesCust && !matchesDesc && !matchesGrit) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Jobs that do not yet have an estimate calculated
  List<JobModel> get _grantedJobsPendingEstimate {
    final estimatedJobIds = _allEstimates.map((e) => e.jobId).where((id) => id != null && id.isNotEmpty).toSet();
    return _grantedJobs.where((j) => !estimatedJobIds.contains(j.jobId)).toList();
  }

  List<JobModel> get _displayedGrantedJobs {
    return _showAllGranted ? _grantedJobs : _grantedJobsPendingEstimate;
  }

  // Get matching saved estimates
  List<EstimateModel> get _filteredEstimates {
    if (_searchQuery.isEmpty) return _allEstimates;
    final q = _searchQuery.toLowerCase();
    return _allEstimates.where((e) {
      return e.calculationNo.toLowerCase().contains(q) ||
          e.customerName.toLowerCase().contains(q) ||
          (e.itemDescription?.toLowerCase().contains(q) ?? false) ||
          (e.jobId?.toLowerCase().contains(q) ?? false) ||
          (e.drawingNo?.toLowerCase().contains(q) ?? false) ||
          (e.gritSize?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  EstimateModel? _findEstimateForJob(String jobId) {
    try {
      return _allEstimates.firstWhere((e) => e.jobId == jobId);
    } catch (_) {
      return null;
    }
  }

  void _openCalculatorForJob(JobModel job) {
    final existing = _findEstimateForJob(job.jobId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimateCalculatorScreen(
          initialJob: job,
          existingEstimate: existing,
        ),
      ),
    ).then((saved) {
      if (saved != null && mounted) {
        _tabController.animateTo(1); // Switch to Estimated Section
      }
      _loadData();
    });
  }

  void _openCalculatorForEstimate(EstimateModel estimate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimateCalculatorScreen(
          existingEstimate: estimate,
        ),
      ),
    ).then((saved) {
      if (saved != null && mounted) {
        _tabController.animateTo(1); // Switch to Estimated Section
      }
      _loadData();
    });
  }

  void _openNewCustomCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EstimateCalculatorScreen(),
      ),
    ).then((saved) {
      if (saved != null && mounted) {
        _tabController.animateTo(1); // Switch to Estimated Section
      }
      _loadData();
    });
  }

  Future<void> _deleteEstimate(EstimateModel estimate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Estimate?'),
        content: Text('Are you sure you want to delete Estimate #${estimate.calculationNo} for ${estimate.customerName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && estimate.id != null) {
      final success = await _api.deleteEstimate(estimate.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estimate deleted'), backgroundColor: Colors.red),
          );
        }
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(
          leading: const DrawerMenuButton(),
          title: const Text('Estimates & Costing', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: const [GlobalLogoutButton()],
        ),
        body: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.lock, color: Color(0xFFD97706), size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Estimates is Password Protected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This section contains proprietary pricing, cost breakdowns, and margin calculations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await EstimateAuthService.ensureAuthorized(context);
                    if (ok && mounted) {
                      setState(() => _authorized = true);
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.vpn_key, size: 18),
                  label: const Text('Enter Password (1212)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Estimates & Costing', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Re-lock section',
            icon: const Icon(Icons.lock_open, color: Color(0xFFD97706)),
            onPressed: () {
              EstimateAuthService.lock();
              setState(() => _authorized = false);
            },
          ),
          IconButton(
            tooltip: 'Refresh data',
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
          const GlobalLogoutButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0288D1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0288D1),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Granted Section (${_grantedJobsPendingEstimate.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 18),
                  const SizedBox(width: 8),
                  Text('Estimated Section (${_allEstimates.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTopFilterBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGrantedJobsTab(),
                      _buildEstimatedSectionTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0288D1),
        foregroundColor: Colors.white,
        onPressed: _openNewCustomCalculator,
        icon: const Icon(Icons.add_chart),
        label: const Text('New Custom Estimate', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTopFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by Customer, Part No, Job ID, Grit Size...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip('All'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('New'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Re-coating'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Coating'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String type) {
    final isSelected = _selectedJobTypeFilter == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedJobTypeFilter = type);
      },
      selectedColor: const Color(0xFF0288D1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  // --- TAB 1: GRANTED JOBS (THE GRANTED SECTION) ---
  Widget _buildGrantedJobsTab() {
    final jobs = _displayedGrantedJobs;

    return Column(
      children: [
        _buildGrantedJobsSubFilter(),
        Expanded(
          child: jobs.isEmpty
              ? _buildGrantedEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final estimate = _findEstimateForJob(job.jobId);
                      return _buildGrantedJobCard(job, estimate);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGrantedJobsSubFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text('Awaiting Estimate (${_grantedJobsPendingEstimate.length})'),
            selected: !_showAllGranted,
            onSelected: (val) {
              if (val) setState(() => _showAllGranted = false);
            },
            selectedColor: const Color(0xFF0288D1),
            labelStyle: TextStyle(
              color: !_showAllGranted ? Colors.white : Colors.black87,
              fontWeight: !_showAllGranted ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('All Granted (${_grantedJobs.length})'),
            selected: _showAllGranted,
            onSelected: (val) {
              if (val) setState(() => _showAllGranted = true);
            },
            selectedColor: const Color(0xFF0288D1),
            labelStyle: TextStyle(
              color: _showAllGranted ? Colors.white : Colors.black87,
              fontWeight: _showAllGranted ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrantedEmptyState() {
    if (!_showAllGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 16),
              const Text(
                'All Granted Jobs Have Been Estimated!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every granted job currently has a confirmed estimate. You can view, edit, or export them in the Estimated Section.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('Go to Estimated Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Granted Jobs Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jobs granted access by the owner appear here. You can click on any job to create its price estimate.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrantedJobCard(JobModel job, EstimateModel? estimate) {
    final hasEstimate = estimate != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasEstimate ? const Color(0xFF81C784) : const Color(0xFFE2E8F0),
          width: hasEstimate ? 1.5 : 1.0,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                JobTypeBadge(jobType: job.jobType ?? 'New'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Job #${job.jobId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const Spacer(),
                if (hasEstimate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text(
                          'Estimated: ${currencyFmt.format(estimate.qtnPrice)}',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: const Text(
                      'Awaiting Estimate',
                      style: TextStyle(color: Color(0xFFC2410C), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.customerName?.isNotEmpty == true ? job.customerName! : 'Customer Not Set',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Part Number: ${job.partNumber ?? "N/A"}${job.wheelSize != null ? " • ${job.wheelSize}" : ""}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            if (job.diamondPowderGritSize != null && job.diamondPowderGritSize!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Grit Size: ${job.diamondPowderGritSize}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0288D1), fontWeight: FontWeight.w600),
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: _buildMiniInfo('Quantity', '${job.quantity ?? 0} units')),
                Expanded(child: _buildMiniInfo('Current Status', job.status)),
                if (hasEstimate)
                  Expanded(child: _buildMiniInfo('Calc No', estimate.calculationNo)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasEstimate) ...[
                  OutlinedButton.icon(
                    onPressed: () => PdfEstimateApi.printOrShare(estimate),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0288D1),
                      side: const BorderSide(color: Color(0xFF0288D1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                ElevatedButton.icon(
                  onPressed: () => _openCalculatorForJob(job),
                  icon: Icon(hasEstimate ? Icons.edit_note : Icons.calculate, size: 18),
                  label: Text(
                    hasEstimate ? 'View / Edit Estimate' : 'Calculate Estimate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasEstimate ? const Color(0xFF2E7D32) : const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: ESTIMATED SECTION (ALL CONFIRMED ESTIMATES) ---
  Widget _buildEstimatedSectionTab() {
    final list = _filteredEstimates;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No Confirmed Estimates in Estimated Section', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              const Text('Calculate an estimate in the Granted Section and click Confirm & Save to see it listed here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Go to Granted Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final est = list[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFC8E6C9), width: 1.5),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF81C784)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 13, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Text(
                                  'Calc #${est.calculationNo}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(est.date),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (est.jobId != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Job #${est.jobId}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0288D1)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Text(
                          currencyFmt.format(est.qtnPrice),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    est.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  if (est.itemDescription != null && est.itemDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(est.itemDescription!, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildPill('Grit: ${est.gritSize ?? "N/A"}'),
                      _buildPill('Factor: ${est.factor.toStringAsFixed(2)}'),
                      _buildPill('Eff. Area: ${est.effectiveCoatingArea.toStringAsFixed(1)} sq cm'),
                      _buildPill('Diamond: ${est.diamondRequirement.toStringAsFixed(2)} cts'),
                      _buildPill('Margin: ${est.marginPercentage.toStringAsFixed(0)}%'),
                      _buildPill('Discount: ${est.discountPercentage.toStringAsFixed(0)}%'),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        est.jobId != null ? 'Linked to Job #${est.jobId}' : 'Custom Estimate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Delete estimate',
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => _deleteEstimate(est),
                          ),
                          IconButton(
                            tooltip: 'Export PDF',
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: Color(0xFF0288D1)),
                            onPressed: () => PdfEstimateApi.printOrShare(est),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () => _openCalculatorForEstimate(est),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('View / Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }
}
