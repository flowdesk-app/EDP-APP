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

    const double colA = 48.4;
    const double colB = 123.0;
    const double colC = 100.5;
    const double colD = 42.7;
    const double colEG = 139.9;
    const double colH = 55.5;

    const borderSide = pw.BorderSide(color: PdfColors.black, width: 0.75);

    pw.Widget cellA(double height) {
      return pw.Container(
        width: colA,
        height: height,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: borderSide,
            bottom: borderSide,
            left: borderSide,
            right: borderSide,
          ),
        ),
      );
    }

    pw.Widget cell({
      required double width,
      required double height,
      required pw.Widget child,
      pw.Alignment alignment = pw.Alignment.centerLeft,
      pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      bool borderRight = true,
      bool borderBottom = true,
      bool borderTop = true,
      bool borderLeft = true,
    }) {
      return pw.Container(
        width: width,
        height: height,
        padding: padding,
        alignment: alignment,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: borderTop ? borderSide : pw.BorderSide.none,
            bottom: borderBottom ? borderSide : pw.BorderSide.none,
            left: borderLeft ? borderSide : pw.BorderSide.none,
            right: borderRight ? borderSide : pw.BorderSide.none,
          ),
        ),
        child: child,
      );
    }

    final calcNoStr = estimate.calculationNo.isNotEmpty ? estimate.calculationNo : '000001089';
    final dateStr = dateFmt.format(estimate.date);
    final customerStr = estimate.customerName.isNotEmpty ? estimate.customerName : 'M/s.';
    final itemDescStr = estimate.itemDescription?.isNotEmpty == true ? estimate.itemDescription! : '';
    final drgNoStr = estimate.drawingNo?.isNotEmpty == true ? 'DRG No: ${estimate.drawingNo}' : '';
    final typeStr = estimate.type.isNotEmpty ? estimate.type : 'R';

    String calcNotesStr;
    if (estimate.calculationsNotes != null && estimate.calculationsNotes!.isNotEmpty) {
      calcNotesStr = estimate.calculationsNotes!;
    } else if (estimate.effectiveCoatingArea > 0) {
      calcNotesStr = 'Area = ${estimate.effectiveCoatingArea.toStringAsFixed(2)} sq.cm';
    } else {
      calcNotesStr = '';
    }

    // PAGE 1: PRICE CALCULATION SHEET (exact format matching the official quotation sheet)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.only(left: 50.4, top: 40.0, right: 51.6, bottom: 40.0),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Row 1: Calculation No & Date (h=15.8)
              pw.Row(
                children: [
                  cellA(15.8),
                  cell(
                    width: colB,
                    height: 15.8,
                    child: pw.Text('Calulation No:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: colC,
                    height: 15.8,
                    child: pw.Text(calcNoStr, style: const pw.TextStyle(fontSize: 11.5)),
                  ),
                  cell(
                    width: colD,
                    height: 15.8,
                    child: pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: colEG + colH,
                    height: 15.8,
                    child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),

              // Row 2: Customer (h=26.0)
              pw.Row(
                children: [
                  cellA(26.0),
                  cell(
                    width: colB,
                    height: 26.0,
                    borderTop: false,
                    child: pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: colC + colD + colEG + colH,
                    height: 26.0,
                    borderTop: false,
                    child: pw.ClipRect(
                      child: pw.Text(
                        customerStr,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),

              // Row 3: Item Description Header (h=14.6)
              pw.Row(
                children: [
                  cellA(14.6),
                  cell(
                    width: colB + colC + colD + colEG,
                    height: 14.6,
                    borderTop: false,
                    child: pw.Text(
                      'Item Description:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8, decoration: pw.TextDecoration.underline),
                    ),
                  ),
                  cell(
                    width: colH,
                    height: 14.6,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                ],
              ),

              // Rows 4-7: Item Description text + DRG No + Type 'R' / 'N' (h=58.9)
              pw.Row(
                children: [
                  cellA(58.9),
                  cell(
                    width: colB + colC + colD + colEG,
                    height: 58.9,
                    borderTop: false,
                    alignment: pw.Alignment.topLeft,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: pw.ClipRect(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (itemDescStr.isNotEmpty)
                            pw.Text(
                              itemDescStr,
                              style: const pw.TextStyle(fontSize: 8.8, lineSpacing: 1.2),
                              maxLines: 3,
                              overflow: pw.TextOverflow.clip,
                            ),
                          if (drgNoStr.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              drgNoStr,
                              style: pw.TextStyle(fontSize: 8.8, fontWeight: pw.FontWeight.bold),
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  cell(
                    width: colH,
                    height: 58.9,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text(typeStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 36)),
                  ),
                ],
              ),

              // Rows 8-19: Drawing (h=142.0)
              pw.Row(
                children: [
                  cellA(142.0),
                  cell(
                    width: colB + colC + colD + colEG + colH,
                    height: 142.0,
                    borderTop: false,
                    alignment: pw.Alignment.topLeft,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Drawing:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                        pw.SizedBox(height: 10),
                        pw.Text('SEE OVERLEAF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                        if (estimate.drawingNo?.isNotEmpty == true) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('DRG No: ${estimate.drawingNo}', style: const pw.TextStyle(fontSize: 9.0)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Row 20: Calculations Header (h=15.4)
              pw.Row(
                children: [
                  cellA(15.4),
                  cell(
                    width: colB + colC + colD + colEG + colH,
                    height: 15.4,
                    borderTop: false,
                    child: pw.Text('Calculations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                ],
              ),

              // Rows 21-25: Calculations Notes (h=55.0)
              pw.Row(
                children: [
                  cellA(55.0),
                  cell(
                    width: colB + colC + colD + colEG + colH,
                    height: 55.0,
                    borderTop: false,
                    alignment: pw.Alignment.topLeft,
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.ClipRect(
                      child: pw.Text(
                        calcNotesStr,
                        style: const pw.TextStyle(fontSize: 9.0),
                        maxLines: 3,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),

              // Rows 26-38: 13 Cost breakdown rows (each h=24.0)
              ...[
                {'label': 'Eff. Area of Coating', 'val': estimate.effectiveCoatingArea > 0 ? numFmt.format(estimate.effectiveCoatingArea) : '', 'unit': '', 'bold': false},
                {'label': 'Diamond requirement', 'val': estimate.diamondRequirement > 0 ? numFmt.format(estimate.diamondRequirement) : '', 'unit': estimate.diamondRequirement > 0 ? 'cts' : '', 'bold': false},
                {'label': 'Diamond cost', 'val': numFmt.format(estimate.diamondCost), 'unit': '', 'bold': false},
                {'label': 'Blank cost', 'val': numFmt.format(estimate.blankCost), 'unit': '', 'bold': false},
                {'label': 'Grinding Cost', 'val': numFmt.format(estimate.grindingCost), 'unit': '', 'bold': false},
                {'label': 'Extraction', 'val': numFmt.format(estimate.extractionCost), 'unit': '', 'bold': false},
                {'label': 'Balancing Cost', 'val': numFmt.format(estimate.balancingCost), 'unit': '', 'bold': false},
                {'label': 'Transportation Cost', 'val': numFmt.format(estimate.transportationCost), 'unit': '', 'bold': false},
                {'label': '', 'val': '', 'unit': '', 'bold': false}, // Empty divider row
                {'label': 'Sub-Total(incl margin)', 'val': numFmt.format(estimate.subTotalInclMargin), 'unit': '', 'bold': true},
                {'label': 'Process Cost', 'val': numFmt.format(estimate.processCost), 'unit': '', 'bold': false},
                {'label': 'Total', 'val': numFmt.format(estimate.totalCost), 'unit': '', 'bold': true, 'total': true},
                {'label': 'Provision for discount', 'val': numFmt.format(estimate.provisionForDiscount), 'unit': '', 'bold': false},
              ].map((r) {
                final isTotal = r['total'] == true;
                final isBold = r['bold'] == true;
                final label = r['label'] as String;
                final val = r['val'] as String;
                final unit = r['unit'] as String;

                return pw.Row(
                  children: [
                    cellA(24.0),
                    cell(
                      width: colB,
                      height: 24.0,
                      borderTop: false,
                      alignment: isTotal ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                      child: pw.Text(
                        label,
                        style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 9.8),
                      ),
                    ),
                    cell(
                      width: colC,
                      height: 24.0,
                      borderTop: false,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        val,
                        style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 9.8),
                      ),
                    ),
                    cell(
                      width: colD,
                      height: 24.0,
                      borderTop: false,
                      child: pw.Text(unit, style: const pw.TextStyle(fontSize: 9.8)),
                    ),
                    cell(
                      width: colEG,
                      height: 24.0,
                      borderTop: false,
                      child: pw.Text(''),
                    ),
                    cell(
                      width: colH,
                      height: 24.0,
                      borderTop: false,
                      child: pw.Text(''),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    // PAGE 2: QUOTATION TERMS
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.only(left: 50.4, top: 40.0, right: 51.6, bottom: 40.0),
        build: (context) {
          const double p2ColDEF = 133.8;
          const double p2ColGH = 104.3;

          final displayQtn = estimate.qtnPrice > 0 ? estimate.qtnPrice : estimate.provisionForDiscount;
          final discountStr = estimate.discountPercentage > 0 ? '${estimate.discountPercentage.toStringAsFixed(0)}%' : '-';
          final minOrdStr = estimate.minOrderQty?.isNotEmpty == true ? estimate.minOrderQty! : '1 set';
          final deliveryStr = estimate.delivery?.isNotEmpty == true ? estimate.delivery! : '4 - 6 Weeks';
          final qtnNoAndDateStr = estimate.qtnNoAndDate?.isNotEmpty == true ? estimate.qtnNoAndDate! : '';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Row 1: Header (h=24.5)
              pw.Row(
                children: [
                  cellA(24.5),
                  cell(
                    width: colB,
                    height: 24.5,
                    alignment: pw.Alignment.center,
                    child: pw.Text('QTN PRICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: colC,
                    height: 24.5,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Discount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: p2ColDEF,
                    height: 24.5,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Min. Ord Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: p2ColGH,
                    height: 24.5,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Delivery', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                ],
              ),

              // Row 2: Values (h=24.5)
              pw.Row(
                children: [
                  cellA(24.5),
                  cell(
                    width: colB,
                    height: 24.5,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      numFmt.format(displayQtn),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.6),
                    ),
                  ),
                  cell(
                    width: colC,
                    height: 24.5,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      discountStr,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.6),
                    ),
                  ),
                  cell(
                    width: p2ColDEF,
                    height: 24.5,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      minOrdStr,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.6),
                    ),
                  ),
                  cell(
                    width: p2ColGH,
                    height: 24.5,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      deliveryStr,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.6),
                    ),
                  ),
                ],
              ),

              // Row 3: QTN NO & Date (h=26.3)
              pw.Row(
                children: [
                  cellA(26.3),
                  cell(
                    width: colB,
                    height: 26.3,
                    borderTop: false,
                    alignment: pw.Alignment.center,
                    child: pw.Text('QTN NO & Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.8)),
                  ),
                  cell(
                    width: colC + p2ColDEF + p2ColGH,
                    height: 26.3,
                    borderTop: false,
                    child: pw.Text(qtnNoAndDateStr, style: const pw.TextStyle(fontSize: 10)),
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

  static Future<void> printOrShare(EstimateModel estimate) async {
    final bytes = await generate(estimate);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'EDP_Estimate_${estimate.calculationNo}.pdf',
    );
  }
}
