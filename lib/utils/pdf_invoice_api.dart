import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceItem {
  final String? title;
  final String description;
  final String hsnCode;
  final int quantity;
  final String unit;
  final double rate;

  InvoiceItem({
    this.title,
    required this.description,
    required this.hsnCode,
    required this.quantity,
    this.unit = 'No(s)',
    required this.rate,
  });

  double get amount => quantity * rate;
}

class InvoiceData {
  final String invoiceTitle;
  final String salesOrderNo;
  final DateTime salesOrderDate;
  
  final String billToName;
  final String billToAddress;
  final String billToGstin;
  final String billToVendorCode;
  
  final String shipToName;
  final String shipToAddress;
  final String shipToGstin;
  final String shipToVendorCode;

  final String placeOfSupply;
  final DateTime? orderDate;
  final String reference;

  final List<InvoiceItem> items;
  final double taxPercentage;
  final String taxLabel; // e.g. "IGST (18%)" or "CGST (9%) + SGST (9%)"

  InvoiceData({
    required this.invoiceTitle,
    required this.salesOrderNo,
    required this.salesOrderDate,
    required this.billToName,
    required this.billToAddress,
    required this.billToGstin,
    required this.billToVendorCode,
    required this.shipToName,
    required this.shipToAddress,
    required this.shipToGstin,
    required this.shipToVendorCode,
    required this.placeOfSupply,
    required this.orderDate,
    required this.reference,
    required this.items,
    required this.taxPercentage,
    required this.taxLabel,
  });
}

class PdfInvoiceApi {
  static final _cDarkHeader = PdfColor.fromHex('383B3E');
  static final _cGreyDivider = PdfColor.fromHex('D0D0D0');
  static final _cBottomDivider = PdfColor.fromHex('C8C8C8');
  static final _cLightShade = PdfColor.fromHex('F2F2F2');
  static final _cTextDark = PdfColor.fromHex('111111');
  static final _cTextBody = PdfColor.fromHex('222222');
  static final _cTextMedium = PdfColor.fromHex('333333');
  static final _cTextLight = PdfColor.fromHex('444444');
  static final _cTextDesc = PdfColor.fromHex('404040');
  static final _cTextSub = PdfColor.fromHex('555555');
  static final _cTextMuted = PdfColor.fromHex('666666');

  static const _rupeeSvg = '''
<svg viewBox="0 0 24 24" width="12" height="12">
  <path fill="#000000" d="M13.66 7C13.1 5.83 11.9 5 10.5 5H6V3h12v2h-3.26c.48.58.84 1.26 1.05 2H18v2h-2.02c-.25 2.8-2.61 5-5.48 5h-.73l6.73 7H13.8l-6.3-6.55V12h3c2.21 0 4-1.79 4-4v-.01z"/>
</svg>
''';

