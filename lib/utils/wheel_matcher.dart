import '../models/estimate_model.dart';
import '../models/job_model.dart';

class WheelMatcher {
  /// Extract drawing number from a string (e.g. wheelSize, partNumber, description)
  static String? extractDrawingNo(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    final patterns = [
      // Explicit DRG / DRAWING prefix
      RegExp(
        r'(?:DRG\.?\s*NO\.?|DRAWING\s*NO\.?|DRG\s*NO|DRG\s*NUMBER)[:;\s]+([A-Za-z0-9_\-\.\/\s]+?)(?=\r|\n|Material|Mat\.?\s*code|Line\s*Item|Partys|Model|\(|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:Drg\.?\s*No\.?)[:;\s]*([A-Za-z0-9_\-\.\/\s]+?)(?=\r|\n|Material|Mat\.?\s*code|Line\s*Item|Partys|Model|\(|$)',
        caseSensitive: false,
      ),
      // In parentheses: e.g. (DP50033), (29LAU0002), (LAU0153), (11VV2888), (LAU0157ARC)
      RegExp(r'\(([A-Za-z0-9_\-\.\/]{4,})\)'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final val = m.group(1)?.trim();
        if (val != null && val.length >= 3) {
          // Reject false positives like "Dia" or "EDP"
          final lower = val.toLowerCase();
          if (!lower.startsWith('dia') && !lower.startsWith('edp') && !lower.startsWith('model')) {
            // Strip any trailing punctuation
            return val.replaceAll(RegExp(r'[\s;,\.\-]+$'), '');
          }
        }
      }
    }
    return null;
  }

