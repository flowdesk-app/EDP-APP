import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../services/document_generation_service.dart';
import '../../utils/company_utils.dart';
import '../../utils/pdf_invoice_api.dart';
import '../../widgets/global_logout_button.dart';

class SalesOrderScreen extends StatefulWidget {
  final JobModel? initialJob;

  const SalesOrderScreen({super.key, this.initialJob});

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  bool _loading = true;
  List<JobModel> _allJobs = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      final jobs = await _api.getFilteredJobs();
      if (mounted) {
        setState(() {
          _allJobs = jobs;
          _loading = false;
        });

        // If an initial job was passed, immediately offer/show its Sale Order
        if (widget.initialJob != null) {
          final target = _allJobs.firstWhere(
            (j) => j.jobId == widget.initialJob!.jobId,
            orElse: () => widget.initialJob!,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onJobSelected(target);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load jobs: $e')),
        );
      }
    }
  }

  List<JobModel> get _grantedJobs {
    return _allJobs.where((j) => j.accessGranted == true).toList();
  }

  List<JobModel> get _availableJobs {
    return _grantedJobs.where((j) {
      final hasSo = j.salesOrderNumber != null && j.salesOrderNumber!.trim().isNotEmpty;
      if (hasSo) return false;
      if (_searchQuery.isEmpty) return true;
      return smartMatch(j.customerName, _searchQuery) ||
          smartMatch(j.jobId, _searchQuery) ||
          smartMatch(j.partNumber, _searchQuery) ||
          smartMatch(j.wheelSize, _searchQuery);
    }).toList();
  }

  List<JobModel> get _generatedJobs {
    return _grantedJobs.where((j) {
      final hasSo = j.salesOrderNumber != null && j.salesOrderNumber!.trim().isNotEmpty;
      if (!hasSo) return false;
      if (_searchQuery.isEmpty) return true;
      return smartMatch(j.customerName, _searchQuery) ||
          smartMatch(j.jobId, _searchQuery) ||
          smartMatch(j.salesOrderNumber, _searchQuery) ||
          smartMatch(j.partNumber, _searchQuery);
    }).toList();
  }

  Future<void> _onJobSelected(JobModel job) async {
    final hasSo = job.salesOrderNumber != null && job.salesOrderNumber!.trim().isNotEmpty;
    if (hasSo) {
      _viewSalesOrderPdf(job);
    } else {
      _showGenerateDialog(job);
    }
  }

  Future<void> _showGenerateDialog(JobModel job) async {
    final company = findCompanyForJob(job.customerName);
    final rateCtrl = TextEditingController(
      text: job.itemRate != null && job.itemRate! > 0 ? '${job.itemRate}' : '',
    );

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_turned_in, color: Color(0xFF1A73E8), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Auto-Generate Sale Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All company information will be automatically pulled from the official database, along with job specifications.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Customer', company?.name ?? job.customerName ?? 'N/A', isBold: true),
                    if (company != null && company.gstin.isNotEmpty)
                      _infoRow('GSTIN (Database)', company.gstin),
                    if (company != null && company.placeOfSupply.isNotEmpty)
                      _infoRow('Place of Supply', company.placeOfSupply),
                    const Divider(height: 16),
                    _infoRow('Job ID', job.jobId),
                    _infoRow('Wheel / Description', job.wheelSize ?? job.partDescription ?? job.partNumber ?? 'N/A'),
                    _infoRow('Quantity', '${job.quantity ?? 1} No(s)'),
                    if (job.purchaseOrderNumber != null && job.purchaseOrderNumber!.isNotEmpty)
                      _infoRow('PO Number', job.purchaseOrderNumber!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Rate per unit (Rs.) [Optional]',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee, size: 18),
                  helperText: 'Leave empty or 0.0 if not applicable',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Generate Now'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
      await _executeGenerateSaleOrder(job, rate: rate);
    }
  }

  Future<void> _executeGenerateSaleOrder(JobModel job, {double rate = 0.0}) async {
    final now = DateTime.now();
    final soNumber = 'SO-${job.jobId}';

    final updatedJob = job.copyWith(
      salesOrderNumber: soNumber,
      salesOrderDate: now,
      itemRate: rate > 0 ? rate : job.itemRate,
    );

    try {
      await _api.updateJob(updatedJob);

      setState(() {
        final idx = _allJobs.indexWhere((j) => j.jobId == job.jobId);
        if (idx != -1) {
          _allJobs[idx] = updatedJob;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale Order $soNumber generated successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );

        // Switch tab to Generated
        _tabController.animateTo(1);

        // Open PDF preview
        _viewSalesOrderPdf(updatedJob);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Sale Order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _viewSalesOrderPdf(JobModel job) {
    // Dynamically builds the latest Sales Order using current Job data and live Database company
    final soData = DocumentGenerationService.buildSalesOrderData(job);

    DocumentGenerationService.showPdfPreviewDialog(
      context,
      title: 'Sales Order Preview',
      documentNumber: soData.salesOrderNo,
      pdfBuilder: () => PdfInvoiceApi.generate(soData),
      onRegenerate: () async {
        await _showGenerateDialog(job);
      },
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF202124),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableJobs;
    final generated = _generatedJobs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Sale Orders', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        actions: [
          const GlobalLogoutButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF202124)),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadJobs,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by Customer, Job ID, Part No, or SO#...',
                    filled: true,
                    fillColor: const Color(0xFFF1F3F4),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0D47A1),
                unselectedLabelColor: const Color(0xFF5F6368),
                indicatorColor: const Color(0xFF0D47A1),
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions, size: 18),
                        const SizedBox(width: 8),
                        const Text('Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: available.isNotEmpty ? const Color(0xFF0D47A1) : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${available.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        const Text('Generated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: generated.isNotEmpty ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${generated.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableList(available),
                _buildGeneratedList(generated),
              ],
            ),
    );
  }

  Widget _buildAvailableList(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Available Jobs for Sale Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Once a job is granted by the owner in Approvals, it will appear here ready to auto-generate a Sale Order.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final company = findCompanyForJob(job.customerName);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          company?.name ?? job.customerName ?? 'Customer #${job.jobId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF202124)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC2E7FF)),
                        ),
                        child: Text(
                          'Job #${job.jobId}',
                          style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (job.wheelSize != null && job.wheelSize!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Wheel: ${job.wheelSize!}',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _cardInfo('Part No', job.partNumber ?? 'N/A'),
                      ),
                      Expanded(
                        child: _cardInfo('Quantity', '${job.quantity ?? 1} No(s)'),
                      ),
                      Expanded(
                        child: _cardInfo(
                          'PO Number',
                          job.purchaseOrderNumber?.isNotEmpty == true ? job.purchaseOrderNumber! : 'N/A',
                        ),
                      ),
                      Expanded(
                        child: _cardInfo(
                          'Created',
                          DateFormat('dd MMM yyyy').format(job.createdDate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showGenerateDialog(job),
                      icon: const Icon(Icons.assignment_turned_in, size: 16),
                      label: const Text('Generate Sale Order'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneratedList(List<JobModel> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Generated Sale Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sale orders generated from the Available tab or Approvals screen will be displayed here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final company = findCompanyForJob(job.customerName);
          final soNumber = job.salesOrderNumber ?? 'SO-${job.jobId}';
          final soDate = job.salesOrderDate != null
              ? DateFormat('dd MMM yyyy').format(job.salesOrderDate!)
              : 'Recent';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFC8E6C9), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF81C784)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 14, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              soNumber,
                              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('• Generated: $soDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text('Job #${job.jobId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    company?.name ?? job.customerName ?? 'Customer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF202124)),
                  ),
                  if (job.wheelSize != null && job.wheelSize!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('Wheel: ${job.wheelSize!}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      Expanded(child: _cardInfo('Part No', job.partNumber ?? 'N/A')),
                      Expanded(child: _cardInfo('Quantity', '${job.quantity ?? 1} No(s)')),
                      if (job.itemRate != null && job.itemRate! > 0)
                        Expanded(child: _cardInfo('Rate', 'Rs. ${job.itemRate!.toStringAsFixed(2)}')),
                      if (job.purchaseOrderNumber != null)
                        Expanded(child: _cardInfo('PO#', job.purchaseOrderNumber!)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),
                          side: const BorderSide(color: Color(0xFFE65100)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showGenerateDialog(job),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Regenerate'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A73E8),
                          side: const BorderSide(color: Color(0xFF1A73E8)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final soData = DocumentGenerationService.buildSalesOrderData(job);
                          final bytes = await PdfInvoiceApi.generate(soData);
                          await Printing.layoutPdf(
                            onLayout: (PdfPageFormat format) async => bytes,
                            name: '$soNumber.pdf',
                          );
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _viewSalesOrderPdf(job),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View PDF'),
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

  Widget _cardInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF202124))),
      ],
    );
  }
}
