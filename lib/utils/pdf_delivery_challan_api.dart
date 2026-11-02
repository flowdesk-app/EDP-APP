import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/delivery_challan_model.dart';

class PdfDeliveryChallanApi {
  static const borderSide = pw.BorderSide(color: PdfColors.black, width: 0.75);

  /// Generate the PDF document matching the exact official Delivery Challan format
  static Future<Uint8List> generate(DeliveryChallanModel challan) async {
    final pdf = pw.Document();

    // Load logo image asset
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/dc_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      try {
        final fallbackBytes = await rootBundle.load('assets/images/edp_logo.png');
        logoImage = pw.MemoryImage(fallbackBytes.buffer.asUint8List());
      } catch (_) {}
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    final formattedDate = dateFmt.format(challan.date);
    final hasReference = challan.reference != null && challan.reference!.trim().isNotEmpty;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 45.6, right: 43.8, top: 36.0, bottom: 25.0),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Top Logo
              if (logoImage != null)
                pw.Container(
                  height: 32.0,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Image(logoImage, height: 32.0, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  height: 32.0,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Exclusive Diamond Products',
                    style: pw.TextStyle(
                      fontSize: 16.0,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('0088CC'),
                    ),
                  ),
                ),

              pw.SizedBox(height: 8.0),

              // 2. Centered Section Title with Horizontal Rule on Left & Right
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Divider(thickness: 1.0, color: PdfColors.black)),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14.0),
                    child: pw.Text(
                      'RETURNABLE DELIVERY CHALLAN',
                      style: pw.TextStyle(
                        fontSize: 13.0,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  pw.Expanded(child: pw.Divider(thickness: 1.0, color: PdfColors.black)),
                ],
              ),

              pw.SizedBox(height: 25.0),

              // 3. Deliver To & Challan Number Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Deliver To
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Deliver To',
                          style: const pw.TextStyle(fontSize: 9.0),
                        ),
                        pw.SizedBox(height: 4.0),
                        pw.Text(
                          challan.supplierName,
                          style: pw.TextStyle(fontSize: 9.0, fontWeight: pw.FontWeight.bold),
                        ),
                        if (challan.supplierAddress.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2.5),
                          ...challan.supplierAddress.split(RegExp(r'[\r\n]+')).map(
                            (line) => pw.Text(line.trim(), style: const pw.TextStyle(fontSize: 8.0)),
                          ),
                        ],
                        if (challan.supplierGstin != null && challan.supplierGstin!.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 3.0),
                          pw.Text(challan.supplierGstin!.trim(), style: const pw.TextStyle(fontSize: 8.0)),
                        ],
                        pw.SizedBox(height: 12.0),
                        pw.Text(
                          'Place Of Supply: ${challan.placeOfSupply}',
                          style: const pw.TextStyle(fontSize: 8.0),
                        ),
                      ],
                    ),
                  ),

                  // Right side: Delivery Challan#
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Delivery Challan#',
                        style: const pw.TextStyle(fontSize: 8.0, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2.0),
                      pw.Text(
                        challan.dcNumber,
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30.0),

              // 4. Metadata Box Table (Challan Date, Reference, Challan Type)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.75),
                children: [
                  // Header Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                        child: pw.Text('Challan Date', style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                      if (hasReference)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                          child: pw.Text('Reference', style: const pw.TextStyle(fontSize: 8.0)),
                        ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                        child: pw.Text('Challan Type', style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                    ],
                  ),
                  // Values Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                      if (hasReference)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          child: pw.Text(challan.reference!.trim(), style: const pw.TextStyle(fontSize: 8.0)),
                        ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: pw.Text(challan.challanType, style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 35.0),

              // 5. Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.75),
                columnWidths: const {
                  0: pw.FixedColumnWidth(26.0),
                  1: pw.FlexColumnWidth(1.0),
                  2: pw.FixedColumnWidth(48.0),
                  3: pw.FixedColumnWidth(48.0),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
                        child: pw.Text('#', style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: pw.Text('Description', style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                        child: pw.Text('Qty', style: const pw.TextStyle(fontSize: 8.0)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Approx.', style: const pw.TextStyle(fontSize: 8.0)),
                            pw.Text('Value', style: const pw.TextStyle(fontSize: 8.0)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Item Rows
                  ...challan.items.map((it) {
                    return pw.TableRow(
                      children: [
                        // #
                        pw.Container(
                          alignment: pw.Alignment.topCenter,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                          child: pw.Text(it.itemNumber.toString(), style: const pw.TextStyle(fontSize: 8.0)),
                        ),
                        // Description
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: pw.Text(
                            it.description,
                            style: const pw.TextStyle(fontSize: 8.0),
                          ),
                        ),
                        // Qty
                        pw.Container(
                          alignment: pw.Alignment.topCenter,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(it.quantity.toString(), style: const pw.TextStyle(fontSize: 8.0)),
                              pw.Text(it.unit, style: const pw.TextStyle(fontSize: 8.0)),
                            ],
                          ),
                        ),
                        // Approx. Value
                        pw.Container(
                          alignment: pw.Alignment.topRight,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                          child: pw.Text(
                            it.approxValue.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8.0),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 55.0),

              // 6. Authorized Signatory Block
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Authorized Signatory ',
                        style: const pw.TextStyle(fontSize: 10.0),
                      ),
                      pw.Container(
                        width: 170.0,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.75)),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3.0),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 105.0),
                    child: pw.Text(
                      'For ${challan.authorizedSignatoryFor}',
                      style: const pw.TextStyle(fontSize: 8.0),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 7. Bottom Footer (Company Address, Phones, GSTIN, PAN)
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Divider(thickness: 0.75, color: PdfColors.black),
                    pw.SizedBox(height: 3.0),
                    pw.Text(
                      'No.62, Easwaran Koil Street, Porur(Behind RABS Engineering Works, entry from Balamurugan Koil 2nd Street), Chennai - 600116, Tamilnadu, India',
                      style: const pw.TextStyle(fontSize: 6.0),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      'Phone: +91-44-42121634, 9840539026, 9677067936, 9840231634, Email: exclusivediamodproducts@gmail.com, website: www.exclusivediamondproducts.com',
                      style: const pw.TextStyle(fontSize: 6.0),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      'GSTIN: 33AABFE0399P1Z5, PAN No: AABFE0399P',
                      style: const pw.TextStyle(fontSize: 6.0),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or show system print & download preview
  static Future<void> printOrShare(DeliveryChallanModel challan) async {
    final pdfBytes = await generate(challan);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${challan.dcNumber}.pdf',
    );
  }

  /// Direct PDF download / share
  static Future<void> downloadPdf(DeliveryChallanModel challan) async {
    final pdfBytes = await generate(challan);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${challan.dcNumber}.pdf',
    );
  }
}
