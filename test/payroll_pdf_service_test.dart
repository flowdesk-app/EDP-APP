import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/models/payroll_model.dart';
import 'package:automated_dashboard/services/payroll_pdf_service.dart';

void main() {
  group('PayrollPdfService Tests', () {
    final sampleEmp = PayrollRecord(
      id: '1',
      month: '2026-09',
      monthDisplay: 'September 2026',
      empNo: '20004',
      employeeName: 'K.RAMA',
      designation: 'WORKS MANAGER',
      department: 'Production',
      doj: '01-04-2017',
      bankName: 'ICICI BANK',
      accountNo: '000101569420',
      ifscCode: 'ICIC0000001',
      pfNo: 'TN/MAS/0048123/001',
      uanNo: '100904819201',
      esiNo: 'N/A',
      totalDays: 30,
      daysWorked: 30,
      lopDays: 0,
      otHoursFormatted: '201h 30m',
      otHoursDecimal: 201.5,
      basic: 8900,
      da: 4450,
      hra: 4450,
      conveyance: 1000,
      spl: 0,
      medicalAlw: 1250,
      otherAlw: 15350,
      earnedGross: 35400,
      otAmount: 14945,
      grossSalary: 50345,
      pf: 1068,
      esi: 0,
      advanceLoan: 1000,
      tds: 0,
      insurance: 1250,
      others: 0,
      totalDeductions: 3318,
      netSalary: 47027,
      netSalaryWords: 'Rupees Forty-Seven Thousand Twenty-Seven Only',
      employerPf: 1068,
      employerEsi: 0,
    );

    test('generatePayslipPdf generates valid PDF bytes', () async {
      final bytes = await PayrollPdfService.generatePayslipPdf(sampleEmp);
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(1000));
    });

    test('generateMasterStatementPdf generates valid landscape PDF bytes', () async {
      final bytes = await PayrollPdfService.generateMasterStatementPdf(
        [sampleEmp],
        {'basic': 8900, 'netSalary': 47027, 'grossSalary': 50345},
        'September 2026',
      );
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(1000));
    });

    test('OfficialPayslipModel maps official figures for 20004 correctly', () {
      final payslip = OfficialPayslipModel.fromPayrollRecord(sampleEmp, month: 'September 2026');
      expect(payslip.empNo, '20004');
      expect(payslip.employeeName, 'K.RAMA');
      expect(payslip.designation, 'Works Manager');
      expect(payslip.department, 'Production');
      expect(payslip.doj, '01-09-1988');
      expect(payslip.leave, '5');
      expect(payslip.balance, '0.5');
      expect(payslip.lop, '0.00');
      expect(payslip.otHours, '201.50');
      expect(payslip.basic, 8900.0);
      expect(payslip.hra, 6000.0);
      expect(payslip.lunch, 4600.0);
      expect(payslip.transport, 1600.0);
      expect(payslip.medical, 1250.0);
      expect(payslip.specialAllowance, 8150.0);
      expect(payslip.overtime, 14945.0);
      expect(payslip.otherAllowance, 4900.0);
      expect(payslip.totalEarnings, 50345.0);
      expect(payslip.pf, 1068.0);
      expect(payslip.advanceLoan, 1000.0);
      expect(payslip.insurance, 1250.0);
      expect(payslip.totalDeductions, 3318.0);
      expect(payslip.netSalary, 47027.0);
    });

    test('generateBankTransferPdf generates valid PDF bytes', () async {
      final transfer = BankTransferRecord(
        slNo: 1,
        empNo: '20004',
        employeeName: 'K.RAMA',
        bankName: 'ICICI BANK',
        accountNo: '000101569420',
        ifscCode: 'ICIC0000001',
        amount: 47027.0,
        paymentStatus: 'Paid',
        paymentDate: '05-10-2026',
      );
      final bytes = await PayrollPdfService.generateBankTransferPdf([transfer], 47027.0, 'September 2026');
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
