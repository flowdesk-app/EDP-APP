import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/estimate_model.dart';

class PdfEstimateApi {
  static Future<Uint8List> generate(EstimateModel estimate) async {
    final pdf = pw.Document();

    final numFmt = NumberFormat('0.00');
    final dateFmt = DateFormat('dd-MMM-yyyy');

    // PAGE 1: PRICE CALCULATION SHEET
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // TOP HEADER TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(2.8),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.8),
                },
                children: [
                  // Row 1: Calculation No & Date
                  pw.TableRow(
                    children: [
                      _cell('Calulation No:', isBold: true),
                      _cell(estimate.calculationNo.isNotEmpty ? estimate.calculationNo : '000001089'),
                      _cell('Date:', isBold: true),
                      _cell(dateFmt.format(estimate.date)),
                    ],
                  ),
                  // Row 2: Customer
                  pw.TableRow(
                    children: [
                      _cell('Customer:', isBold: true),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: pw.Text(
                          estimate.customerName.isNotEmpty ? estimate.customerName : 'M/s.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      _cell(''),
                      _cell(''),
                    ],
                  ),
                ],
              ),

              // ITEM DESCRIPTION & TYPE BOX
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(6.2),
                  1: const pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Item Description:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, decoration: pw.TextDecoration.underline)),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              estimate.itemDescription?.isNotEmpty == true ? estimate.itemDescription! : 'N/A',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            if (estimate.drawingNo != null && estimate.drawingNo!.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              pw.Text('DRG No: ${estimate.drawingNo}', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              estimate.type.isNotEmpty ? estimate.type : 'R',
                              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Drawing / Notes Row
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Drawing:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text('SEE OVERLEAF', style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                      _cell(''),
                    ],
                  ),
                  // Calculations Notes
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Calculations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            if (estimate.calculationsNotes != null && estimate.calculationsNotes!.isNotEmpty)
                              pw.Text(estimate.calculationsNotes!, style: const pw.TextStyle(fontSize: 8.5))
                            else
                              pw.Text('Area = ${estimate.effectiveCoatingArea.toStringAsFixed(2)} sq cm', style: const pw.TextStyle(fontSize: 8.5)),
                          ],
                        ),
                      ),
                      _cell(''),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // MAIN COST BREAKDOWN TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.8),
                  1: const pw.FlexColumnWidth(2.2),
                  2: const pw.FlexColumnWidth(2.0),
                },
                children: [
                  _costRow('Eff. Area of Coating', estimate.effectiveCoatingArea > 0 ? numFmt.format(estimate.effectiveCoatingArea) : '-'),
                  _costRow('Diamond requirement', '${numFmt.format(estimate.diamondRequirement)} cts'),
                  _costRow('Diamond cost', numFmt.format(estimate.diamondCost)),
                  _costRow('Blank cost', numFmt.format(estimate.blankCost)),
                  _costRow('Grinding Cost', numFmt.format(estimate.grindingCost)),
                  _costRow('Extraction', numFmt.format(estimate.extractionCost)),
                  _costRow('Balancing Cost', numFmt.format(estimate.balancingCost)),
                  _costRow('Transportation Cost', numFmt.format(estimate.transportationCost)),
                  _dividerRow(),
                  _costRow('Sub-Total(incl margin)', numFmt.format(estimate.subTotalInclMargin), isBold: true),
                  _costRow('Process Cost', numFmt.format(estimate.processCost)),
                  _totalRow('Total', numFmt.format(estimate.totalCost), isBold: true),
                  _costRow('Provision for discount', numFmt.format(estimate.provisionForDiscount)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // PAGE 2: QUOTATION PRICE & TERMS
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        build: (context) {
          final discountStr = estimate.discountPercentage > 0 ? '${estimate.discountPercentage.toStringAsFixed(0)}%' : '10%';
          final minOrdStr = estimate.minOrderQty?.isNotEmpty == true ? estimate.minOrderQty! : '1 set';
          final deliveryStr = estimate.delivery?.isNotEmpty == true ? estimate.delivery! : '4 - 6 Weeks';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(2.0),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  // Row 1: Headers
                  pw.TableRow(
                    children: [
                      _cell('QTN PRICE', isBold: true, align: pw.TextAlign.center),
                      _cell('Discount', isBold: true, align: pw.TextAlign.center),
                      _cell('Min. Ord Qty', isBold: true, align: pw.TextAlign.center),
                      _cell('Delivery', isBold: true, align: pw.TextAlign.center),
                    ],
                  ),
                  // Row 2: Values
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text(
                          numFmt.format(estimate.qtnPrice),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text(
                          discountStr,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text(
                          minOrdStr,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: pw.Text(
                          deliveryStr,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // Row 3: QTN NO & Date
                  pw.TableRow(
                    children: [
                      _cell('QTN NO & Date', isBold: true, align: pw.TextAlign.center),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          estimate.qtnNoAndDate?.isNotEmpty == true ? estimate.qtnNoAndDate! : '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      _cell(''),
                      _cell(''),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(String text, {bool isBold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.TableRow _costRow(String label, String value, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4.5),
          child: pw.Text(''),
        ),
      ],
    );
  }

  static pw.TableRow _totalRow(String label, String value, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 9.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4.5),
          child: pw.Text(''),
        ),
      ],
    );
  }

  static pw.TableRow _dividerRow() {
    return pw.TableRow(
      children: [
        pw.Container(height: 1, color: PdfColors.black),
        pw.Container(height: 1, color: PdfColors.black),
        pw.Container(height: 1, color: PdfColors.black),
      ],
    );
  }

  static Future<void> printOrShare(EstimateModel estimate) async {
    final bytes = await generate(estimate);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'EDP_Estimate_${estimate.calculationNo}.pdf',
    );
  }
}
