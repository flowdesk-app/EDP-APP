import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum TaxType {
  igst18,
  cgstSgst9,
  lutExempt,
  custom,
}

class TaxInvoiceItem {
  final String description;
  final String hsnCode;
  final int quantity;
  final String unit;
  final double rate;

  TaxInvoiceItem({
    required this.description,
    this.hsnCode = '68042110',
    required this.quantity,
    this.unit = 'No(s)',
    required this.rate,
  });

  double get amount => quantity * rate;
}

class TaxInvoiceData {
  final String invoiceNo;
  final DateTime invoiceDate;
  final String poNo;
  final String placeOfSupply;
  final String reference;
  final String docRef;
  final String deliveryRef;

  final String billToName;
  final String billToAddress;
  final String billToGstin;
  final String billToVendorCode;

  final String shipToName;
  final String shipToAddress;
  final String shipToGstin;
  final String shipToVendorCode;

  final List<TaxInvoiceItem> items;
  final TaxType taxType;
  final double customTaxRate;
  final double? manualRounding;

  TaxInvoiceData({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.poNo,
    required this.placeOfSupply,
    this.reference = '',
    this.docRef = '',
    this.deliveryRef = '',
    required this.billToName,
    required this.billToAddress,
    this.billToGstin = '',
    this.billToVendorCode = '',
    this.shipToName = '',
    this.shipToAddress = '',
    this.shipToGstin = '',
    this.shipToVendorCode = '',
    required this.items,
    this.taxType = TaxType.igst18,
    this.customTaxRate = 18.0,
    this.manualRounding,
  });

  double get subTotal => items.fold<double>(0.0, (sum, item) => sum + item.amount);

  bool get isLutExempt => taxType == TaxType.lutExempt;

  double get taxableAmount => isLutExempt ? 0.0 : subTotal;

  double get igstRate => taxType == TaxType.igst18
      ? 18.0
      : (taxType == TaxType.custom ? customTaxRate : 0.0);

  double get cgstRate => taxType == TaxType.cgstSgst9 ? 9.0 : 0.0;
  double get sgstRate => taxType == TaxType.cgstSgst9 ? 9.0 : 0.0;

  double get igstAmount => (taxType == TaxType.igst18 || taxType == TaxType.custom)
      ? double.parse((subTotal * (igstRate / 100)).toStringAsFixed(2))
      : 0.0;

  double get cgstAmount => taxType == TaxType.cgstSgst9
      ? double.parse((subTotal * 0.09).toStringAsFixed(2))
      : 0.0;

  double get sgstAmount => taxType == TaxType.cgstSgst9
      ? double.parse((subTotal * 0.09).toStringAsFixed(2))
      : 0.0;

  double get totalTaxAmount => isLutExempt ? 0.0 : (igstAmount + cgstAmount + sgstAmount);

  double get rawTotal => subTotal + totalTaxAmount;

  double get rounding {
    if (manualRounding != null) return manualRounding!;
    final rounded = rawTotal.roundToDouble();
    return double.parse((rounded - rawTotal).toStringAsFixed(2));
  }

  double get grandTotal {
    return rawTotal + rounding;
  }
}

class PdfTaxInvoiceApi {
  static const borderSide = pw.BorderSide(color: PdfColors.black, width: 0.8);

