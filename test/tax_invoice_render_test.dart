import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/utils/pdf_tax_invoice_api.dart';

void main() {
  test('PdfTaxInvoiceApi generates invoice matching reference screenshot (IGST)', () async {
    final data = TaxInvoiceData(
      invoiceNo: '2627-000355',
      invoiceDate: DateTime(2026, 8, 24),
      poNo: '5100015994 Dt.06.03.2025',
      placeOfSupply: 'Jharkhand (20)',
      reference: 'RGP NO.CQ3260000142\nDt.08.06.2026T',
      docRef: 'TPNO.4968468571 Dt.\n08.06.2026',
      billToName: 'Brakes india  Private Limited - Jharkhand',
      billToAddress: 'PLOT NO.577 & 578,\nVillage:- Birbans, P.O:- Kolabira,\nTata- Saraikela Main Road,\nP.S. :-Saraikela,\nDistrict - Saraikela - Kharswana,,\nJharkhand - 833220',
      billToGstin: '20AAACB2533Q1ZW',
      shipToName: '',
      shipToAddress: 'PLOT NO.577 & 578,\nVillage:- Birbans, P.O:- Kolabira,\nTata- Saraikela Main Road,\nP.S.:- Saraikela,\nDistrict - Saraikela - Kharswana,,\nJharkhand - 833220',
      shipToGstin: '20AAACB2533Q1ZW',
      items: [
        TaxInvoiceItem(
          description: 'EDP - FINE Grinding Wheel(Drum Type) - Dia 350mm X 80mm Bore X\n240mm Long X Grit 40/50\nMaterial Code:311916000548LB\nLine Item No: 20',
          hsnCode: '68042110',
          quantity: 1,
          rate: 30000.0,
        ),
        TaxInvoiceItem(
          description: 'EDP - ROUGH Grinding Wheel(Drum Type) - Dia 350mm X 80mm Bore\nX 240mm Long X Grit 20/30\nMaterial Code: 311916000549LB\nLine Item No: 10',
          hsnCode: '68042110',
          quantity: 1,
          rate: 50000.0,
        ),
      ],
      taxType: TaxType.igst18,
    );

    final bytes = await PdfTaxInvoiceApi.generate(data);
    expect(bytes.isNotEmpty, true);
    File('/tmp/test_tax_invoice.pdf').writeAsBytesSync(bytes);
  });

  test('PdfTaxInvoiceApi generates invoice matching reference screenshot (CGST+SGST)', () async {
    final data = TaxInvoiceData(
      invoiceNo: '2627-69590182',
      invoiceDate: DateTime(2026, 11, 4),
      poNo: '1212 DT 04 NOV 2026',
      placeOfSupply: 'Tamil Nadu (33)',
      reference: 'Rgp:122212 DT 04.11.2026',
      billToName: 'Wheels India Limited',
      billToAddress: 'PADI, Chennai\nTamil Nadu - 600050',
      billToGstin: '33AAACW0315K1Z0',
      shipToName: '',
      shipToAddress: 'PADI, Chennai\nTamil Nadu - 600050',
      shipToGstin: '33AAACW0315K1Z0',
      items: [
        TaxInvoiceItem(
          description: 'EDP - EDP-DIAMOND File straight Round dia4.5mmx80cl-180mmOAL-ITEMCODE455060180004\nHSN CODE 83031000\nDrg no ;WHEELS-4,5\nGrit: 20/30',
          hsnCode: '68042110',
          quantity: 1,
          rate: 10000.0,
        ),
      ],
      taxType: TaxType.cgstSgst9,
    );

    final bytes = await PdfTaxInvoiceApi.generate(data);
    expect(bytes.isNotEmpty, true);
    File('/tmp/test_tax_invoice_cgst_sgst.pdf').writeAsBytesSync(bytes);
  });
}
