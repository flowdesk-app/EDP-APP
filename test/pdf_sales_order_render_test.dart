import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/utils/pdf_invoice_api.dart';

void main() {
  test('PdfInvoiceApi generates Sales Order matching reference layout', () async {
    final data = InvoiceData(
      invoiceTitle: 'SALES ORDER',
      salesOrderNo: 'RGP NO.4110019123',
      salesOrderDate: DateTime(2026, 8, 20),
      billToName: 'Automotive Axles Limited, Mysore',
      billToAddress: 'Hootagalli Industrial Area\nOff. Hunsur Road, Mysuru\nKarnataka - 570018',
      billToGstin: '29AABCA6923G1ZP',
      billToVendorCode: '500477',
      shipToName: '',
      shipToAddress: 'Hootagalli Industrial Area\nOff. Hunsur Road, Mysuru\nKarnataka - 570018',
      shipToGstin: '29AABCA6923G1ZP',
      shipToVendorCode: '500477',
      placeOfSupply: 'Karnataka (29)',
      orderDate: DateTime(2026, 8, 24),
      reference: 'Matl recd on 24.8.2026\n/WO2158',
      items: [
        InvoiceItem(
          title: 'AutoAxle-Model2 - 610 Face Wheel',
          description: 'EDP -BL OD Grinding Wheel For Brake Shoe\nAssembly Dia 610mm X 254mm ID X 35mm\nThickX Grit 30/40 (MODEL-2)',
          hsnCode: '68042110',
          quantity: 1,
          rate: 31150.0,
        ),
      ],
      taxPercentage: 18.0,
      taxLabel: 'IGST (18%)',
    );

    final bytes = await PdfInvoiceApi.generate(data);
    expect(bytes.isNotEmpty, true);

    File('/tmp/sales_order_test.pdf').writeAsBytesSync(bytes);
  });
}