  static String numberToWords(double amount) {
    final ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertBelowThousand(int num) {
      if (num == 0) return '';
      if (num < 20) return ones[num];
      if (num < 100) {
        final rem = num % 10;
        return tens[num ~/ 10] + (rem != 0 ? '-${ones[rem]}' : '');
      }
      final rem = num % 100;
      return '${ones[num ~/ 100]} Hundred${rem != 0 ? ' ${convertBelowThousand(rem)}' : ''}';
    }

    final totalRounded = double.parse(amount.toStringAsFixed(2));
    if (totalRounded == 0.0) return 'Rupees Zero Only';

    final intPart = totalRounded.truncate();
    final decPart = ((totalRounded - intPart) * 100).round();

    final parts = <String>[];
    int rem = intPart;

    final crores = rem ~/ 10000000;
    rem %= 10000000;
    if (crores > 0) parts.add('${convertBelowThousand(crores)} Crore');

    final lakhs = rem ~/ 100000;
    rem %= 100000;
    if (lakhs > 0) parts.add('${convertBelowThousand(lakhs)} Lakh');

    final thousands = rem ~/ 1000;
    rem %= 1000;
    if (thousands > 0) parts.add('${convertBelowThousand(thousands)} Thousand');

    if (rem > 0) parts.add(convertBelowThousand(rem));

    var words = 'Rupees ${parts.join(' ')}';
    if (decPart > 0) {
      words += ' and ${convertBelowThousand(decPart)} Paise';
    }
    words += ' Only';
    return words;
  }

