import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/models/estimate_model.dart';
import 'package:automated_dashboard/models/job_model.dart';
import 'package:automated_dashboard/utils/wheel_matcher.dart';

void main() {
  group('WheelMatcher Unit Tests', () {
    test('extractDrawingNo handles explicit DRG No', () {
      const text1 = 'EDP - Lining Grinding WHeel - Dia 406mm X 200mm Bore X 26mm Thick X 103mm Face Width X Grit 30/40\nDRG No: LAU 0152/RC\nMaterial: ZB311916000331\nLine Item No: 90';
      expect(WheelMatcher.extractDrawingNo(text1), 'LAU 0152/RC');

      const text2 = 'DRG No.29LAU0157A/RC\nMaterial: ZB311916000333';
      expect(WheelMatcher.extractDrawingNo(text2), '29LAU0157A/RC');

      const text3 = 'DRG NO;DP50039\nMaterial Code: 311916030126';
      expect(WheelMatcher.extractDrawingNo(text3), 'DP50039');

      const text4 = 'Drg.No.DP50033 (Model 2)';
      expect(WheelMatcher.extractDrawingNo(text4), 'DP50033');

      const text5 = 'RBLT-Model2 - 250 Final Wheel(DP50033)';
      expect(WheelMatcher.extractDrawingNo(text5), 'DP50033');

      const text6 = 'BILS-Model2 - VW Chamfering(29LAU0002)';
      expect(WheelMatcher.extractDrawingNo(text6), '29LAU0002');
    });

    test('isSameCustomer identifies company aliases and variations', () {
      expect(WheelMatcher.isSameCustomer('Brakes India Limited Solingar', 'Brakes India Limited Solingar'), isTrue);
      expect(WheelMatcher.isSameCustomer('BIL Solingar', 'Brakes India Limited Solingar'), isTrue);
      expect(WheelMatcher.isSameCustomer('RANE PONNERI', 'rane ponneri'), isTrue);
      expect(WheelMatcher.isSameCustomer('REDEMA', 'redema'), isTrue);
      expect(WheelMatcher.isSameCustomer('Rane Brake Lining Limited Trichy', 'RBL Trichy'), isTrue);
      expect(WheelMatcher.isSameCustomer('Brakes India Limited Solingar', 'REDEMA'), isFalse);
    });

    test('isMatchingWheel matches repeat job with existing estimate', () {
      final existingEstimate = EstimateModel(
        calculationNo: '00000112',
        date: DateTime(2026, 11, 2),
        customerName: 'Brakes India Limited Solingar',
        drawingNo: 'LAU 0152/RC',
        itemDescription: 'BILS-Model2 - External LAU0152LB - EDP - Lining Grinding WHeel - Dia 406mm X 200mm Bore X 26mm Thick X 103mm Face Width X Grit 30/40\nDRG No: LAU 0152/RC\nMaterial: ZB311916000331\nLine Item No: 90 - Grit 30/40',
        qtnPrice: 20980.0,
        effectiveCoatingArea: 535.86,
        diamondRate: 25.0,
        blankCost: 30000.0,
      );

      // Repeat job arriving with same wheel
      final repeatJob = JobModel(
        jobId: 'JOB-99999999',
        customerName: 'Brakes India Limited Solingar',
        partNumber: 'BILS-Model2 - External LAU0152LB',
        wheelSize: 'EDP - Lining Grinding WHeel - Dia 406mm X 200mm Bore X 26mm Thick X 103mm Face Width X Grit 30/40\nDRG No: LAU 0152/RC\nMaterial: ZB311916000331\nLine Item No: 90',
        receivedDate: DateTime(2026, 11, 5),
        createdDate: DateTime(2026, 11, 5),
        status: 'In Progress',
        currentLocation: 'Store',
      );

      final matches = WheelMatcher.isMatchingWheel(job: repeatJob, estimate: existingEstimate);
      expect(matches, isTrue);

      final nextCalc = WheelMatcher.generateNextCalculationNo([existingEstimate]);
      expect(nextCalc, '00000113');

      final autoEstimate = WheelMatcher.createEstimateFromRepeatJob(
        job: repeatJob,
        template: existingEstimate,
        nextCalcNo: nextCalc,
      );

      expect(autoEstimate.calculationNo, '00000113');
      expect(autoEstimate.jobId, 'JOB-99999999');
      expect(autoEstimate.qtnPrice, 20980.0);
      expect(autoEstimate.effectiveCoatingArea, 535.86);
      expect(autoEstimate.blankCost, 30000.0);
      expect(autoEstimate.isAutoEstimated, isTrue);
      expect(autoEstimate.date, DateTime(2026, 11, 5));
    });

    test('generateNextCalculationNo handles numbers properly', () {
      final e1 = EstimateModel(calculationNo: '00000112', date: DateTime.now(), customerName: 'Test');
      final e2 = EstimateModel(calculationNo: '00000115', date: DateTime.now(), customerName: 'Test');
      expect(WheelMatcher.generateNextCalculationNo([e1, e2]), '00000116');
    });
  });
}
