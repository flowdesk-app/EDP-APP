import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/estimate_model.dart';

class PdfEstimateApi {
  static Future<Uint8List> generate(EstimateModel estimate) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      logoImage = pw.MemoryImage((await rootBundle.load('assets/images/logo.png')).buffer.asUint8List());
    } catch (_) {}

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Image(logoImage, width: 100, height: 45)
                  else
                    pw.Text('EDP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PRICE ESTIMATION & CALCULATION SHEET', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text('Electro Diamond Products (EDP)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue800),
              pw.SizedBox(height: 8),

              // Reference Row
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Calculation No: ${estimate.calculationNo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(estimate.date)}', style: const pw.TextStyle(fontSize: 11)),
                    if (estimate.jobId != null)
                      pw.Text('Job Card: #${estimate.jobId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Customer & Item Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 100, child: pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Expanded(child: pw.Text(estimate.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900))),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: pw.BoxDecoration(color: PdfColors.blue50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                          child: pw.Text('Type: ${estimate.type}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 100, child: pw.Text('Item Description:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Expanded(child: pw.Text(estimate.itemDescription ?? 'N/A', style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    if (estimate.drawingNo != null && estimate.drawingNo!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.SizedBox(width: 100, child: pw.Text('Drawing No:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                          pw.Text(estimate.drawingNo!, style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Calculations Notes if any
              if (estimate.calculationsNotes != null && estimate.calculationsNotes!.trim().isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Formula / Area Calculations:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 2),
                      pw.Text(estimate.calculationsNotes!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              // Table of Cost Breakdown
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item / Cost Element', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Details / Basis', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10))),
                    ],
                  ),
                  _buildTableRow('Eff. Area of Coating', '${estimate.effectiveCoatingArea.toStringAsFixed(2)} sq cm', '-'),
                  _buildTableRow('Diamond Requirement', '${estimate.diamondRequirement.toStringAsFixed(4)} cts (Grit: ${estimate.gritSize ?? "N/A"}, Factor: ${estimate.factor.toStringAsFixed(2)})', '-'),
                  _buildTableRow('Diamond Cost', '@ Rs. ${estimate.diamondRate.toStringAsFixed(2)} / ct', currencyFmt.format(estimate.diamondCost)),
                  _buildTableRow('Blank Cost', 'Raw Blank Material', currencyFmt.format(estimate.blankCost)),
                  _buildTableRow('Grinding Cost', 'Pre / Post Grinding', currencyFmt.format(estimate.grindingCost)),
                  _buildTableRow('Extraction Cost', 'Stripping / Extraction', currencyFmt.format(estimate.extractionCost)),
                  _buildTableRow('Balancing Cost', 'Dynamic Balancing', currencyFmt.format(estimate.balancingCost)),
                  _buildTableRow('Transportation Cost', 'Freight / Dispatch', currencyFmt.format(estimate.transportationCost)),
                  _buildTableRow('Sub-Total (incl. ${estimate.marginPercentage.toStringAsFixed(0)}% Margin)', 'Direct Costs / ${(1.0 - estimate.marginPercentage / 100).toStringAsFixed(2)}', currencyFmt.format(estimate.subTotalInclMargin), isBold: true, bgColor: PdfColors.grey100),
                  _buildTableRow('Process Cost', 'Plating & Chemical Processing', currencyFmt.format(estimate.processCost)),
                  _buildTableRow('Total Cost', 'Sub-Total + Process Cost', currencyFmt.format(estimate.totalCost), isBold: true, bgColor: PdfColors.grey200),
                  _buildTableRow('Provision for Discount (${estimate.discountProvisionPercentage.toStringAsFixed(0)}%)', 'Total / ${(1.0 - estimate.discountProvisionPercentage / 100).toStringAsFixed(2)}', currencyFmt.format(estimate.provisionForDiscount)),
                ],
              ),
              pw.SizedBox(height: 12),

              // Final Quotation Highlight Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.amber700, width: 1.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('QUOTATION (QTN) PRICE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Rs. ${NumberFormat("#,##,##0").format(estimate.qtnPrice)}',
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Applicable Discount: ${estimate.discountPercentage.toStringAsFixed(0)}%', style: const pw.TextStyle(fontSize: 10)),
                        if (estimate.minOrderQty != null && estimate.minOrderQty!.isNotEmpty)
                          pw.Text('Min. Order Qty: ${estimate.minOrderQty}', style: const pw.TextStyle(fontSize: 10)),
                        if (estimate.delivery != null && estimate.delivery!.isNotEmpty)
                          pw.Text('Delivery Terms: ${estimate.delivery}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Prepared By: EDP Technical Team', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text('Authorized Signatory: Owner / Management', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String title, String detail, String amount, {bool isBold = false, PdfColor? bgColor}) {
    return pw.TableRow(
      decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(detail, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(amount, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
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