  static String formatIndianCurrency(double value) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    final formatted = formatter.format(absVal);
    return isNegative ? '-$formatted' : formatted;
  }

  static Future<Uint8List> generate(TaxInvoiceData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 28, right: 28, top: 24, bottom: 20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Outer border container enclosing all sections, filling remaining vertical space
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Box
                      _buildHeader(),

                      // 2. Metadata Grid (Invoice#, PO#, Place of supply, docRef, etc.)
                      _buildMetaGrid(data),

                      // 3. Bill To / Ship To Header Row
                      _buildBillShipHeader(),

                      // 4. Bill To / Ship To Details Row
                      _buildBillShipDetails(data),

                      // 5. Items Table
                      _buildItemsTable(data),

                      // 6. Totals & Words / Bank / Signatory Section
                      _buildTotalsAndBankSection(data),

                      // 7. HSN/SAC Summary Section (if taxable)
                      if (!data.isLutExempt && data.totalTaxAmount > 0) ...[
                        pw.Container(
                          padding: const pw.EdgeInsets.only(left: 8, top: 7, bottom: 4),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            'HSN/SAC Summary:',
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        _buildHsnSummary(data),
                      ],

                      pw.Spacer(),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 6),

              // 8. Bottom Legal Notice & Contact Footer (outside bordered box)
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: borderSide),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'No.62, Easwaran Koil Street, Porur, Chennai - 600116, India,',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'GSTIN: 33AABFE0399P1Z5, PAN No:: AABFE0399P',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaGrid(TaxInvoiceData data) {
    final dateStr = DateFormat('dd MMM yyyy').format(data.invoiceDate);

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(1.0),
      },
      border: const pw.TableBorder(
        bottom: borderSide,
        verticalInside: borderSide,
      ),
      children: [
        pw.TableRow(
          children: [
            // Left column
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _metaField('Invoice#', data.invoiceNo),
                  pw.SizedBox(height: 3),
                  _metaField('Invoice Date', dateStr),
                  pw.SizedBox(height: 3),
                  _metaField('P.O.#', data.poNo),
                ],
              ),
            ),
            // Right column
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _metaField('Place Of Supply', data.placeOfSupply),
                  if (data.reference.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _metaField('Reference', data.reference),
                  ],
                  if (data.docRef.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _metaField('DOC Ref', data.docRef),
                  ],
                  if (data.deliveryRef.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    _metaField('Delivery', data.deliveryRef),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metaField(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 82,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
        ),
        pw.Text(' : ', style: const pw.TextStyle(fontSize: 8.5)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBillShipHeader() {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(1.0),
      },
      border: const pw.TableBorder(
        bottom: borderSide,
        verticalInside: borderSide,
      ),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: pw.Text(
                'Bill To',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: pw.Text(
                'Ship To',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBillShipDetails(TaxInvoiceData data) {
    final effectiveShipAddr = data.shipToAddress.isNotEmpty
        ? data.shipToAddress
        : data.billToAddress;
    final effectiveShipGstin = data.shipToGstin.isNotEmpty
        ? data.shipToGstin
        : data.billToGstin;
    final effectiveShipVendor = data.shipToVendorCode.isNotEmpty
        ? data.shipToVendorCode
        : data.billToVendorCode;

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(1.0),
      },
      border: const pw.TableBorder(
        bottom: borderSide,
        verticalInside: borderSide,
      ),
      children: [
        pw.TableRow(
          children: [
            // Bill To Details
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    data.billToName,
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  if (data.billToAddress.isNotEmpty) ...[
                    ...data.billToAddress.split(RegExp(r'[\r\n]+')).map(
                          (line) => pw.Text(line.trim(), style: const pw.TextStyle(fontSize: 8.0)),
                        ),
                  ],
                  if (data.billToGstin.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('GSTIN ${data.billToGstin}', style: const pw.TextStyle(fontSize: 8.0)),
                  ],
                  if (data.billToVendorCode.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('Vendor Code ${data.billToVendorCode}', style: const pw.TextStyle(fontSize: 8.0)),
                  ],
                ],
              ),
            ),

            // Ship To Details
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (data.shipToName.isNotEmpty && data.shipToName != data.billToName) ...[
                    pw.Text(
                      data.shipToName,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (effectiveShipAddr.isNotEmpty) ...[
                    ...effectiveShipAddr.split(RegExp(r'[\r\n]+')).map(
                          (line) => pw.Text(line.trim(), style: const pw.TextStyle(fontSize: 8.0)),
                        ),
                  ],
                  if (effectiveShipGstin.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('GSTIN $effectiveShipGstin', style: const pw.TextStyle(fontSize: 8.0)),
                  ],
                  if (effectiveShipVendor.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('Vendor Code $effectiveShipVendor', style: const pw.TextStyle(fontSize: 8.0)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(TaxInvoiceData data) {
    return pw.Table(
      border: const pw.TableBorder(
        bottom: borderSide,
        horizontalInside: borderSide,
        verticalInside: borderSide,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(24.0), // #
        1: pw.FlexColumnWidth(1.0),   // Description (~253 pt)
        2: pw.FixedColumnWidth(64.0), // HSN/SAC
        3: pw.FixedColumnWidth(50.0), // Qty
        4: pw.FixedColumnWidth(72.0), // Rate
        5: pw.FixedColumnWidth(76.0), // Amount
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: borderSide),
          ),
          children: [
            _tableHeaderCell('#', align: pw.TextAlign.center),
            _tableHeaderCell('Description', align: pw.TextAlign.left),
            _tableHeaderCell('HSN/SAC', align: pw.TextAlign.center),
            _tableHeaderCell('Qty', align: pw.TextAlign.center),
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
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                alignment: pw.Alignment.topCenter,
                child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 8.5)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: pw.Text(
                  item.description,
                  style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.2),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                alignment: pw.Alignment.topCenter,
                child: pw.Text(item.hsnCode, style: const pw.TextStyle(fontSize: 8.5)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                alignment: pw.Alignment.topCenter,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.Text(item.unit, style: const pw.TextStyle(fontSize: 8.0)),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  formatIndianCurrency(item.rate),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  formatIndianCurrency(item.amount),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, {required pw.TextAlign align}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : (align == pw.TextAlign.center ? pw.Alignment.center : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTotalsAndBankSection(TaxInvoiceData data) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FixedColumnWidth(262.0), // Exactly matches sum of HSN(64) + Qty(50) + Rate(72) + Amount(76)
      },
      border: const pw.TableBorder(
        verticalInside: borderSide,
      ),
      children: [
        pw.TableRow(
          children: [
            // Left Cell (Words & Bank Details)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total In Words', style: const pw.TextStyle(fontSize: 8.5)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    numberToWords(data.grandTotal),
                    style: pw.TextStyle(
                      fontSize: 9.0,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Bank Details', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('Bank Name: Karur Vysya Bank', style: const pw.TextStyle(fontSize: 8.0)),
                  pw.Text('Branch: Porur, Chennai - 600116', style: const pw.TextStyle(fontSize: 8.0)),
                  pw.Text('A/c No: 1629280000000475', style: const pw.TextStyle(fontSize: 8.0)),
                  pw.Text('A/c Name: Exclusive Diamond Products', style: const pw.TextStyle(fontSize: 8.0)),
                  pw.Text('RTGS/NEFT/IFSC Code: KVBL0001629', style: const pw.TextStyle(fontSize: 8.0)),
                ],
              ),
            ),

            // Right Cell (Totals Box & Signatory Box, each with border bottom)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Totals Rows
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: borderSide),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Column(
                    children: [
                      _totalLine('Sub Total', formatIndianCurrency(data.subTotal)),
                      if (!data.isLutExempt && data.taxableAmount > 0) ...[
                        pw.SizedBox(height: 3),
                        _totalLine('Total Taxable Amount', formatIndianCurrency(data.taxableAmount)),
                      ],
                      if (data.taxType == TaxType.igst18 || data.taxType == TaxType.custom) ...[
                        pw.SizedBox(height: 3),
                        _totalLine(
                          'IGST (${data.igstRate.toStringAsFixed(data.igstRate.truncateToDouble() == data.igstRate ? 0 : 1)}%)',
                          formatIndianCurrency(data.igstAmount),
                        ),
                      ] else if (data.taxType == TaxType.cgstSgst9) ...[
                        pw.SizedBox(height: 3),
                        _totalLine('CGST (9%)', formatIndianCurrency(data.cgstAmount)),
                        pw.SizedBox(height: 3),
                        _totalLine('SGST (9%)', formatIndianCurrency(data.sgstAmount)),
                      ],
                      if (data.rounding != 0.0) ...[
                        pw.SizedBox(height: 3),
                        _totalLine('Rounding', formatIndianCurrency(data.rounding)),
                      ],
                      pw.SizedBox(height: 3),
                      _totalLine(
                        'Total',
                        formatIndianCurrency(data.grandTotal),
                        isBold: true,
                        fontSize: 9.5,
                      ),
                    ],
                  ),
                ),

                // Signatory block
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: borderSide),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'For Exclusive Diamond Products',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 42),
                      pw.Text(
                        'Authorized Signatory',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _totalLine(String label, String value, {bool isBold = false, double fontSize = 8.5}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHsnSummary(TaxInvoiceData data) {
    // Group items by HSN/SAC
    final hsnMap = <String, double>{};
    for (var item in data.items) {
      hsnMap[item.hsnCode] = (hsnMap[item.hsnCode] ?? 0.0) + item.amount;
    }

    final isIgst = data.taxType == TaxType.igst18 || data.taxType == TaxType.custom;

    if (isIgst) {
      // 4-column table for IGST with Rate/Amount in IGST cell
      const colWidths = <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(1.0),   // HSN/SAC (~115 pt)
        1: pw.FixedColumnWidth(165.0), // Taxable Amount
        2: pw.FixedColumnWidth(150.0), // IGST (subdivided into Rate 55 + Amount 95)
        3: pw.FixedColumnWidth(109.0), // Total Tax Amount
      };

      final totalTaxable = hsnMap.values.fold<double>(0.0, (sum, val) => sum + val);
      final totalIgst = double.parse((totalTaxable * (data.igstRate / 100)).toStringAsFixed(2));

      return pw.Table(
        columnWidths: colWidths,
        border: const pw.TableBorder(
          top: borderSide,
          bottom: borderSide,
          horizontalInside: borderSide,
          verticalInside: borderSide,
        ),
        children: [
          // 2-tier Header Row
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('HSN/SAC', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Taxable Amount', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    alignment: pw.Alignment.center,
                    child: pw.Text('IGST', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(top: borderSide)),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 55,
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          alignment: pw.Alignment.center,
                          child: pw.Text('Rate', style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          width: 95,
                          decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Amount', style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total Tax Amount', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),

          // Data Rows
          ...hsnMap.entries.map((entry) {
            final hsn = entry.key;
            final taxable = entry.value;
            final igstAmt = double.parse((taxable * (data.igstRate / 100)).toStringAsFixed(2));

            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(hsn, style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(formatIndianCurrency(taxable), style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 55,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('${data.igstRate.toStringAsFixed(data.igstRate.truncateToDouble() == data.igstRate ? 0 : 1)}%', style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Container(
                      width: 95,
                      decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(formatIndianCurrency(igstAmt), style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(formatIndianCurrency(igstAmt), style: const pw.TextStyle(fontSize: 8.5)),
                ),
              ],
            );
          }),

          // Total Row
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Total', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(formatIndianCurrency(totalTaxable), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 55),
                  pw.Container(
                    width: 95,
                    decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(formatIndianCurrency(totalIgst), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(formatIndianCurrency(totalIgst), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ],
      );
    } else {
      // 5-column table for CGST + SGST
      const colWidths = <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(1.0),   // HSN/SAC (~95 pt)
        1: pw.FixedColumnWidth(125.0), // Taxable Amount
        2: pw.FixedColumnWidth(110.0), // CGST (Rate 45 + Amount 65)
        3: pw.FixedColumnWidth(110.0), // SGST (Rate 45 + Amount 65)
        4: pw.FixedColumnWidth(99.0),  // Total Tax Amount
      };

      final totalTaxable = hsnMap.values.fold<double>(0.0, (sum, val) => sum + val);
      final totalCgst = double.parse((totalTaxable * 0.09).toStringAsFixed(2));
      final totalSgst = double.parse((totalTaxable * 0.09).toStringAsFixed(2));
      final grandTax = totalCgst + totalSgst;

      return pw.Table(
        columnWidths: colWidths,
        border: const pw.TableBorder(
          top: borderSide,
          bottom: borderSide,
          horizontalInside: borderSide,
          verticalInside: borderSide,
        ),
        children: [
          // 2-tier Header Row
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('HSN/SAC', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Taxable Amount', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    alignment: pw.Alignment.center,
                    child: pw.Text('CGST', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(top: borderSide)),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 45,
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          alignment: pw.Alignment.center,
                          child: pw.Text('Rate', style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          width: 65,
                          decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Amount', style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    alignment: pw.Alignment.center,
                    child: pw.Text('SGST', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(top: borderSide)),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 45,
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          alignment: pw.Alignment.center,
                          child: pw.Text('Rate', style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          width: 65,
                          decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Amount', style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total Tax Amount', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),

          // Data Rows
          ...hsnMap.entries.map((entry) {
            final hsn = entry.key;
            final taxable = entry.value;
            final cgstAmt = double.parse((taxable * 0.09).toStringAsFixed(2));
            final sgstAmt = double.parse((taxable * 0.09).toStringAsFixed(2));

            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(hsn, style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(formatIndianCurrency(taxable), style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 45,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('9%', style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Container(
                      width: 65,
                      decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(formatIndianCurrency(cgstAmt), style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 45,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('9%', style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.Container(
                      width: 65,
                      decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(formatIndianCurrency(sgstAmt), style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(formatIndianCurrency(cgstAmt + sgstAmt), style: const pw.TextStyle(fontSize: 8.5)),
                ),
              ],
            );
          }),

          // Total Row
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Total', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(formatIndianCurrency(totalTaxable), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 45),
                  pw.Container(
                    width: 65,
                    decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(formatIndianCurrency(totalCgst), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Container(width: 45),
                  pw.Container(
                    width: 65,
                    decoration: const pw.BoxDecoration(border: pw.Border(left: borderSide)),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(formatIndianCurrency(totalSgst), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(formatIndianCurrency(grandTax), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ],
      );
    }
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Our aggregate turnover does not exceed prescribed limit, hence we are not liable to issue Invoice as per Sub Rule 4 Rule 48 of Central Goods & Services Tax Rules 2017',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Ph: +91-44-42121634, 9840539026, 9677067936, email: exclusivediamondproducts@gmail.com, website: www.exclusivediamondproducts.com',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
            pw.Text(
              '1',
              style: const pw.TextStyle(fontSize: 8.0),
            ),
          ],
        ),
      ],
    );
  }
}
