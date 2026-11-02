import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/estimate_model.dart';
import '../../models/job_model.dart';
import '../../services/api_service.dart';
import '../../utils/estimate_calculator.dart';
import '../../utils/pdf_estimate_api.dart';
import '../../utils/positive_number_formatter.dart';

class EstimateCalculatorScreen extends StatefulWidget {
  final JobModel? initialJob;
  final EstimateModel? existingEstimate;

  const EstimateCalculatorScreen({
    super.key,
    this.initialJob,
    this.existingEstimate,
  });

  @override
  State<EstimateCalculatorScreen> createState() => _EstimateCalculatorScreenState();
}

class _EstimateCalculatorScreenState extends State<EstimateCalculatorScreen> {
  final ApiService _api = ApiService();
  bool _saving = false;

  late TextEditingController _calcNoCtrl;
  late DateTime _date;
  late TextEditingController _customerNameCtrl;
  late TextEditingController _itemDescCtrl;
  late TextEditingController _drawingNoCtrl;
  late String _type; // 'N', 'R', 'C'
  late TextEditingController _notesCtrl;

  // Diamond & Coating
  late TextEditingController _areaCtrl;
  String _selectedGrit = '30/40';
  late TextEditingController _factorCtrl;
  late TextEditingController _diamondRateCtrl;

  // Operational costs
  late TextEditingController _blankCostCtrl;
  late TextEditingController _grindingCostCtrl;
  late TextEditingController _extractionCostCtrl;
  late TextEditingController _balancingCostCtrl;
  late TextEditingController _transportationCostCtrl;

  // Margin & Process
  double _marginPercentage = 25.0; // default 25%
  late TextEditingController _marginCtrl;
  late TextEditingController _processCostCtrl;

  // Discount & QTN
  double _discountProvisionPercentage = 15.0; // default 15%
  late TextEditingController _discountProvisionCtrl;
  late TextEditingController _discountPercentageCtrl;
  late TextEditingController _qtnPriceCtrl;
  bool _customQtnPriceOverridden = false;

  late TextEditingController _minOrderQtyCtrl;
  late TextEditingController _deliveryCtrl;
  late TextEditingController _qtnNoDateCtrl;

