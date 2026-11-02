import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/models/estimate_model.dart';
import 'package:automated_dashboard/utils/pdf_estimate_api.dart';

void main() {
  test('PdfEstimateApi generates non-empty PDF bytes', () async {
    final estimate = EstimateModel(
      calculationNo: '00000112',
      date: DateTime(2026, 11, 2),
      customerName: 'Brakes India Limited Solingar',
      itemDescription: 'EDP - Lining Grinding WHeel - Dia 406mm X 200mm Bore X 26mm Thick X 103mm Face Width X Grit 30/40',
      drawingNo: 'LAU 0152/RC',
      type: 'R',
      effectiveCoatingArea: 535.86,
      diamondRequirement: 225.06,
      diamondCost: 8628.53,
      blankCost: 0,
      grindingCost: 0,
      extractionCost: 0,
      balancingCost: 3000,
      transportationCost: 1000,
      subTotalInclMargin: 12628.37,
      processCost: 5000,
      totalCost: 17628.37,
      provisionForDiscount: 20982.79,
      discountPercentage: 0,
      qtnPrice: 20980,
      minOrderQty: '1 set',
      delivery: '4 - 6 Weeks',
      qtnNoAndDate: '',
    );

    final bytes = await PdfEstimateApi.generate(estimate);
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
  });
}
