import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/utils/pdf_tax_invoice_api.dart';

void main() {
  test('PdfTaxInvoiceApi generates sample invoice 1 correctly', () async {
    final data = TaxInvoiceData(
      invoiceNo: '2627-000555',
      invoiceDate: DateTime(2026, 11, 2),
      poNo: '3100-5700010615 DT02\nAUG 2025',
      placeOfSupply: 'Telangana (36)',
      docRef: 'RGP NO.3100006831 Dt.\n6.10.2026',
      billToName: 'Rane (Madras) Limited(BCD), Medak',
      billToAddress: 'BRAKE COMPONENTS DIVISION\nPREGNAPUR VILLAGE\nGAJWEL MANDEL\nMEDAK,\nTelangana - 502 311',
      billToGstin: '36AACCR9772M1ZM',
      shipToName: 'RANE (MADRAS)LIMITED,',
      shipToAddress: 'BRAKE COMPONENTS DIVISION\nH.NO.6-R8-035\nPLOT NO.23, SY.NO.22\nRAJALAKSHMI NILAYAM\nOPP.TO - TADBUND HANUMAN TEMPLE\nSIKH.VILLAGE, SECUNDERABAD\nTelangana - 500 009',
      shipToGstin: '36AACCR9772M1ZM',
      items: [
        TaxInvoiceItem(
          description: 'EDP - Dia 150mm peripheral wheel thickness 80mm x Bore 50mmXGrit\n30/40\nDrg no ;BP50011\nMat code;311916020009.',
          hsnCode: '68042110',
          quantity: 1,
          rate: 6745.0,
        ),
      ],
      taxType: TaxType.igst18,
    );

    expect(data.subTotal, 6745.0);
    expect(data.igstAmount, 1214.10);
    expect(data.rounding, -0.10);
    expect(data.grandTotal, 7959.0);
    expect(PdfTaxInvoiceApi.numberToWords(data.grandTotal), 'Rupees Seven Thousand Nine Hundred Fifty-Nine Only');

    final bytes = await PdfTaxInvoiceApi.generate(data);
    expect(bytes.isNotEmpty, true);

    final outDir = Directory('/Users/siddarth-mac/.gemini/antigravity/brain/ed7196ec-da69-4194-986b-8cae9dfbf6e5/scratch');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    File('${outDir.path}/generated_tax_invoice_1.pdf').writeAsBytesSync(bytes);
  });

  test('PdfTaxInvoiceApi generates sample invoice 2 (LUT exempt) correctly', () async {
    final data = TaxInvoiceData(
      invoiceNo: '2627-000557',
      invoiceDate: DateTime(2026, 11, 3),
      poNo: '5100010867/19.06.2018',
      placeOfSupply: 'Tamil Nadu (33)',
      reference: 'Rgp:AH3260000324 DT .\n25.08.2026',
      docRef: 'LUT NO;\nAD330326082684X DT\n26.03.2026',
      deliveryRef: 'TPNO 4971939707 DT\n25.08.2026',
      billToName: 'Brakes India Private Ltd, Unit-68',
      billToAddress: 'Plot No. AA2, Auto Ancillary SEZ\nMahindra World City,, Chengalpet\nTamil Nadu - 603004',
      billToGstin: '33AAACB2533Q2ZO',
      billToVendorCode: '202008',
      shipToAddress: 'Plot No. AA2, Auto Ancillary SEZ\nMahindra World City,, Chengalpet\nTamil Nadu - 603004',
      shipToGstin: '33AAACB2533Q2ZO',
      shipToVendorCode: '202008',
      items: [
        TaxInvoiceItem(
          description: 'EDP ROUGH Grinding Wheel Dia 360mm X 120mm Bore X 62mm OAL\nX Grit 30/40 DRG No: 68TV0001 Material Code: 311916000547LB\nLine Item No: 110',
          hsnCode: '998890',
          quantity: 1,
          rate: 19500.0,
        ),
      ],
      taxType: TaxType.lutExempt,
    );

    expect(data.subTotal, 19500.0);
    expect(data.totalTaxAmount, 0.0);
    expect(data.grandTotal, 19500.0);
    expect(PdfTaxInvoiceApi.numberToWords(data.grandTotal), 'Rupees Nineteen Thousand Five Hundred Only');

    final bytes = await PdfTaxInvoiceApi.generate(data);
    expect(bytes.isNotEmpty, true);

    final outDir = Directory('/Users/siddarth-mac/.gemini/antigravity/brain/ed7196ec-da69-4194-986b-8cae9dfbf6e5/scratch');
    File('${outDir.path}/generated_tax_invoice_2.pdf').writeAsBytesSync(bytes);
  });
}
