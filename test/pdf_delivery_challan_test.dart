import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/models/delivery_challan_model.dart';
import 'package:automated_dashboard/utils/pdf_delivery_challan_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfDeliveryChallanApi Tests', () {
    test('Generates valid PDF for DC2627-00228 (multi-item)', () async {
      final challan = DeliveryChallanModel(
        dcNumber: 'DC2627-00228',
        date: DateTime(2026, 10, 24),
        supplierName: 'SKMT Engineering Enerprises',
        supplierAddress: '63, Sarangapani Street, Sivabootham\nVanagaram, Chennai - 600095,\n-',
        supplierGstin: 'GSTIN 33AFFPV1640H1ZK',
        placeOfSupply: 'Tamil Nadu (33)',
        reference: 'sent for grinding polishing return',
        challanType: 'Job Work',
        items: [
          DeliveryChallanItem(
            itemNumber: 1,
            description: 'EDP FINE Grinding Wheel Dia 360mm X 120mm Bore X 62mm OAL(BI JARKHAND)GRI&POLISHING',
            quantity: 1,
            unit: 'No(s)',
            approxValue: 1.00,
          ),
          DeliveryChallanItem(
            itemNumber: 2,
            description: 'EDP ROUGH Grinding Wheel - Dia 360mm X 120mm Bore X 62mm OAL(BIJARKHAND)\nGRI&POLISHING',
            quantity: 1,
            unit: 'No(s)',
            approxValue: 1.00,
          ),
          DeliveryChallanItem(
            itemNumber: 3,
            description: 'EDP-Dia200mm x ID166 x BORE80 X Width of coating 17mmXThickness 30mm (slots 16 nos)(J Chamfer Wheel)(SRICITY)GRI&POLISHING',
            quantity: 1,
            unit: 'No(s)',
            approxValue: 1.00,
          ),
          DeliveryChallanItem(
            itemNumber: 4,
            description: 'EDP-EDP-Dia 250mm x Thick 50mm xBore 50mm(ADMAC)GRI&POLISHING',
            quantity: 1,
            unit: 'No(s)',
            approxValue: 1.00,
          ),
          DeliveryChallanItem(
            itemNumber: 5,
            description: 'EDP-DIA 250 FINAL WHEEL(RMLT)GRI&POLIHING',
            quantity: 1,
            unit: 'No(s)',
            approxValue: 1.00,
          ),
        ],
      );

      final bytes = await PdfDeliveryChallanApi.generate(challan);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Generates valid PDF for DC2627-00230 (without reference)', () async {
      final challan = DeliveryChallanModel(
        dcNumber: 'DC2627-00230',
        date: DateTime(2026, 11, 2),
        supplierName: 'SKMT Engineering Enerprises',
        supplierAddress: '63, Sarangapani Street, Sivabootham\nVanagaram, Chennai - 600095,\n-',
        supplierGstin: 'GSTIN 33AFFPV1640H1ZK',
        placeOfSupply: 'Tamil Nadu (33)',
        reference: null,
        challanType: 'Job Work',
        items: [
          DeliveryChallanItem(
            itemNumber: 1,
            description: 'EDP- Dia 260mm Final Wheel for Grinding\nand polishing and return.',
            quantity: 1,
            unit: 'No(s)',
            approxValue: 1.00,
          ),
        ],
      );

      final bytes = await PdfDeliveryChallanApi.generate(challan);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