  // Live Calculated Values
  double _diamondRequirement = 0.0;
  double _diamondCost = 0.0;
  double _directCostSum = 0.0;
  double _subTotalInclMargin = 0.0;
  double _totalCost = 0.0;
  double _provisionForDiscount = 0.0;
  double _suggestedQtnPrice = 0.0;

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);
  final shortCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initControllers();
    _recalculate(syncQtnPrice: true);
  }

  void _initControllers() {
    final est = widget.existingEstimate;
    final job = widget.initialJob;

    final initialCalcNo = est?.calculationNo ?? '00000112';
    _calcNoCtrl = TextEditingController(text: initialCalcNo);
    _date = est?.date ?? DateTime.now();

    final customer = est?.customerName ?? job?.customerName ?? '';
    _customerNameCtrl = TextEditingController(text: customer);

    String desc = est?.itemDescription ?? '';
    if (desc.isEmpty && job != null) {
      final parts = <String>[];
      if (job.partNumber != null) parts.add(job.partNumber!);
      if (job.wheelSize != null && job.wheelSize!.isNotEmpty) parts.add(job.wheelSize!);
      if (job.diamondPowderGritSize != null && job.diamondPowderGritSize!.isNotEmpty) {
        parts.add('Grit ${job.diamondPowderGritSize}');
      }
      desc = parts.join(' - ');
    }
    _itemDescCtrl = TextEditingController(text: desc);

    _drawingNoCtrl = TextEditingController(text: est?.drawingNo ?? '');

    String initType = est?.type ?? 'N';
    if (est == null && job != null) {
      if (job.jobType == 'Re-coating') {
        initType = 'R';
      } else if (job.jobType == 'Coating') {
        initType = 'C';
      } else {
        initType = 'N';
      }
    }
    _type = initType;

    _notesCtrl = TextEditingController(text: est?.calculationsNotes ?? '');

    // Area
    _areaCtrl = TextEditingController(text: est != null ? est.effectiveCoatingArea.toString() : '535.86');

    // Grit
    String detectedGrit = '30/40';
    if (est?.gritSize != null && est!.gritSize!.isNotEmpty) {
      detectedGrit = est.gritSize!;
    } else if (job?.diamondPowderGritSize != null) {
      final d = EstimateCalculator.detectGritSize(job!.diamondPowderGritSize);
      if (d != null) detectedGrit = d;
    }
    _selectedGrit = detectedGrit;

    final initialFactor = est?.factor ?? EstimateCalculator.getFactorForGrit(_selectedGrit);
    _factorCtrl = TextEditingController(text: initialFactor.toStringAsFixed(2));

    _diamondRateCtrl = TextEditingController(text: (est?.diamondRate ?? 25.0).toStringAsFixed(2));

    // Operational costs
    _blankCostCtrl = TextEditingController(text: (est?.blankCost ?? (_type == 'N' ? 30000.0 : 0.0)).toStringAsFixed(0));
    _grindingCostCtrl = TextEditingController(text: (est?.grindingCost ?? 0.0).toStringAsFixed(0));
    _extractionCostCtrl = TextEditingController(text: (est?.extractionCost ?? 0.0).toStringAsFixed(0));
    _balancingCostCtrl = TextEditingController(text: (est?.balancingCost ?? 3000.0).toStringAsFixed(0));
    _transportationCostCtrl = TextEditingController(text: (est?.transportationCost ?? 1000.0).toStringAsFixed(0));

    // Margins
    _marginPercentage = est?.marginPercentage ?? 25.0;
    _marginCtrl = TextEditingController(text: _marginPercentage.toStringAsFixed(0));
    _processCostCtrl = TextEditingController(text: (est?.processCost ?? 5000.0).toStringAsFixed(0));

    // Discounts
    _discountProvisionPercentage = est?.discountProvisionPercentage ?? 15.0;
    _discountProvisionCtrl = TextEditingController(text: _discountProvisionPercentage.toStringAsFixed(0));
    _discountPercentageCtrl = TextEditingController(text: (est?.discountPercentage ?? 10.0).toStringAsFixed(0));

    final initQtn = est?.qtnPrice ?? 0.0;
    _qtnPriceCtrl = TextEditingController(text: initQtn > 0 ? initQtn.toStringAsFixed(0) : '');
    _customQtnPriceOverridden = est != null && est.qtnPrice > 0;

    _minOrderQtyCtrl = TextEditingController(text: est?.minOrderQty ?? '1 set');
    _deliveryCtrl = TextEditingController(text: est?.delivery ?? '4 - 6 Weeks');
    _qtnNoDateCtrl = TextEditingController(text: est?.qtnNoAndDate ?? '');
  }

  @override
  void dispose() {
    _calcNoCtrl.dispose();
    _customerNameCtrl.dispose();
    _itemDescCtrl.dispose();
    _drawingNoCtrl.dispose();
    _notesCtrl.dispose();
    _areaCtrl.dispose();
    _factorCtrl.dispose();
    _diamondRateCtrl.dispose();
    _blankCostCtrl.dispose();
    _grindingCostCtrl.dispose();
    _extractionCostCtrl.dispose();
    _balancingCostCtrl.dispose();
    _transportationCostCtrl.dispose();
    _marginCtrl.dispose();
    _processCostCtrl.dispose();
    _discountProvisionCtrl.dispose();
    _discountPercentageCtrl.dispose();
    _qtnPriceCtrl.dispose();
    _minOrderQtyCtrl.dispose();
    _deliveryCtrl.dispose();
    _qtnNoDateCtrl.dispose();
    super.dispose();
  }

  void _onGritChanged(String newGrit) {
    setState(() {
      _selectedGrit = newGrit;
      final factor = EstimateCalculator.getFactorForGrit(newGrit);
      _factorCtrl.text = factor.toStringAsFixed(2);
      _recalculate(syncQtnPrice: true);
    });
  }

  void _recalculate({bool syncQtnPrice = false}) {
    final area = double.tryParse(_areaCtrl.text.trim()) ?? 0.0;
    final factor = double.tryParse(_factorCtrl.text.trim()) ?? EstimateCalculator.getFactorForGrit(_selectedGrit);
    final rate = double.tryParse(_diamondRateCtrl.text.trim()) ?? 25.0;

    _diamondRequirement = EstimateCalculator.calculateDiamondRequirement(area, factor);
    _diamondCost = EstimateCalculator.calculateDiamondCost(_diamondRequirement, rate);

    final blank = double.tryParse(_blankCostCtrl.text.trim()) ?? 0.0;
    final grinding = double.tryParse(_grindingCostCtrl.text.trim()) ?? 0.0;
    final extraction = double.tryParse(_extractionCostCtrl.text.trim()) ?? 0.0;
    final balancing = double.tryParse(_balancingCostCtrl.text.trim()) ?? 0.0;
    final transport = double.tryParse(_transportationCostCtrl.text.trim()) ?? 0.0;

    _directCostSum = EstimateCalculator.calculateDirectCosts(
      diamondCost: _diamondCost,
      blankCost: blank,
      grindingCost: grinding,
      extractionCost: extraction,
      balancingCost: balancing,
      transportationCost: transport,
    );

    _marginPercentage = 25.0; // Fixed at 25%
    _marginCtrl.text = '25';
    _subTotalInclMargin = EstimateCalculator.calculateSubTotalInclMargin(_directCostSum, _marginPercentage);

    final process = double.tryParse(_processCostCtrl.text.trim()) ?? 0.0;
    _totalCost = EstimateCalculator.calculateTotal(_subTotalInclMargin, process);

    _discountProvisionPercentage = 15.0; // Fixed at 15%
    _discountProvisionCtrl.text = '15';
    _provisionForDiscount = EstimateCalculator.calculateProvisionForDiscount(_totalCost, _discountProvisionPercentage);

    _suggestedQtnPrice = EstimateCalculator.roundQtnPrice(_provisionForDiscount);

    if (syncQtnPrice || !_customQtnPriceOverridden) {
      _qtnPriceCtrl.text = _suggestedQtnPrice.toStringAsFixed(0);
    }

    setState(() {});
  }

  EstimateModel _buildCurrentEstimate() {
    final area = double.tryParse(_areaCtrl.text.trim()) ?? 0.0;
    final factor = double.tryParse(_factorCtrl.text.trim()) ?? EstimateCalculator.getFactorForGrit(_selectedGrit);
    final rate = double.tryParse(_diamondRateCtrl.text.trim()) ?? 25.0;
    final blank = double.tryParse(_blankCostCtrl.text.trim()) ?? 0.0;
    final grinding = double.tryParse(_grindingCostCtrl.text.trim()) ?? 0.0;
    final extraction = double.tryParse(_extractionCostCtrl.text.trim()) ?? 0.0;
    final balancing = double.tryParse(_balancingCostCtrl.text.trim()) ?? 0.0;
    final transport = double.tryParse(_transportationCostCtrl.text.trim()) ?? 0.0;
    final process = double.tryParse(_processCostCtrl.text.trim()) ?? 0.0;
    final discount = double.tryParse(_discountPercentageCtrl.text.trim()) ?? 10.0;
    final qtn = double.tryParse(_qtnPriceCtrl.text.trim()) ?? _suggestedQtnPrice;

    return EstimateModel(
      id: widget.existingEstimate?.id,
      calculationNo: _calcNoCtrl.text.trim().isNotEmpty ? _calcNoCtrl.text.trim() : '00000112',
      date: _date,
      jobId: widget.existingEstimate?.jobId ?? widget.initialJob?.jobId,
      customerName: _customerNameCtrl.text.trim(),
      itemDescription: _itemDescCtrl.text.trim(),
      drawingNo: _drawingNoCtrl.text.trim(),
      type: _type,
      calculationsNotes: _notesCtrl.text.trim(),
      effectiveCoatingArea: area,
      gritSize: _selectedGrit,
      factor: factor,
      diamondRequirement: _diamondRequirement,
      diamondRate: rate,
      diamondCost: _diamondCost,
      blankCost: blank,
      grindingCost: grinding,
      extractionCost: extraction,
      balancingCost: balancing,
      transportationCost: transport,
      directCostSum: _directCostSum,
      marginPercentage: _marginPercentage,
      subTotalInclMargin: _subTotalInclMargin,
      processCost: process,
      totalCost: _totalCost,
      discountProvisionPercentage: _discountProvisionPercentage,
      provisionForDiscount: _provisionForDiscount,
      discountPercentage: discount,
      qtnPrice: qtn,
      minOrderQty: _minOrderQtyCtrl.text.trim(),
      delivery: _deliveryCtrl.text.trim(),
      qtnNoAndDate: _qtnNoDateCtrl.text.trim(),
    );
  }

  Future<void> _saveEstimate() async {
    if (_customerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer Name is required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final estimate = _buildCurrentEstimate();
      final saved = await _api.saveEstimate(estimate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estimate #${saved.calculationNo} confirmed & saved to Estimated Section!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save estimate: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportPdf() async {
    final estimate = _buildCurrentEstimate();
    try {
      await PdfEstimateApi.printOrShare(estimate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Color(0xFF0288D1), size: 22),
                const SizedBox(width: 8),
                Text(
                  widget.existingEstimate != null ? 'Edit Price Estimate' : 'Price Calculation & Estimate',
                  style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (widget.initialJob != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF7DD3FC)),
                    ),
                    child: Text(
                      'Job #${widget.initialJob!.jobId}',
                      style: const TextStyle(color: Color(0xFF0288D1), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              'Calculation No: ${_calcNoCtrl.text}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Print / Export Quotation PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF0288D1)),
            onPressed: _exportPdf,
          ),
          IconButton(
            tooltip: 'Reset calculation values',
            icon: const Icon(Icons.restart_alt, color: Colors.grey),
            onPressed: () {
              setState(() {
                _initControllers();
                _recalculate(syncQtnPrice: true);
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildCalculationsColumn()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildSummaryColumn()),
                    ],
                  )
                else ...[
                  _buildCalculationsColumn(),
                  const SizedBox(height: 16),
                  _buildSummaryColumn(),
                ],
                const SizedBox(height: 24),
                _buildBottomActionBar(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SECTION 1: HEADER & CUSTOMER DETAILS ---
  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business_outlined, color: Color(0xFF0288D1), size: 20),
                const SizedBox(width: 8),
                const Text('Customer & Quotation Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(DateFormat('dd-MM-yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _calcNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Calculation No *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer *',
                      hintText: 'e.g. M/s. Brakes India P Ltd',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'N', child: Text('N (New)')),
                      DropdownMenuItem(value: 'R', child: Text('R (Re-coating)')),
                      DropdownMenuItem(value: 'C', child: Text('C (Coating)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _type = val;
                          if (_type == 'R') {
                            _blankCostCtrl.text = '0';
                          } else if (_type == 'N' && _blankCostCtrl.text == '0') {
                            _blankCostCtrl.text = '30000';
                          }
                          _recalculate();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _itemDescCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Item Description',
                      hintText: 'e.g. EDP - Lined Shoe Assembly Grinding Wheel - Dia 360mm X Dia 240mm ID X Grit 30/40',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _drawingNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'DRG No (Drawing)',
                      hintText: 'e.g. 68TV0001',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION 2: CALCULATIONS COLUMN (DIAMOND, GRIT, OPERATIONAL COSTS) ---
  Widget _buildCalculationsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Diamond Coating Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.diamond_outlined, color: Color(0xFF0288D1), size: 20),
                    const SizedBox(width: 8),
                    const Text('Diamond & Coating Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Factor: ${_factorCtrl.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0288D1), fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Area and Grit selection
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _areaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Eff. Area of Coating (sq cm) *',
                          hintText: 'e.g. 535.86',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: kGritSizeFactors.containsKey(_selectedGrit) ? _selectedGrit : null,
                        decoration: const InputDecoration(
                          labelText: 'Grit Size *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: kGritSizeFactors.keys.map((k) {
                          return DropdownMenuItem(
                            value: k,
                            child: Text('$k (factor: ${kGritSizeFactors[k]!.toStringAsFixed(2)})', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) _onGritChanged(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _factorCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Factor',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Diamond Rate and Results
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _diamondRateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Diamond Rate (₹/ct)',
                          hintText: '25.00',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Diamond Requirement',
                        value: '${_diamondRequirement.toStringAsFixed(3)} cts',
                        subtext: 'Area × Factor',
                        icon: Icons.scale,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'Diamond Cost',
                        value: currencyFormatter.format(_diamondCost),
                        subtext: 'Req × Rate',
                        icon: Icons.currency_rupee,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Area calculations formula notes
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Calculations & Formula Notes (Optional)',
                    hintText: 'e.g. Area = (pi()/400)*((360+3)^2-(240-3)^2) = 593.46, Effective = 535.86',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Direct Operational Costs Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.precision_manufacturing_outlined, color: Color(0xFF0288D1), size: 20),
                    const SizedBox(width: 8),
                    const Text('Operational & Material Costs (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _blankCostCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Blank Cost (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _grindingCostCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Grinding Cost (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _extractionCostCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Extraction Cost (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _balancingCostCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Balancing Cost (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _transportationCostCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Transportation Cost (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _recalculate(syncQtnPrice: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Direct Costs (Materials + Diamond + Handling):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        currencyFormatter.format(_directCostSum),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quotation Terms Card (MOQ, Delivery, etc.)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handshake_outlined, color: Color(0xFF0288D1), size: 20),
                    const SizedBox(width: 8),
                    const Text('Quotation Terms & Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minOrderQtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Min. Order Qty (MOQ)',
                          hintText: 'e.g. 1 or 48750',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _deliveryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Terms',
                          hintText: 'e.g. 10% or 4-6 weeks',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _qtnNoDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'QTN No & Date (Optional)',
                          hintText: 'e.g. QTN/26/104',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 3: SUMMARY & MARGIN / DISCOUNT COLUMN ---
  Widget _buildSummaryColumn() {
    final currentQtnPrice = double.tryParse(_qtnPriceCtrl.text.trim()) ?? _suggestedQtnPrice;
    final discount = double.tryParse(_discountPercentageCtrl.text.trim()) ?? 10.0;
    // With 15% discount buffer and 10% discount: 25% base + (15% - 10%) = 30% margin on final price
    final effectiveFinalMargin = 25.0 + (15.0 - discount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cost Calculation Step-by-Step Card (PRICE BUILD-UP FIRST)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Build-Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),

                // Profit Margin (Fixed at 25%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profit Margin:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('25% (Fixed)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0288D1))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildSummaryLine(
                  label: 'Direct Costs Subtotal',
                  value: currencyFormatter.format(_directCostSum),
                  subtitle: 'Diamond + Materials',
                ),
                _buildSummaryLine(
                  label: 'Sub-Total (incl. 25% margin)',
                  value: currencyFormatter.format(_subTotalInclMargin),
                  subtitle: 'Direct Costs ÷ 0.75',
                  isHighlighted: true,
                ),

                const Divider(height: 20),

                // Process Cost
                TextField(
                  controller: _processCostCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Process Cost (Plating & Chemical) *',
                    hintText: '5000',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.science_outlined, size: 20),
                  ),
                  onChanged: (_) => _recalculate(syncQtnPrice: true),
                ),
                const SizedBox(height: 10),

                _buildSummaryLine(
                  label: 'Total Cost',
                  value: currencyFormatter.format(_totalCost),
                  subtitle: 'Sub-Total + Process Cost',
                  isBold: true,
                ),

                const Divider(height: 20),

                // Provision for Discount (Fixed at 15%)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Provision for Discount:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('15% (Fixed)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildSummaryLine(
                  label: 'Provision for Discount',
                  value: currencyFormatter.format(_provisionForDiscount),
                  subtitle: 'Total ÷ 0.85',
                  isHighlighted: true,
                ),

                const SizedBox(height: 14),

                // Discount and Override Price
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _discountPercentageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                          hintText: '10',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _qtnPriceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          const PositiveNumberInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'QTN Price (₹) *',
                          hintText: '68170',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          _customQtnPriceOverridden = true;
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // FINAL QUOTATION PRICE CARD (NOW PROMINENTLY AT THE BOTTOM OF THE FLOW)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0288D1), Color(0xFF01579B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0288D1).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FINAL QUOTATION PRICE (QTN)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Text(
                      '${effectiveFinalMargin.toStringAsFixed(0)}% Final Margin',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                shortCurrency.format(currentQtnPrice),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '15% discount buffer provisioned | Discount offered: ${discount.toStringAsFixed(0)}% | Final Margin on QTN: ${effectiveFinalMargin.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryLine({
    required String label,
    required String value,
    String? subtitle,
    bool isBold = false,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFF0F9FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted ? const Color(0xFF0369A1) : const Color(0xFF334155),
                ),
              ),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold || isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF0288D1) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(subtext, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- BOTTOM ACTION BAR ---
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Estimates'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _exportPdf,
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Export Quotation PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0288D1),
                  side: const BorderSide(color: Color(0xFF0288D1)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveEstimate,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(_saving ? 'Confirming...' : 'Confirm & Save Estimate', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
