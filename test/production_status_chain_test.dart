import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/models/job_model.dart';
import 'package:automated_dashboard/widgets/production_status_chain.dart';

void main() {
  group('Production Pipeline Stages and Helpers', () {
    test('kProductionStages contains the 6 sequential EDP stages', () {
      expect(kProductionStages, equals([
        'Start',
        'Cleaning',
        'Lacquering',
        'Plating',
        'Tacking',
        'Final Cleaning',
      ]));
    });

    test('getEffectiveProductionStage defaults to Start when stage is null or empty', () {
      final job1 = JobModel(jobId: '101', status: 'Production', createdDate: DateTime.now());
      expect(getEffectiveProductionStage(job1), equals('Start'));

      final job2 = JobModel(jobId: '102', status: 'Production', productionStage: '', createdDate: DateTime.now());
      expect(getEffectiveProductionStage(job2), equals('Start'));

      final job3 = JobModel(jobId: '103', status: 'Production', productionStage: 'Cleaning', createdDate: DateTime.now());
      expect(getEffectiveProductionStage(job3), equals('Cleaning'));
    });

    test('getNextProductionStage progresses through the pipeline sequentially', () {
      expect(getNextProductionStage('Start'), equals('Cleaning'));
      expect(getNextProductionStage('Cleaning'), equals('Lacquering'));
      expect(getNextProductionStage('Lacquering'), equals('Plating'));
      expect(getNextProductionStage('Plating'), equals('Tacking'));
      expect(getNextProductionStage('Tacking'), equals('Final Cleaning'));
      expect(getNextProductionStage('Final Cleaning'), isNull);
    });

    test('getPreviousProductionStage reverts sequentially', () {
      expect(getPreviousProductionStage('Start'), isNull);
      expect(getPreviousProductionStage('Cleaning'), equals('Start'));
      expect(getPreviousProductionStage('Lacquering'), equals('Cleaning'));
      expect(getPreviousProductionStage('Plating'), equals('Lacquering'));
      expect(getPreviousProductionStage('Tacking'), equals('Plating'));
      expect(getPreviousProductionStage('Final Cleaning'), equals('Tacking'));
    });
  });

  group('JobModel production serialization', () {
    test('JobModel serializes and deserializes productionStage and expectedProductionStageDate', () {
      final expectedDate = DateTime(2026, 11, 15);
      final job = JobModel(
        jobId: 'J-500',
        status: 'Production',
        productionStage: 'Lacquering',
        expectedProductionStageDate: expectedDate,
        productionStageHistory: [
          {'stage': 'Start', 'date': '2026-11-10T10:00:00.000Z'},
          {'stage': 'Cleaning', 'date': '2026-11-12T10:00:00.000Z'},
          {'stage': 'Lacquering', 'date': '2026-11-14T10:00:00.000Z', 'expectedDate': '2026-11-15T00:00:00.000Z'},
        ],
        createdDate: DateTime.now(),
      );

      final json = job.toJson();
      expect(json['productionStage'], equals('Lacquering'));
      expect(json['expectedProductionStageDate'], equals(expectedDate.toIso8601String()));
      expect(json['productionStageHistory'], hasLength(3));

      final restored = JobModel.fromJson(json);
      expect(restored.productionStage, equals('Lacquering'));
      expect(restored.expectedProductionStageDate, equals(expectedDate));
      expect(restored.productionStageHistory, hasLength(3));
    });
  });

  group('ProductionStatusChain widget', () {
    testWidgets('renders Production Start in green initially with unified EDP chain', (tester) async {
      final job = JobModel(
        jobId: 'J-1',
        status: 'Production',
        productionStage: 'Start',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductionStatusChain(job: job),
          ),
        ),
      );

      expect(find.text('Production Status'), findsOneWidget);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
      final chainRichText = richTexts.firstWhere((r) => (r.text as TextSpan).children?.any((c) => (c as TextSpan).text == 'Production Start') ?? false);
      final textSpan = chainRichText.text as TextSpan;
      
      // EDP, ' -> ', Production Start, ' -> ', Cleaning, ' -> ', Lacquering, ' -> ', Plating, ' -> ', Tacking, ' -> ', Final Cleaning
      expect(textSpan.children, hasLength(13));
      final edpSpan = textSpan.children![0] as TextSpan;
      expect(edpSpan.text, equals('EDP'));
      expect(edpSpan.style?.color, equals(const Color(0xFF202124)));

      final startSpan = textSpan.children![2] as TextSpan;
      expect(startSpan.text, equals('Production Start'));
      expect(startSpan.style?.color, equals(const Color(0xFF2E7D32))); // Green active

      final cleaningSpan = textSpan.children![4] as TextSpan;
      expect(cleaningSpan.text, equals('Cleaning'));
      expect(cleaningSpan.style?.color, equals(const Color(0xFF9E9E9E))); // Grey remaining
    });

    testWidgets('renders supplier chain EDP -> SKMT -> Production Start -> ... with active stage in green and remaining in grey', (tester) async {
      final expectedDate = DateTime(2026, 11, 20);
      final job = JobModel(
        jobId: 'J-2',
        status: 'Production',
        supplierChain: ['SKMT'],
        productionStage: 'Plating',
        expectedProductionStageDate: expectedDate,
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductionStatusChain(job: job),
          ),
        ),
      );

      expect(find.text('Production Status'), findsOneWidget);
      expect(find.text('Expected: 20-11-2026'), findsOneWidget);

      final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
      final chainRichText = richTexts.firstWhere((r) => (r.text as TextSpan).children?.any((c) => (c as TextSpan).text == 'Plating') ?? false);
      final textSpan = chainRichText.text as TextSpan;
      
      // EDP, ' -> ', SKMT, ' -> ', Production Start, ' -> ', Cleaning, ' -> ', Lacquering, ' -> ', Plating, ' -> ', Tacking, ' -> ', Final Cleaning
      // Total children: 15
      expect(textSpan.children, hasLength(15));

      final edpSpan = textSpan.children![0] as TextSpan;
      expect(edpSpan.text, equals('EDP'));
      expect(edpSpan.style?.color, equals(const Color(0xFF202124)));

      final skmtSpan = textSpan.children![2] as TextSpan;
      expect(skmtSpan.text, equals('SKMT'));
      expect(skmtSpan.style?.color, equals(const Color(0xFF202124)));

      final startSpan = textSpan.children![4] as TextSpan;
      expect(startSpan.text, equals('Production Start'));
      expect(startSpan.style?.color, equals(const Color(0xFF202124)));

      final platingSpan = textSpan.children![10] as TextSpan;
      expect(platingSpan.text, equals('Plating'));
      expect(platingSpan.style?.color, equals(const Color(0xFF2E7D32))); // Green active

      final tackingSpan = textSpan.children![12] as TextSpan;
      expect(tackingSpan.text, equals('Tacking'));
      expect(tackingSpan.style?.color, equals(const Color(0xFF9E9E9E))); // Grey remaining
    });

    testWidgets('renders Ready for Dispatch when completed', (tester) async {
      final job = JobModel(
        jobId: 'J-3',
        status: 'Completed',
        productionStage: 'Ready for Dispatch',
        createdDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductionStatusChain(job: job),
          ),
        ),
      );

      final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
      final chainRichText = richTexts.firstWhere((r) => (r.text as TextSpan).children?.any((c) => (c as TextSpan).text == 'Ready for Dispatch') ?? false);
      final textSpan = chainRichText.text as TextSpan;
      // All stages + arrow + Ready for Dispatch
      final lastSpan = textSpan.children!.last as TextSpan;
      expect(lastSpan.text, equals('Ready for Dispatch'));
      expect(lastSpan.style?.color, equals(const Color(0xFF2E7D32)));
    });
  });
}
