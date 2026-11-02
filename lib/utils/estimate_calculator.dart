/// Grit Size to Diamond Requirement Factor Table
/// Extracted directly from EDP engineering standard table
const Map<String, double> kGritSizeFactors = {
  '15/20': 0.85,
  '20/25': 0.75,
  '25/30': 0.65,
  '30/40': 0.42,
  '40/50': 0.30,
  '50/60': 0.27,
  '60/80': 0.22,
  '80/100': 0.17,
  '100/120': 0.15,
  '120/140': 0.13,
  '140/170': 0.11,
  '170/200': 0.11,
  '200/240': 0.10,
  '240/300': 0.10,
  '300/400': 0.10,
};

/// Helper methods for EDP estimates and quotation calculations
class EstimateCalculator {
  /// Detects standard grit size key from text or returns null
  static String? detectGritSize(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final clean = input.trim();

    // Direct match
    if (kGritSizeFactors.containsKey(clean)) return clean;

    // Search for patterns like "30/40" in description
    for (final key in kGritSizeFactors.keys) {
      if (clean.contains(key)) {
        return key;
      }
    }

    // Try normalising slashes or spaces
    final normalised = clean.replaceAll(' ', '');
    for (final key in kGritSizeFactors.keys) {
      if (normalised.contains(key)) {
        return key;
      }
    }
    return null;
  }

  /// Gets the factor for a given grit size string, defaulting to 0.30 if not recognized
  static double getFactorForGrit(String? gritSize) {
    if (gritSize == null) return 0.30;
    final detected = detectGritSize(gritSize);
    if (detected != null && kGritSizeFactors.containsKey(detected)) {
      return kGritSizeFactors[detected]!;
    }
    return 0.30;
  }

  /// Calculates diamond requirement in carats (cts)
  /// Formula: Effective Coating Area (sq cm) * Factor
  static double calculateDiamondRequirement(double effectiveArea, double factor) {
    if (effectiveArea <= 0 || factor <= 0) return 0.0;
    return effectiveArea * factor;
  }

  /// Calculates diamond cost in INR
  /// Formula: Diamond requirement (cts) * Rate per carat (₹/ct)
  static double calculateDiamondCost(double diamondRequirement, double diamondRate) {
    if (diamondRequirement <= 0 || diamondRate <= 0) return 0.0;
    return diamondRequirement * diamondRate;
  }

  /// Calculates direct costs subtotal
  static double calculateDirectCosts({
    required double diamondCost,
    required double blankCost,
    required double grindingCost,
    required double extractionCost,
    required double balancingCost,
    required double transportationCost,
  }) {
    return diamondCost + blankCost + grindingCost + extractionCost + balancingCost + transportationCost;
  }

  /// Calculates Sub-Total including profit margin
  /// Formula: Direct Costs / (1 - (marginPercentage / 100))
  /// E.g. For 25% margin: Direct Costs / 0.75
  /// E.g. For 20% margin: Direct Costs / 0.80
  static double calculateSubTotalInclMargin(double directCosts, double marginPercentage) {
    if (directCosts <= 0) return 0.0;
    final divisor = 1.0 - (marginPercentage / 100.0);
    if (divisor <= 0.05) return directCosts; // safety against division by 0
    return directCosts / divisor;
  }

  /// Calculates Total cost
  /// Formula: Sub-Total(incl margin) + Process Cost
  static double calculateTotal(double subTotalInclMargin, double processCost) {
    return subTotalInclMargin + (processCost > 0 ? processCost : 0.0);
  }

  /// Calculates Provision for discount
  /// Formula: Total / (1 - (provisionPercentage / 100))
  /// E.g. For 15% discount provision: Total / 0.85
  /// E.g. For 20% discount provision: Total / 0.80
  static double calculateProvisionForDiscount(double total, double provisionPercentage) {
    if (total <= 0) return 0.0;
    final divisor = 1.0 - (provisionPercentage / 100.0);
    if (divisor <= 0.05) return total; // safety
    return total / divisor;
  }

  /// Rounds QTN price to nearest 10 (as used in EDP quotation sheets, e.g. 68166.45 -> 68170)
  static double roundQtnPrice(double provisionForDiscount) {
    if (provisionForDiscount <= 0) return 0.0;
    return (provisionForDiscount / 10.0).round() * 10.0;
  }
}
