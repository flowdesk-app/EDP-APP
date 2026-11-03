class PayrollRecord {
  final String id;
  final String month;
  final String monthDisplay;
  final String empNo;
  final String employeeName;
  final String designation;
  final String department;
  final String doj;

  // Bank
  final String bankName;
  final String accountNo;
  final String ifscCode;

  // Statutory
  final String pfNo;
  final String uanNo;
  final String esiNo;

  // Attendance
  final int totalDays;
  final int daysWorked;
  final int lopDays;
  final String otHoursFormatted;
  final double otHoursDecimal;

  // Earnings
  final double basic;
  final double da;
  final double hra;
  final double conveyance;
  final double spl;
  final double medicalAlw;
  final double otherAlw;
  final double earnedGross;
  final double otAmount;
  final double grossSalary;

  // Deductions
  final double pf;
  final double esi;
  final double advanceLoan;
  final double tds;
  final double insurance;
  final double others;
  final double totalDeductions;

  // Net & Employer
  final double netSalary;
  final String netSalaryWords;
  final double employerPf;
  final double employerEsi;

  final String paymentStatus;
  final String paymentDate;
  final String paymentMode;

  PayrollRecord({
    required this.id,
    required this.month,
    required this.monthDisplay,
    required this.empNo,
    required this.employeeName,
    required this.designation,
    this.department = 'Production',
    this.doj = '01-04-2020',
    this.bankName = 'State Bank of India',
    this.accountNo = '',
    this.ifscCode = '',
    this.pfNo = '',
    this.uanNo = '',
    this.esiNo = '',
    this.totalDays = 30,
    this.daysWorked = 30,
    this.lopDays = 0,
    this.otHoursFormatted = '0h 0m',
    this.otHoursDecimal = 0,
    this.basic = 0,
    this.da = 0,
    this.hra = 0,
    this.conveyance = 0,
    this.spl = 0,
    this.medicalAlw = 0,
    this.otherAlw = 0,
    this.earnedGross = 0,
    this.otAmount = 0,
    this.grossSalary = 0,
    this.pf = 0,
    this.esi = 0,
    this.advanceLoan = 0,
    this.tds = 0,
    this.insurance = 0,
    this.others = 0,
    this.totalDeductions = 0,
    this.netSalary = 0,
    this.netSalaryWords = '',
    this.employerPf = 0,
    this.employerEsi = 0,
    this.paymentStatus = 'Paid',
    this.paymentDate = '05-10-2026',
    this.paymentMode = 'Online Bank Transfer',
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    final earnings = json['earnings'] as Map<String, dynamic>? ?? {};
    final deductions = json['deductions'] as Map<String, dynamic>? ?? {};
    final bank = json['bankDetails'] as Map<String, dynamic>? ?? {};
    final stat = json['statutory'] as Map<String, dynamic>? ?? {};
    final att = json['attendance'] as Map<String, dynamic>? ?? {};
    final empCont = json['employerContribution'] as Map<String, dynamic>? ?? {};

    return PayrollRecord(
      id: json['_id']?.toString() ?? '',
      month: json['month'] ?? '2026-09',
      monthDisplay: json['monthDisplay'] ?? 'September 2026',
      empNo: json['empNo'] ?? '',
      employeeName: json['employeeName'] ?? '',
      designation: json['designation'] ?? '',
      department: json['department'] ?? 'Production',
      doj: json['doj'] ?? '01-04-2020',
      bankName: bank['bankName'] ?? 'State Bank of India',
      accountNo: bank['accountNo'] ?? '',
      ifscCode: bank['ifscCode'] ?? '',
      pfNo: stat['pfNo'] ?? '',
      uanNo: stat['uanNo'] ?? '',
      esiNo: stat['esiNo'] ?? '',
      totalDays: (att['totalDays'] as num?)?.toInt() ?? 30,
      daysWorked: (att['daysWorked'] as num?)?.toInt() ?? 30,
      lopDays: (att['lopDays'] as num?)?.toInt() ?? 0,
      otHoursFormatted: att['otHoursFormatted']?.toString() ?? '0h 0m',
      otHoursDecimal: (att['otHoursDecimal'] as num?)?.toDouble() ?? 0.0,
      basic: (earnings['basic'] as num?)?.toDouble() ?? 0.0,
      da: (earnings['da'] as num?)?.toDouble() ?? 0.0,
      hra: (earnings['hra'] as num?)?.toDouble() ?? 0.0,
      conveyance: (earnings['conveyance'] as num?)?.toDouble() ?? 0.0,
      spl: (earnings['spl'] as num?)?.toDouble() ?? 0.0,
      medicalAlw: (earnings['medicalAlw'] as num?)?.toDouble() ?? 0.0,
      otherAlw: (earnings['otherAlw'] as num?)?.toDouble() ?? 0.0,
      earnedGross: (earnings['earnedGross'] as num?)?.toDouble() ?? 0.0,
      otAmount: (earnings['otAmount'] as num?)?.toDouble() ?? 0.0,
      grossSalary: (earnings['grossSalary'] as num?)?.toDouble() ?? 0.0,
      pf: (deductions['pf'] as num?)?.toDouble() ?? 0.0,
      esi: (deductions['esi'] as num?)?.toDouble() ?? 0.0,
      advanceLoan: (deductions['advanceLoan'] as num?)?.toDouble() ?? 0.0,
      tds: (deductions['tds'] as num?)?.toDouble() ?? 0.0,
      insurance: (deductions['insurance'] as num?)?.toDouble() ?? 0.0,
      others: (deductions['others'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (deductions['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0.0,
      netSalaryWords: json['netSalaryWords'] ?? '',
      employerPf: (empCont['pf'] as num?)?.toDouble() ?? 0.0,
      employerEsi: (empCont['esi'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] ?? 'Paid',
      paymentDate: json['paymentDate'] ?? '05-10-2026',
      paymentMode: json['paymentMode'] ?? 'Online Bank Transfer',
    );
  }
}

class BankTransferRecord {
  final int slNo;
  final String empNo;
  final String employeeName;
  final String bankName;
  final String accountNo;
  final String ifscCode;
  final double amount;
  final String paymentStatus;
  final String paymentDate;

  BankTransferRecord({
    required this.slNo,
    required this.empNo,
    required this.employeeName,
    required this.bankName,
    required this.accountNo,
    required this.ifscCode,
    required this.amount,
    required this.paymentStatus,
    required this.paymentDate,
  });

  factory BankTransferRecord.fromJson(Map<String, dynamic> json) {
    return BankTransferRecord(
      slNo: (json['slNo'] as num?)?.toInt() ?? 1,
      empNo: json['empNo'] ?? '',
      employeeName: json['employeeName'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNo: json['accountNo'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] ?? 'Paid',
      paymentDate: json['paymentDate'] ?? '05-10-2026',
    );
  }
}

class LeaveRecord {
  final String empNo;
  final String employeeName;
  final String department;
  final double openingLeave;
  final double monthlyAccrual;
  final double leaveTaken;
  final double lopDays;
  final double closingBalance;
  final String remarks;

  LeaveRecord({
    required this.empNo,
    required this.employeeName,
    this.department = 'Production',
    this.openingLeave = 0.0,
    this.monthlyAccrual = 1.5,
    this.leaveTaken = 0.0,
    this.lopDays = 0.0,
    this.closingBalance = 0.0,
    this.remarks = '',
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      empNo: json['empNo'] ?? '',
      employeeName: json['employeeName'] ?? '',
      department: json['department'] ?? 'Production',
      openingLeave: (json['openingLeave'] as num?)?.toDouble() ?? 0.0,
      monthlyAccrual: (json['monthlyAccrual'] as num?)?.toDouble() ?? 1.5,
      leaveTaken: (json['leaveTaken'] as num?)?.toDouble() ?? 0.0,
      lopDays: (json['lopDays'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closingBalance'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] ?? '',
    );
  }
}

class PersonalLoanRecord {
  final String empNo;
  final String employeeName;
  final String department;
  final double loanSanctioned;
  final String sanctionDate;
  final double previousBalance;
  final double monthlyDeduction;
  final double closingBalance;
  final String status;
  final String notes;

  PersonalLoanRecord({
    required this.empNo,
    required this.employeeName,
    this.department = 'Production',
    this.loanSanctioned = 0.0,
    this.sanctionDate = '01-01-2025',
    this.previousBalance = 0.0,
    this.monthlyDeduction = 0.0,
    this.closingBalance = 0.0,
    this.status = 'Active',
    this.notes = 'Monthly deduction',
  });

  factory PersonalLoanRecord.fromJson(Map<String, dynamic> json) {
    return PersonalLoanRecord(
      empNo: json['empNo'] ?? '',
      employeeName: json['employeeName'] ?? '',
      department: json['department'] ?? 'Production',
      loanSanctioned: (json['loanSanctioned'] as num?)?.toDouble() ?? 0.0,
      sanctionDate: json['sanctionDate'] ?? '01-01-2025',
      previousBalance: (json['previousBalance'] as num?)?.toDouble() ?? 0.0,
      monthlyDeduction: (json['monthlyDeduction'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closingBalance'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Active',
      notes: json['notes'] ?? '',
    );
  }
}

class PayrollSummary {
  final int totalEmployees;
  final double totalNetDisbursed;
  final double totalGrossPayroll;
  final double totalEarnedGross;
  final double totalDeductions;
  final double totalOtAmount;
  final String totalOtHoursFormatted;
  final double totalLoanBalance;
  final double totalLoanDeduction;
  final double totalLopDays;

  PayrollSummary({
    required this.totalEmployees,
    required this.totalNetDisbursed,
    required this.totalGrossPayroll,
    required this.totalEarnedGross,
    required this.totalDeductions,
    required this.totalOtAmount,
    required this.totalOtHoursFormatted,
    required this.totalLoanBalance,
    required this.totalLoanDeduction,
    required this.totalLopDays,
  });

  factory PayrollSummary.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'] as Map<String, dynamic>? ?? {};
    return PayrollSummary(
      totalEmployees: (kpis['totalEmployees'] as num?)?.toInt() ?? 0,
      totalNetDisbursed: (kpis['totalNetDisbursed'] as num?)?.toDouble() ?? 0.0,
      totalGrossPayroll: (kpis['totalGrossPayroll'] as num?)?.toDouble() ?? 0.0,
      totalEarnedGross: (kpis['totalEarnedGross'] as num?)?.toDouble() ?? 0.0,
      totalDeductions: (kpis['totalDeductions'] as num?)?.toDouble() ?? 0.0,
      totalOtAmount: (kpis['totalOtAmount'] as num?)?.toDouble() ?? 0.0,
      totalOtHoursFormatted: kpis['totalOtHoursFormatted']?.toString() ?? '888h 30m',
      totalLoanBalance: (kpis['totalLoanBalance'] as num?)?.toDouble() ?? 0.0,
      totalLoanDeduction: (kpis['totalLoanDeduction'] as num?)?.toDouble() ?? 0.0,
      totalLopDays: (kpis['totalLopDays'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