  /// Clean string to lowercase alphanumeric only for resilient matching
  static String cleanAlphanumeric(String? text) {
    if (text == null) return '';
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Check if two customer names refer to the same company
  static bool isSameCustomer(String? c1, String? c2) {
    if (c1 == null || c2 == null) return false;
    final a = cleanAlphanumeric(c1);
    final b = cleanAlphanumeric(c2);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    // Substring match if sufficiently long
    if (a.length >= 4 && b.length >= 4) {
      if (a.contains(b) || b.contains(a)) return true;
    }

    // Common abbreviations
    // BIL -> Brakes India Limited
    if ((a.contains('bil') || a.contains('brakesindia')) &&
        (b.contains('bil') || b.contains('brakesindia'))) {
      // Also check location if present (e.g. solingar, sricity)
      if (a.contains('solingar') && b.contains('solingar')) return true;
      if ((a.contains('sricity') || a.contains('sri')) && (b.contains('sricity') || b.contains('sri'))) return true;
      if (!a.contains('solingar') && !b.contains('solingar') && !a.contains('sricity') && !b.contains('sri')) return true;
    }

    // RBL -> Rane Brake Lining
    if ((a.contains('rbl') || a.contains('ranebrakelining')) &&
        (b.contains('rbl') || b.contains('ranebrakelining'))) {
      if (a.contains('trichy') && b.contains('trichy')) return true;
      if (a.contains('ambattur') && b.contains('ambattur')) return true;
      if (a.contains('pondicherry') && b.contains('pondicherry')) return true;
      if (a.contains('medak') && b.contains('medak')) return true;
      if (a.contains('ponneri') && b.contains('ponneri')) return true;
    }

    return false;
  }

  /// Check if a job matches an estimate for the same customer & wheel
  static bool isMatchingWheel({
    required JobModel job,
    required EstimateModel estimate,
  }) {
    // 1. Must be the same customer
    if (!isSameCustomer(job.customerName, estimate.customerName)) {
      return false;
    }

    // 2. Drawing Number match (strongest criteria)
    final jobDrg = extractDrawingNo(job.wheelSize) ??
        extractDrawingNo(job.partNumber) ??
        extractDrawingNo(job.partDescription);

    final estDrg = estimate.drawingNo?.trim().isNotEmpty == true
        ? estimate.drawingNo!.trim()
        : (extractDrawingNo(estimate.itemDescription) ?? extractDrawingNo(estimate.calculationsNotes));

    if (jobDrg != null && estDrg != null) {
      final cleanJobDrg = cleanAlphanumeric(jobDrg);
      final cleanEstDrg = cleanAlphanumeric(estDrg);
      if (cleanJobDrg.isNotEmpty && cleanEstDrg.isNotEmpty) {
        if (cleanJobDrg == cleanEstDrg || cleanJobDrg.contains(cleanEstDrg) || cleanEstDrg.contains(cleanJobDrg)) {
          return true;
        }
      }
    }

    // 3. Part Number matching
    if (job.partNumber != null && job.partNumber!.trim().isNotEmpty) {
      final cleanJobPart = cleanAlphanumeric(job.partNumber);
      final cleanEstDesc = cleanAlphanumeric(estimate.itemDescription);
      final cleanEstDrg = estDrg != null ? cleanAlphanumeric(estDrg) : '';

      // Ignore trivial single-digit part numbers like "1"
      if (cleanJobPart.length >= 4) {
        if (cleanEstDesc.contains(cleanJobPart) || (cleanEstDrg.isNotEmpty && cleanEstDrg.contains(cleanJobPart))) {
          return true;
        }

        // Check if extracted code inside partNumber (e.g. DP50033 or LAU0153) matches
        final codeInJobPart = extractDrawingNo(job.partNumber);
        if (codeInJobPart != null) {
          final cleanCode = cleanAlphanumeric(codeInJobPart);
          if (cleanCode.length >= 4 && (cleanEstDesc.contains(cleanCode) || cleanEstDrg.contains(cleanCode))) {
            return true;
          }
        }
      }
    }

    // 4. Clean Wheel Description matching
    final jobWheel = job.wheelSize;
    final estDesc = estimate.itemDescription;
    if (jobWheel != null && estDesc != null) {
      final firstLineJob = jobWheel.split(RegExp(r'[\r\n]+')).first.trim();
      final cleanJobWheel = cleanAlphanumeric(firstLineJob);
      final cleanEstDesc = cleanAlphanumeric(estDesc);

      // If wheel dimensions line has substantial content (>= 15 chars) and is in estimate desc
      if (cleanJobWheel.length >= 15 && cleanEstDesc.contains(cleanJobWheel)) {
        return true;
      }

      // Check key dimension tokens (e.g. Dia 406mm, 200mm Bore, 26mm Thick)
      final diaMatch = RegExp(r'Dia\s*(\d+(?:\.\d+)?)\s*mm', caseSensitive: false).firstMatch(firstLineJob);
      final boreMatch = RegExp(r'(\d+(?:\.\d+)?)\s*mm\s*Bore', caseSensitive: false).firstMatch(firstLineJob) ??
          RegExp(r'Bore\s*(\d+(?:\.\d+)?)\s*mm', caseSensitive: false).firstMatch(firstLineJob);
      final thickMatch = RegExp(r'(\d+(?:\.\d+)?)\s*mm\s*Thick', caseSensitive: false).firstMatch(firstLineJob);

      if (diaMatch != null && boreMatch != null) {
        final diaVal = diaMatch.group(1);
        final boreVal = boreMatch.group(1);
        final thickVal = thickMatch?.group(1);

        final diaRegex = RegExp('Dia\\s*$diaVal\\s*mm', caseSensitive: false);
        final boreRegex = RegExp('$boreVal\\s*mm\\s*Bore|Bore\\s*$boreVal\\s*mm', caseSensitive: false);

        if (diaRegex.hasMatch(estDesc) && boreRegex.hasMatch(estDesc)) {
          if (thickVal == null || estDesc.contains(thickVal) || RegExp('$thickVal\\s*mm\\s*Thick', caseSensitive: false).hasMatch(estDesc)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Find matching estimate for a job from a list of estimates
  static EstimateModel? findMatchingEstimate(
    JobModel job,
    List<EstimateModel> existingEstimates,
  ) {
    for (final est in existingEstimates) {
      // Don't match the same job ID with itself as a repeat
      if (est.jobId == job.jobId) continue;

      if (isMatchingWheel(job: job, estimate: est)) {
        return est;
      }
    }
    return null;
  }

  /// Generate next sequential 8-digit calculation number (e.g. 00000113)
  static String generateNextCalculationNo(List<EstimateModel> estimates) {
    int maxNo = 112; // Base number starting point
    for (final e in estimates) {
      final parsed = int.tryParse(e.calculationNo);
      if (parsed != null && parsed > maxNo) {
        maxNo = parsed;
      }
    }
    return (maxNo + 1).toString().padLeft(8, '0');
  }

  /// Create a new EstimateModel pre-populated with costs from template,
  /// linked to repeat job with job's date.
  static EstimateModel createEstimateFromRepeatJob({
    required JobModel job,
    required EstimateModel template,
    required String nextCalcNo,
  }) {
    final jobDate = job.receivedDate ?? job.customerOrderDate ?? job.createdDate;

    // Use drawing number from template or job
    String? drgNo = template.drawingNo;
    if (drgNo == null || drgNo.trim().isEmpty) {
      drgNo = extractDrawingNo(job.wheelSize) ?? extractDrawingNo(job.partNumber);
    }

    // Build or reuse item description
    String itemDesc = template.itemDescription ?? '';
    if (itemDesc.isEmpty && job.wheelSize != null) {
      itemDesc = job.wheelSize!;
    }

    // Clean wheel type
    String wheelType = template.type;
    if (job.jobType == 'Re-coating') {
      wheelType = 'R';
    } else if (job.jobType == 'Coating') {
      wheelType = 'C';
    }

    return EstimateModel(
      calculationNo: nextCalcNo,
      date: jobDate,
      jobId: job.jobId,
      customerName: job.customerName?.isNotEmpty == true ? job.customerName! : template.customerName,
      itemDescription: itemDesc,
      drawingNo: drgNo,
      type: wheelType,
      calculationsNotes: template.calculationsNotes,
      effectiveCoatingArea: template.effectiveCoatingArea,
      gritSize: (job.diamondPowderGritSize?.isNotEmpty == true) ? job.diamondPowderGritSize : template.gritSize,
      factor: template.factor,
      diamondRequirement: template.diamondRequirement,
      diamondRate: template.diamondRate,
      diamondCost: template.diamondCost,
      blankCost: template.blankCost,
      grindingCost: template.grindingCost,
      extractionCost: template.extractionCost,
      balancingCost: template.balancingCost,
      transportationCost: template.transportationCost,
      directCostSum: template.directCostSum,
      marginPercentage: template.marginPercentage,
      subTotalInclMargin: template.subTotalInclMargin,
      processCost: template.processCost,
      totalCost: template.totalCost,
      discountProvisionPercentage: template.discountProvisionPercentage,
      provisionForDiscount: template.provisionForDiscount,
      discountPercentage: template.discountPercentage,
      qtnPrice: template.qtnPrice,
      minOrderQty: template.minOrderQty,
      delivery: template.delivery,
      qtnNoAndDate: template.qtnNoAndDate,
      isAutoEstimated: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
