import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceItem {
  final String description;
  final String hsnCode;
  final int quantity;
  final double rate;

  InvoiceItem({
    required this.description,
    required this.hsnCode,
    required this.quantity,
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
  final String taxLabel; // e.g. "IGST (18%)"

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
  static Future<Uint8List> generate(InvoiceData data) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildHeader(data),
            pw.SizedBox(height: 24),
            _buildAddresses(data),
            pw.SizedBox(height: 24),
            _buildTable(data),
            pw.SizedBox(height: 24),
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

  static pw.Widget _buildHeader(InvoiceData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 30,
                    height: 30,
                    decoration: const pw.BoxDecoration(color: PdfColors.red900, shape: pw.BoxShape.circle),
                    child: pw.Center(child: pw.Text('EDP', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold))),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text('Exclusive Diamond Products', style: pw.TextStyle(color: PdfColors.blue, fontSize: 16, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Exclusive Diamond Products', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Text('No.62, Easwaran Koil Street, Porur,\n(Entry from Balamuragn Koil 2nd St & Behind RABS Engg\nWorks),\nChennai - 600116, India,', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('GSTIN: 33AABFE0399P1Z5, PAN No:: AABFE0399P', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(data.invoiceTitle.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Sales Order# ${data.salesOrderNo} Dt,${DateFormat('dd.MM.yyyy').format(data.salesOrderDate)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(data.billToName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(data.billToAddress, style: const pw.TextStyle(fontSize: 10)),
              if (data.billToGstin.isNotEmpty) pw.Text('GSTIN ${data.billToGstin}', style: const pw.TextStyle(fontSize: 10)),
              if (data.billToVendorCode.isNotEmpty) pw.Text('Vendor Code ${data.billToVendorCode}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Text('Ship To', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(data.shipToAddress.isNotEmpty ? data.shipToAddress : data.billToAddress, style: const pw.TextStyle(fontSize: 10)),
              if (data.shipToGstin.isNotEmpty) pw.Text('GSTIN ${data.shipToGstin}', style: const pw.TextStyle(fontSize: 10)),
              if (data.shipToVendorCode.isNotEmpty) pw.Text('Vendor Code ${data.shipToVendorCode}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Text('Place Of Supply: ${data.placeOfSupply}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.SizedBox(height: 32),
              if (data.orderDate != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Order Date : ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(DateFormat('dd MMM yyyy').format(data.orderDate!), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 8),
              if (data.reference.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ref# : ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(data.reference, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(InvoiceData data) {
    final headers = ['#', 'Item & Description', 'HSN/SAC', 'Qty', 'Rate', 'Amount'];
    
    final tableData = data.items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return [
        '${i + 1}',
        item.description,
        item.hsnCode,
        '${item.quantity}\nNo(s)',
        item.rate.toStringAsFixed(2),
        item.amount.toStringAsFixed(2),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: tableData,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.topCenter,
        1: pw.Alignment.topLeft,
        2: pw.Alignment.topCenter,
        3: pw.Alignment.topRight,
        4: pw.Alignment.topRight,
        5: pw.Alignment.topRight,
      },
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    );
  }

  static pw.Widget _buildTotal(InvoiceData data) {
    final subTotal = data.items.fold<double>(0, (sum, item) => sum + item.amount);
    final taxAmount = subTotal * (data.taxPercentage / 100);
    final total = subTotal + taxAmount;
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        children: [
          pw.Spacer(flex: 3),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Divider(),
                _buildTotalRow('Sub Total', subTotal.toStringAsFixed(2)),
                pw.SizedBox(height: 8),
                _buildTotalRow(data.taxLabel, taxAmount.toStringAsFixed(2)),
                pw.SizedBox(height: 8),
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(8),
                  child: _buildTotalRow('Total', 'Rs. ${total.toStringAsFixed(2)}', isBold: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10)),
        pw.Text(amount, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10)),
      ],
    );
  }
}
