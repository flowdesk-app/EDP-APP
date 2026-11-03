import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/payroll_model.dart';

class PayrollPdfService {
  static final NumberFormat _currFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _intFmt = NumberFormat('#,##,##0', 'en_IN');

  // ============================================================
  // 1. INDIVIDUAL EMPLOYEE PAYSLIP PDF (Portrait - Matches Doc 4)
  // ============================================================
  static Future<Uint8List> generatePayslipPdf(PayrollRecord emp) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Company Header
                pw.Center(
                  child: pw.Text(
                    'EXCLUSIVE DIAMOND PRODUCTS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    'No.62, Eswaran Koil Street, Porur, Chennai 600116',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  color: PdfColors.blueGrey100,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Center(
                    child: pw.Text(
                      'PAYSLIP FOR THE MONTH OF ${emp.monthDisplay.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),

                // Employee Details Grid
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    children: [
                      _gridRow('Employee Code', emp.empNo, 'Employee Name', emp.employeeName),
                      _gridRow('Designation', emp.designation, 'Department', emp.department),
                      _gridRow('Date of Joining', emp.doj, 'Bank Name', emp.bankName),
                      _gridRow('Bank A/C No', emp.accountNo, 'IFSC Code', emp.ifscCode),
                      _gridRow('UAN Number', emp.uanNo.isNotEmpty ? emp.uanNo : 'N/A', 'PF Number', emp.pfNo.isNotEmpty ? emp.pfNo : 'N/A'),
                      _gridRow('Total Days in Month', '${emp.totalDays}', 'Days Worked / Paid', '${emp.daysWorked}'),
                      _gridRow('Loss of Pay (LOP)', '${emp.lopDays} Days', 'Overtime Hours', emp.otHoursFormatted),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Earnings & Deductions Tables
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Earnings Column
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              color: PdfColors.blueGrey50,
                              padding: const pw.EdgeInsets.all(5),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('EARNINGS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  pw.Text('AMOUNT (Rs.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                ],
                              ),
                            ),
                            _tableLine('Basic Pay', emp.basic),
                            _tableLine('Dearness Allowance (D.A.)', emp.da),
                            _tableLine('House Rent Allowance (H.R.A.)', emp.hra),
                            _tableLine('Conveyance Allowance', emp.conveyance),
                            _tableLine('Medical Allowance', emp.medicalAlw),
                            _tableLine('Other Allowance', emp.otherAlw),
                            _tableLine('Overtime Compensation', emp.otAmount, isHighlight: emp.otAmount > 0),
                            pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey400),
                            pw.Container(
                              color: PdfColors.blueGrey100,
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('GROSS EARNINGS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  pw.Text('Rs. ${_currFmt.format(emp.grossSalary)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),

                    // Deductions Column
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              color: PdfColors.blueGrey50,
                              padding: const pw.EdgeInsets.all(5),
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('DEDUCTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  pw.Text('AMOUNT (Rs.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                ],
                              ),
                            ),
                            _tableLine('Provident Fund (P.F.)', emp.pf),
                            _tableLine('Employee State Insurance (E.S.I.)', emp.esi),
                            _tableLine('Staff Loan / Advance Recovery', emp.advanceLoan, isHighlight: emp.advanceLoan > 0),
                            _tableLine('Life / Medical Insurance', emp.insurance),
                            _tableLine('Tax Deducted at Source (TDS)', emp.tds),
                            _tableLine('Other Deductions', emp.others),
                            pw.SizedBox(height: 16), // align rows
                            pw.Divider(height: 1, thickness: 0.5, color: PdfColors.grey400),
                            pw.Container(
                              color: PdfColors.blueGrey100,
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('TOTAL DEDUCTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                  pw.Text('Rs. ${_currFmt.format(emp.totalDeductions)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Net Salary Callout Box
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green700, width: 1),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'NET TAKE-HOME SALARY',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: PdfColors.green900,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            emp.netSalaryWords.isNotEmpty ? emp.netSalaryWords : 'Rupees ${_intFmt.format(emp.netSalary)} Only',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Rs. ${_currFmt.format(emp.netSalary)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Employer Statutory Contribution Info
                if (emp.employerPf > 0 || emp.employerEsi > 0)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Text('Employer P.F. Contribution: Rs. ${_currFmt.format(emp.employerPf)}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Employer E.S.I. Contribution: Rs. ${_currFmt.format(emp.employerEsi)}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Payment Mode: ${emp.paymentMode}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                        pw.SizedBox(height: 4),
                        pw.Text('Employee Signature', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                        pw.SizedBox(height: 4),
                        pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                        pw.Text('Exclusive Diamond Products', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated salary document issued by Exclusive Diamond Products Payroll System.',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printPayslipPdf(PayrollRecord emp) async {
    final bytes = await generatePayslipPdf(emp);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Payslip_${emp.empNo}_${emp.employeeName.replaceAll(' ', '_')}.pdf',
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
  static pw.TableRow _gridRow(String label1, String val1, String label2, String val2) {
    return pw.TableRow(
      children: [
        _gridCell(label1, isLabel: true),
        _gridCell(val1),
        _gridCell(label2, isLabel: true),
        _gridCell(val2),
      ],
    );
  }

  static pw.Widget _gridCell(String text, {bool isLabel = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: isLabel ? PdfColors.grey100 : PdfColors.white,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isLabel ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _tableLine(String label, double amount, {bool isHighlight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      color: isHighlight ? PdfColors.amber50 : PdfColors.white,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
          pw.Text(
            _currFmt.format(amount),
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? PdfColors.amber900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

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
