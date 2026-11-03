import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/payroll_model.dart';

class PayrollPdfService {
  static final NumberFormat _currFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

  // ============================================================
  // 1. INDIVIDUAL EMPLOYEE PAYSLIP PDF (Exact Replica of Document 4)
  // ============================================================
  static Future<Uint8List> generatePayslipPdf(PayrollRecord emp, {String? month}) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final byteData = await rootBundle.load('assets/images/edp_logo.png');
      logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {}

    final payslip = OfficialPayslipModel.fromPayrollRecord(emp, month: month);

    String fmtAmt(double val, {bool showDashIfZero = false}) {
      if (val <= 0.001) return showDashIfZero ? '-' : '';
      if (val % 1 == 0) {
        return _intFmt.format(val);
      }
      return _currFmt.format(val);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.0),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Header (Logo on left, Centered Address & Pay Slip Month & Name, Balanced right)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 130,
                      height: 50,
                      alignment: pw.Alignment.centerLeft,
                      child: logoImage != null
                          ? pw.Image(logoImage, width: 125, height: 46, fit: pw.BoxFit.contain)
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text('EDP', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B'))),
                                pw.Text('Exclusive Diamond Products', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                              ],
                            ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'No.62, Eswaran Koil Street',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                          pw.SizedBox(height: 1.5),
                          pw.Text(
                            'Porur, Chennai - 600116',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Pay Slip - ${payslip.monthTitle}',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            payslip.employeeName.toUpperCase(),
                            style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 130), // Symmetrical right balance
                  ],
                ),
                pw.SizedBox(height: 10),

                // Table 1: Employee Details (4 columns)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.2),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FlexColumnWidth(1.2),
                    3: pw.FlexColumnWidth(1.8),
                  },
                  children: [
                    _pdfDetailRow('Employee No.', payslip.empNo, 'PAN No.', payslip.panNo),
                    _pdfDetailRow('Designation', payslip.designation, 'PF No.', payslip.pfNo),
                    _pdfDetailRow('Department', payslip.department, 'ESI No.', payslip.esiNo),
                    _pdfDetailRow('Date of Joining', payslip.doj, 'Bank A/c No.', payslip.bankAccountNo),
                  ],
                ),

                // Table 2: Attendance Information (8 columns)
                pw.Table(
                  border: const pw.TableBorder(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.1),
                    1: pw.FlexColumnWidth(0.9),
                    2: pw.FlexColumnWidth(1.1),
                    3: pw.FlexColumnWidth(0.9),
                    4: pw.FlexColumnWidth(1.1),
                    5: pw.FlexColumnWidth(0.9),
                    6: pw.FlexColumnWidth(1.3),
                    7: pw.FlexColumnWidth(1.1),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        _pdfCell('Leave', isBold: true),
                        _pdfCell(payslip.leave, align: pw.TextAlign.center),
                        _pdfCell('Balance', isBold: true),
                        _pdfCell(payslip.balance, align: pw.TextAlign.center),
                        _pdfCell('LOP', isBold: true),
                        _pdfCell(payslip.lop, align: pw.TextAlign.center),
                        _pdfCell('OT Hours', isBold: true),
                        _pdfCell(payslip.otHours, align: pw.TextAlign.center),
                      ],
                    ),
                  ],
                ),

                // Table 3: Earnings & Deductions (4 columns)
                pw.Table(
                  border: const pw.TableBorder(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.8),
                    1: pw.FlexColumnWidth(1.2),
                    2: pw.FlexColumnWidth(1.8),
                    3: pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      children: [
                        _pdfCell('Earnings', isBold: true),
                        _pdfCell('Amount (Rs.)', isBold: true, align: pw.TextAlign.right),
                        _pdfCell('Deductions', isBold: true),
                        _pdfCell('Amount (Rs.)', isBold: true, align: pw.TextAlign.right),
                      ],
                    ),
                    // 8 Official Item Rows
                    _pdfItemRow('Basic', fmtAmt(payslip.basic), 'PF', fmtAmt(payslip.pf)),
                    _pdfItemRow('HRA', fmtAmt(payslip.hra), 'ESI', fmtAmt(payslip.esi, showDashIfZero: true)),
                    _pdfItemRow('Lunch', fmtAmt(payslip.lunch), 'TDS', fmtAmt(payslip.tds)),
                    _pdfItemRow('Transport', fmtAmt(payslip.transport), 'Prof Tax', fmtAmt(payslip.profTax)),
                    _pdfItemRow('Medical', fmtAmt(payslip.medical), 'Advance/Loan', fmtAmt(payslip.advanceLoan)),
                    _pdfItemRow('Special Allowance', fmtAmt(payslip.specialAllowance), 'Insurance', fmtAmt(payslip.insurance)),
                    _pdfItemRow('Overtime', fmtAmt(payslip.overtime), 'Other Deductions', fmtAmt(payslip.otherDeductions)),
                    _pdfItemRow('Other Allowance*', fmtAmt(payslip.otherAllowance), '', ''),
                    // Totals Row
                    pw.TableRow(
                      children: [
                        _pdfCell('Total', isBold: true),
                        _pdfCell(fmtAmt(payslip.totalEarnings), isBold: true, align: pw.TextAlign.right),
                        _pdfCell('Total', isBold: true),
                        _pdfCell(fmtAmt(payslip.totalDeductions), isBold: true, align: pw.TextAlign.right),
                      ],
                    ),
                  ],
                ),

                // Net Salary Box
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Net Salary',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        fmtAmt(payslip.netSalary),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 7),

                // Footnote
                pw.Text(
                  '*Includes Arrears if any. Computer generated statement and signature not required',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPayslipPdf(PayrollRecord emp, {String? month}) async {
    final bytes = await generatePayslipPdf(emp, month: month);
    final payslip = OfficialPayslipModel.fromPayrollRecord(emp, month: month);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Payslip_${payslip.empNo}_${payslip.employeeName.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> downloadPayslipPdf(PayrollRecord emp, {String? month}) async {
    final bytes = await generatePayslipPdf(emp, month: month);
    final payslip = OfficialPayslipModel.fromPayrollRecord(emp, month: month);
    final fileName = 'Payslip_${payslip.empNo}_${payslip.employeeName.replaceAll(' ', '_')}_${payslip.monthTitle.replaceAll(' ', '_')}.pdf';
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  static pw.TableRow _pdfDetailRow(String l1, String v1, String l2, String v2) {
    return pw.TableRow(
      children: [
        _pdfCell(l1, isBold: true),
        _pdfCell(v1),
        _pdfCell(l2, isBold: true),
        _pdfCell(v2),
      ],
    );
  }

  static pw.TableRow _pdfItemRow(String earnLabel, String earnVal, String dedLabel, String dedVal) {
    return pw.TableRow(
      children: [
        _pdfCell(earnLabel),
        _pdfCell(earnVal, align: pw.TextAlign.right),
        _pdfCell(dedLabel),
        _pdfCell(dedVal, align: pw.TextAlign.right),
      ],
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.center
              ? pw.Alignment.center
              : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }

  // ============================================================
  // 2. MASTER SALARY STATEMENT PDF (Landscape - Matches Doc 1)
  // ============================================================
  static Future<Uint8List> generateMasterStatementPdf(
    List<PayrollRecord> records,
    Map<String, dynamic> totals,
    String monthDisplay,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'EXCLUSIVE DIAMOND PRODUCTS',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              ),
              pw.Text(
                'No.62, Eswaran Koil Street, Porur, Chennai 600116',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                color: PdfColors.blueGrey100,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: pw.Text(
                  'SALARY STATEMENT FOR THE MONTH OF ${monthDisplay.toUpperCase()}',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 6),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20), // S.No
                1: const pw.FixedColumnWidth(35), // Emp No
                2: const pw.FixedColumnWidth(95), // Name
                3: const pw.FixedColumnWidth(75), // Designation
                4: const pw.FixedColumnWidth(40), // Basic
                5: const pw.FixedColumnWidth(35), // DA
                6: const pw.FixedColumnWidth(35), // HRA
                7: const pw.FixedColumnWidth(30), // Conv
                8: const pw.FixedColumnWidth(35), // Med
                9: const pw.FixedColumnWidth(45), // Other
                10: const pw.FixedColumnWidth(45), // OT Amt
                11: const pw.FixedColumnWidth(50), // Gross
                12: const pw.FixedColumnWidth(35), // PF
                13: const pw.FixedColumnWidth(30), // ESI
                14: const pw.FixedColumnWidth(35), // Loan
                15: const pw.FixedColumnWidth(35), // Ins
                16: const pw.FixedColumnWidth(45), // Total Ded
                17: const pw.FixedColumnWidth(55), // Net Pay
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey200),
                  children: [
                    _th('#'),
                    _th('CODE'),
                    _th('EMPLOYEE NAME'),
                    _th('DESIGNATION'),
                    _th('BASIC'),
                    _th('D.A.'),
                    _th('H.R.A.'),
                    _th('CONV'),
                    _th('MED'),
                    _th('OTHER'),
                    _th('O.T.'),
                    _th('GROSS'),
                    _th('P.F.'),
                    _th('E.S.I.'),
                    _th('LOAN'),
                    _th('INS'),
                    _th('DEDUCT'),
                    _th('NET PAY'),
                  ],
                ),
                // Employee Rows
                ...records.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final r = entry.value;
                  final isEven = idx % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
                    children: [
                      _td('$idx', align: pw.TextAlign.center),
                      _td(r.empNo, align: pw.TextAlign.center),
                      _td(r.employeeName),
                      _td(r.designation),
                      _td(_intFmt.format(r.basic), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.da), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.hra), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.conveyance), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.medicalAlw), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.otherAlw), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.otAmount), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.grossSalary), align: pw.TextAlign.right, isBold: true),
                      _td(_intFmt.format(r.pf), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.esi), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.advanceLoan), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.insurance), align: pw.TextAlign.right),
                      _td(_intFmt.format(r.totalDeductions), align: pw.TextAlign.right),
                      _td(_currFmt.format(r.netSalary), align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
                // Grand Totals Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                  children: [
                    _td('', align: pw.TextAlign.center),
                    _td('', align: pw.TextAlign.center),
                    _td('GRAND TOTAL', isBold: true),
                    _td('${records.length} Staff', isBold: true),
                    _td(_intFmt.format(totals['basic'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['da'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['hra'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['conveyance'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['medicalAlw'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['otherAlw'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['otAmount'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['grossSalary'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['pf'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['esi'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['advanceLoan'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['insurance'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_intFmt.format(totals['totalDeductions'] ?? 0), align: pw.TextAlign.right, isBold: true),
                    _td(_currFmt.format(totals['netSalary'] ?? 0), align: pw.TextAlign.right, isBold: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text('Prepared By (Accounts)', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text('Verified By (Admin)', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey700),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printMasterStatementPdf(
    List<PayrollRecord> records,
    Map<String, dynamic> totals,
    String monthDisplay,
  ) async {
    final bytes = await generateMasterStatementPdf(records, totals, monthDisplay);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Salary_Statement_${monthDisplay.replaceAll(' ', '_')}.pdf',
    );
  }

  // ============================================================
  // 3. ONLINE BANK TRANSFER REGISTER PDF (Matches Doc 2)
  // ============================================================
  static Future<Uint8List> generateBankTransferPdf(
    List<BankTransferRecord> transfers,
    double totalAmount,
    String monthDisplay,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'EXCLUSIVE DIAMOND PRODUCTS',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'NO: 62, ESWARAN KOIL STREET, PORUR, CHENNAI - 600116.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                color: PdfColors.blueGrey100,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Center(
                  child: pw.Text(
                    'ONLINE BANK TRANSFER FOR THE MONTH OF ${monthDisplay.toUpperCase()}',
                    style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FixedColumnWidth(140),
                  3: const pw.FixedColumnWidth(120),
                  4: const pw.FixedColumnWidth(110),
                  5: const pw.FixedColumnWidth(80),
                  6: const pw.FixedColumnWidth(80),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey200),
                    children: [
                      _th('Sl.No'),
                      _th('EMP CODE'),
                      _th('NAME OF EMPLOYEE'),
                      _th('BANK NAME'),
                      _th('A/C NO'),
                      _th('IFSC CODE'),
                      _th('AMOUNT (Rs.)'),
                    ],
                  ),
                  ...transfers.map((t) {
                    final isEven = t.slNo % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
                      children: [
                        _td('${t.slNo}', align: pw.TextAlign.center),
                        _td(t.empNo, align: pw.TextAlign.center),
                        _td(t.employeeName),
                        _td(t.bankName),
                        _td(t.accountNo),
                        _td(t.ifscCode),
                        _td(_currFmt.format(t.amount), align: pw.TextAlign.right, isBold: true),
                      ],
                    );
                  }),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                    children: [
                      _td(''),
                      _td(''),
                      _td('GRAND TOTAL', isBold: true),
                      _td(''),
                      _td(''),
                      _td('${transfers.length} Staff', isBold: true, align: pw.TextAlign.center),
                      _td('Rs. ${_currFmt.format(totalAmount)}', align: pw.TextAlign.right, isBold: true),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Total in words
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('Amount in Words: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    pw.Expanded(
                      child: pw.Text(
                        'Rupees Three Lakh Eighty-Eight Thousand Eighty-One Only',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Prepared By', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Exclusive Diamond Products', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printBankTransferPdf(
    List<BankTransferRecord> transfers,
    double totalAmount,
    String monthDisplay,
  ) async {
    final bytes = await generateBankTransferPdf(transfers, totalAmount, monthDisplay);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Bank_Transfer_Register_${monthDisplay.replaceAll(' ', '_')}.pdf',
    );
  }

  // ============================================================
  // 4. DOCUMENT 5 - STAFF PERSONAL LOAN STATEMENT PDF (Landscape)
  // ============================================================
  static Future<Uint8List> generateLoanStatementPdf(
    List<PersonalLoanRecord> records,
    Map<String, dynamic> totals,
    String monthDisplay,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          final totalSanctioned = totals['loanSanctioned'] ?? records.fold<double>(0.0, (s, r) => s + r.loanSanctioned);
          final totalPrevious = totals['previousBalance'] ?? records.fold<double>(0.0, (s, r) => s + r.previousBalance);
          final totalDeduction = totals['monthlyDeduction'] ?? records.fold<double>(0.0, (s, r) => s + r.monthlyDeduction);
          final totalClosing = totals['closingBalance'] ?? records.fold<double>(0.0, (s, r) => s + r.closingBalance);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EXCLUSIVE DIAMOND PRODUCTS',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        'No.62, Eswaran Koil Street, Porur, Chennai 600116',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.deepPurple50,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: PdfColors.deepPurple200),
                        ),
                        child: pw.Text(
                          'DOCUMENT 5: STAFF PERSONAL LOAN STATEMENT',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Month: ${monthDisplay.toUpperCase()}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(2),
                  6: const pw.FlexColumnWidth(2),
                  7: const pw.FlexColumnWidth(2),
                  8: const pw.FixedColumnWidth(55),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _th('#'),
                      _th('EMP CODE'),
                      _th('NAME OF EMPLOYEE'),
                      _th('DEPARTMENT'),
                      _th('SANCTIONED (Rs.)'),
                      _th('PREV. BALANCE (Rs.)'),
                      _th('DEDUCTION (Rs.)'),
                      _th('CLOSING (Rs.)'),
                      _th('STATUS'),
                    ],
                  ),
                  ...records.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final r = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _td('$idx', align: pw.TextAlign.center),
                        _td(r.empNo, align: pw.TextAlign.center, isBold: true),
                        _td(r.employeeName, isBold: true),
                        _td(r.department),
                        _td(_intFmt.format(r.loanSanctioned), align: pw.TextAlign.right),
                        _td(_intFmt.format(r.previousBalance), align: pw.TextAlign.right),
                        _td(_intFmt.format(r.monthlyDeduction), align: pw.TextAlign.right, isBold: true),
                        _td(_intFmt.format(r.closingBalance), align: pw.TextAlign.right, isBold: true),
                        _td(r.status, align: pw.TextAlign.center),
                      ],
                    );
                  }),
                  // Totals Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _td(''),
                      _td('TOTAL', align: pw.TextAlign.center, isBold: true),
                      _td('${records.length} Staff Accounts', isBold: true),
                      _td(''),
                      _td('Rs. ${_intFmt.format(totalSanctioned)}', align: pw.TextAlign.right, isBold: true),
                      _td('Rs. ${_intFmt.format(totalPrevious)}', align: pw.TextAlign.right, isBold: true),
                      _td('Rs. ${_intFmt.format(totalDeduction)}', align: pw.TextAlign.right, isBold: true),
                      _td('Rs. ${_intFmt.format(totalClosing)}', align: pw.TextAlign.right, isBold: true),
                      _td('Active', align: pw.TextAlign.center, isBold: true),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Prepared By (Accounts)', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Approved By (Managing Director)', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Exclusive Diamond Products', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
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

  static Future<void> printLoanStatementPdf(
    List<PersonalLoanRecord> records,
    Map<String, dynamic> totals,
    String monthDisplay,
  ) async {
    final bytes = await generateLoanStatementPdf(records, totals, monthDisplay);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Staff_Loan_Statement_${monthDisplay.replaceAll(' ', '_')}.pdf',
    );
  }

  // ============================================================
  // Helpers
  // ============================================================
  static pw.Widget _th(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3.5),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.center
              ? pw.Alignment.center
              : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }
}