  static String formatIndianCurrency(double value) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    final formatted = formatter.format(absVal);
    return isNegative ? '-$formatted' : formatted;
  }

  static Future<Uint8List> generate(InvoiceData data) async {
    try {
      final pdf = pw.Document();
      
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
        logoImage = pw.MemoryImage(logoBytes);
      } catch (_) {
        try {
          final file = File('assets/images/logo.png');
          if (file.existsSync()) {
            logoImage = pw.MemoryImage(file.readAsBytesSync());
          }
        } catch (_) {}
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(left: 36, right: 36, top: 32, bottom: 24),
          footer: (context) => pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(thickness: 0.5, color: _cBottomDivider),
              pw.SizedBox(height: 4),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${context.pageNumber}',
                  style: pw.TextStyle(fontSize: 8.5, color: _cTextMuted),
                ),
              ),
            ],
          ),
          build: (context) => [
            _buildHeader(data, logoImage),
            pw.SizedBox(height: 20),
            _buildAddresses(data),
            pw.SizedBox(height: 22),
            _buildTable(data),
            pw.SizedBox(height: 14),
            _buildTotal(data),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Text('PDF Generation Error: $e\n$stack'),
        ),
      );
      return await pdf.save();
    }
  }

  static pw.Widget _buildHeader(InvoiceData data, pw.MemoryImage? logoImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Image(logoImage, height: 38)
              else
                pw.Text(
                  'Exclusive Diamond Products',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Exclusive Diamond Products',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: _cTextBody),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'No.62, Easwaran Koil Street, Porur,\n(Entry from Balamuragn Koil 2nd St & Behind RABS Engg\nWorks),\nChennai - 600116, India,\nGSTIN: 33AABFE0399P1Z5, PAN No:: AABFE0399P',
                style: pw.TextStyle(fontSize: 8.5, lineSpacing: 1.2, color: _cTextMedium),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                data.invoiceTitle.toUpperCase(),
                style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: _cTextDark),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Sales Order# ${data.salesOrderNo} Dt,${DateFormat('dd.MM.yyyy').format(data.salesOrderDate)}',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _cTextDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAddresses(InvoiceData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Bill To, Ship To, Place of Supply
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To', style: pw.TextStyle(fontSize: 9.0, color: _cTextLight)),
              pw.SizedBox(height: 2),
              pw.Text(
                data.billToName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: _cTextDark),
              ),
              if (data.billToAddress.isNotEmpty)
                ...data.billToAddress.split(RegExp(r'[\r\n]+')).map(
                  (line) => pw.Text(line.trim(), style: pw.TextStyle(fontSize: 8.5, color: _cTextMedium)),
                ),
              if (data.billToGstin.isNotEmpty)
                pw.Text('GSTIN ${data.billToGstin}', style: pw.TextStyle(fontSize: 8.5, color: _cTextMedium)),
              if (data.billToVendorCode.isNotEmpty)
                pw.Text('Vendor Code ${data.billToVendorCode}', style: pw.TextStyle(fontSize: 8.5, color: _cTextMedium)),

              pw.SizedBox(height: 12),
              pw.Text('Ship To', style: pw.TextStyle(fontSize: 9.0, color: _cTextLight)),
              pw.SizedBox(height: 2),
              if (data.shipToName.isNotEmpty && data.shipToName != data.billToName)
                pw.Text(
                  data.shipToName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: _cTextDark),
                ),
              if (data.shipToAddress.isNotEmpty)
                ...data.shipToAddress.split(RegExp(r'[\r\n]+')).map(
                  (line) => pw.Text(line.trim(), style: pw.TextStyle(fontSize: 8.5, color: _cTextMedium)),
                ),
              if (data.shipToGstin.isNotEmpty)
                pw.Text('GSTIN ${data.shipToGstin}', style: pw.TextStyle(fontSize: 8.5, color: _cTextMedium)),
              if (data.shipToVendorCode.isNotEmpty)
                pw.Text('Vendor Code ${data.shipToVendorCode}', style: pw.TextStyle(fontSize: 8.5, color: _cTextMedium)),

              pw.SizedBox(height: 12),
              pw.Text(
                'Place Of Supply: ${data.placeOfSupply}',
                style: pw.TextStyle(fontSize: 9.0, color: _cTextBody),
              ),
            ],
          ),
        ),

        // Right Column: Order Date & Ref#
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.SizedBox(height: 44),
              if (data.orderDate != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Order Date : ', style: pw.TextStyle(fontSize: 9.0, color: _cTextMedium)),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      DateFormat('dd MMM yyyy').format(data.orderDate!),
                      style: pw.TextStyle(fontSize: 9.0, color: _cTextDark),
                    ),
                  ],
                ),
              if (data.reference.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ref# : ', style: pw.TextStyle(fontSize: 9.0, color: _cTextMedium)),
                    pw.SizedBox(width: 8),
                    pw.Flexible(
                      child: pw.Text(
                        data.reference,
                        style: pw.TextStyle(fontSize: 9.0, color: _cTextDark),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(InvoiceData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(26.0), // #
            1: pw.FlexColumnWidth(1.0),   // Item & Description
            2: pw.FixedColumnWidth(75.0), // HSN/SAC
            3: pw.FixedColumnWidth(55.0), // Qty
            4: pw.FixedColumnWidth(75.0), // Rate
            5: pw.FixedColumnWidth(82.0), // Amount
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: _cDarkHeader,
              ),
              children: [
                _tableHeaderCell('#', align: pw.TextAlign.center),
                _tableHeaderCell('Item & Description', align: pw.TextAlign.left),
                _tableHeaderCell('HSN/SAC', align: pw.TextAlign.center),
                _tableHeaderCell('Qty', align: pw.TextAlign.right),
                _tableHeaderCell('Rate', align: pw.TextAlign.right),
                _tableHeaderCell('Amount', align: pw.TextAlign.right),
              ],
            ),

            // Item Rows
            ...data.items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;

              return pw.TableRow(
                children: [
                  // #
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    alignment: pw.Alignment.topCenter,
                    child: pw.Text('$idx', style: pw.TextStyle(fontSize: 9.0, color: _cTextDark)),
                  ),

                  // Item & Description
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (item.title != null && item.title!.trim().isNotEmpty) ...[
                          pw.Text(
                            item.title!.trim(),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9.5,
                              color: _cTextDark,
                            ),
                          ),
                          if (item.description.trim().isNotEmpty) pw.SizedBox(height: 3),
                        ],
                        if (item.description.trim().isNotEmpty)
                          pw.Text(
                            item.description.trim(),
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: _cTextDesc,
                              lineSpacing: 1.25,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // HSN/SAC
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    alignment: pw.Alignment.topCenter,
                    child: pw.Text(
                      item.hsnCode,
                      style: pw.TextStyle(fontSize: 9.0, color: _cTextDark),
                    ),
                  ),

                  // Qty
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    alignment: pw.Alignment.topRight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          '${item.quantity}',
                          style: pw.TextStyle(fontSize: 9.0, color: _cTextDark),
                        ),
                        pw.Text(
                          item.unit,
                          style: pw.TextStyle(fontSize: 8.0, color: _cTextSub),
                        ),
                      ],
                    ),
                  ),

                  // Rate
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    alignment: pw.Alignment.topRight,
                    child: pw.Text(
                      formatIndianCurrency(item.rate),
                      style: pw.TextStyle(fontSize: 9.0, color: _cTextDark),
                    ),
                  ),

                  // Amount
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    alignment: pw.Alignment.topRight,
                    child: pw.Text(
                      formatIndianCurrency(item.amount),
                      style: pw.TextStyle(fontSize: 9.0, color: _cTextDark),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),

        // Clean full-width horizontal divider line under the table items
        pw.Divider(thickness: 0.5, color: _cGreyDivider),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, {required pw.TextAlign align}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9.5,
        ),
      ),
    );
  }

  static pw.Widget _buildTotal(InvoiceData data) {
    final subTotal = data.items.fold<double>(0, (sum, item) => sum + item.amount);
    final taxAmount = subTotal * (data.taxPercentage / 100);
    final total = subTotal + taxAmount;

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Sub Total row
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sub Total', style: pw.TextStyle(fontSize: 9.5, color: _cTextBody)),
                  pw.Text(formatIndianCurrency(subTotal), style: pw.TextStyle(fontSize: 9.5, color: _cTextBody)),
                ],
              ),
            ),
            pw.SizedBox(height: 4),

            // Tax row
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(data.taxLabel, style: pw.TextStyle(fontSize: 9.5, color: _cTextBody)),
                  pw.Text(formatIndianCurrency(taxAmount), style: pw.TextStyle(fontSize: 9.5, color: _cTextBody)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),

            // Shaded Total Container
            pw.Container(
              decoration: pw.BoxDecoration(
                color: _cLightShade,
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.black),
                  ),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.SvgImage(svg: _rupeeSvg, width: 8.5, height: 8.5),
                      pw.SizedBox(width: 2.5),
                      pw.Text(
                        formatIndianCurrency(total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
