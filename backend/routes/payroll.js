const express = require('express');
const router = express.Router();
const Payroll = require('../models/Payroll');
const PersonalLoan = require('../models/PersonalLoan');
const LeaveRegister = require('../models/LeaveRegister');

// Number to Words converter for Indian Rupees
function numberToIndianWords(num) {
  if (!num || num === 0) return 'Zero Rupees Only';
  const a = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
  const b = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  function convertSection(n) {
    if (n < 20) return a[n];
    const tens = Math.floor(n / 10);
    const units = n % 10;
    return b[tens] + (units ? ' ' + a[units] : '');
  }

  const rounded = Math.round(num);
  let str = '';
  const crore = Math.floor(rounded / 10000000);
  let rem = rounded % 10000000;
  const lakh = Math.floor(rem / 100000);
  rem = rem % 100000;
  const thousand = Math.floor(rem / 1000);
  rem = rem % 1000;
  const hundred = Math.floor(rem / 100);
  rem = rem % 100;

  if (crore > 0) str += convertSection(crore) + ' Crore ';
  if (lakh > 0) str += convertSection(lakh) + ' Lakh ';
  if (thousand > 0) str += convertSection(thousand) + ' Thousand ';
  if (hundred > 0) str += convertSection(hundred) + ' Hundred ';
  if (rem > 0) {
    if (str !== '') str += 'and ';
    str += convertSection(rem) + ' ';
  }
  return 'Rupees ' + str.trim() + ' Only';
}

const SEED_PAYROLL_DATA = [
  {
    empNo: "20004",
    employeeName: "K.RAMA",
    designation: "WORKS MANAGER",
    department: "Production",
    doj: "01-04-2017",
    bankDetails: { bankName: "ICICI BANK", accountNo: "000101569420", ifscCode: "ICIC0000001" },
    statutory: { pfNo: "TN/MAS/0048123/001", uanNo: "100904819201", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "201h 30m", otHoursDecimal: 201.5 },
    earnings: { basic: 8900, da: 4450, hra: 4450, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 15350, earnedGross: 35400, otAmount: 14945, grossSalary: 50345 },
    deductions: { pf: 1068, esi: 0, advanceLoan: 1000, tds: 0, insurance: 1250, others: 0, totalDeductions: 3318 },
    netSalary: 47027,
    netSalaryWords: "Rupees Forty-Seven Thousand Twenty-Seven Only",
    employerContribution: { pf: 1068, esi: 0 }
  },
  {
    empNo: "20005",
    employeeName: "R.RAJESWARI",
    designation: "ADMIN MANAGER",
    department: "Admin",
    doj: "15-06-2018",
    bankDetails: { bankName: "HDFC BANK", accountNo: "00171050064219", ifscCode: "HDFC0000017" },
    statutory: { pfNo: "TN/MAS/0048123/002", uanNo: "100904819202", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "0h 0m", otHoursDecimal: 0 },
    earnings: { basic: 8500, da: 4250, hra: 4250, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 4800, earnedGross: 24050, otAmount: 0, grossSalary: 24050 },
    deductions: { pf: 1020, esi: 0, advanceLoan: 0, tds: 0, insurance: 1250, others: 0, totalDeductions: 2270 },
    netSalary: 21780,
    netSalaryWords: "Rupees Twenty-One Thousand Seven Hundred Eighty Only",
    employerContribution: { pf: 1020, esi: 0 }
  },
  {
    empNo: "20008",
    employeeName: "DILSHATH PEGUM",
    designation: "PRODUCTION EXECUTIVE",
    department: "Production",
    doj: "01-10-2018",
    bankDetails: { bankName: "STATE BANK OF INDIA", accountNo: "30908819201", ifscCode: "SBIN0001856" },
    statutory: { pfNo: "TN/MAS/0048123/003", uanNo: "100904819203", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "33h 24m", otHoursDecimal: 33.4 },
    earnings: { basic: 6500, da: 3250, hra: 3250, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 8950, earnedGross: 24200, otAmount: 1809, grossSalary: 26009 },
    deductions: { pf: 780, esi: 0, advanceLoan: 1000, tds: 0, insurance: 1042, others: 0, totalDeductions: 2822 },
    netSalary: 23187,
    netSalaryWords: "Rupees Twenty-Three Thousand One Hundred Eighty-Seven Only",
    employerContribution: { pf: 780, esi: 0 }
  },
  {
    empNo: "20011",
    employeeName: "A.NAGARAJAN",
    designation: "MARKETING EXECUTIVE",
    department: "Marketing",
    doj: "12-01-2019",
    bankDetails: { bankName: "INDIAN OVERSEAS BANK", accountNo: "088401000012391", ifscCode: "IOBA0000884" },
    statutory: { pfNo: "TN/MAS/0048123/004", uanNo: "100904819204", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 28, lopDays: 2, otHoursFormatted: "0h 0m", otHoursDecimal: 0 },
    earnings: { basic: 8400, da: 4200, hra: 4200, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 16750, earnedGross: 35800, otAmount: 0, grossSalary: 35800 },
    deductions: { pf: 1008, esi: 0, advanceLoan: 5000, tds: 0, insurance: 1250, others: 0, totalDeductions: 7258 },
    netSalary: 28542,
    netSalaryWords: "Rupees Twenty-Eight Thousand Five Hundred Forty-Two Only",
    employerContribution: { pf: 1008, esi: 0 }
  },
  {
    empNo: "20026",
    employeeName: "C.SUBHALAKSHMI",
    designation: "MANAGER - ACCOUNTS",
    department: "Accounts",
    doj: "01-08-2019",
    bankDetails: { bankName: "CANARA BANK", accountNo: "1149101089201", ifscCode: "CNRB0001149" },
    statutory: { pfNo: "TN/MAS/0048123/005", uanNo: "100904819205", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "0h 0m", otHoursDecimal: 0 },
    earnings: { basic: 8000, da: 4000, hra: 4000, conveyance: 1000, spl: 0, medicalAlw: 1000, otherAlw: 0, earnedGross: 18000, otAmount: 0, grossSalary: 18000 },
    deductions: { pf: 960, esi: 0, advanceLoan: 0, tds: 0, insurance: 1295, others: 0, totalDeductions: 2255 },
    netSalary: 15745,
    netSalaryWords: "Rupees Fifteen Thousand Seven Hundred Forty-Five Only",
    employerContribution: { pf: 960, esi: 0 }
  },
  {
    empNo: "20028",
    employeeName: "S.CHANDRAMOULI",
    designation: "MANAGER - PRODUCTION",
    department: "Production",
    doj: "15-11-2019",
    bankDetails: { bankName: "ICICI BANK", accountNo: "000101620194", ifscCode: "ICIC0000001" },
    statutory: { pfNo: "TN/MAS/0048123/006", uanNo: "100904819206", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "0h 0m", otHoursDecimal: 0 },
    earnings: { basic: 10000, da: 5000, hra: 5000, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 16000, earnedGross: 38250, otAmount: 0, grossSalary: 38250 },
    deductions: { pf: 1200, esi: 0, advanceLoan: 0, tds: 0, insurance: 1341, others: 0, totalDeductions: 2541 },
    netSalary: 35709,
    netSalaryWords: "Rupees Thirty-Five Thousand Seven Hundred Nine Only",
    employerContribution: { pf: 1200, esi: 0 }
  },
  {
    empNo: "20029",
    employeeName: "S.REBEKKA",
    designation: "PRODUCTION EXECUTIVE",
    department: "Production",
    doj: "01-02-2020",
    bankDetails: { bankName: "INDIAN BANK", accountNo: "6098214301", ifscCode: "IDIB000P042" },
    statutory: { pfNo: "TN/MAS/0048123/007", uanNo: "100904819207", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "2h 14m", otHoursDecimal: 2.23 },
    earnings: { basic: 8000, da: 4000, hra: 4000, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 11750, earnedGross: 30000, otAmount: 149, grossSalary: 30149 },
    deductions: { pf: 960, esi: 0, advanceLoan: 1000, tds: 0, insurance: 1042, others: 0, totalDeductions: 3002 },
    netSalary: 27147,
    netSalaryWords: "Rupees Twenty-Seven Thousand One Hundred Forty-Seven Only",
    employerContribution: { pf: 960, esi: 0 }
  },
  {
    empNo: "20034",
    employeeName: "KAMAKSHI D",
    designation: "MANAGER - ADMIN",
    department: "Admin",
    doj: "01-06-2020",
    bankDetails: { bankName: "STATE BANK OF INDIA", accountNo: "20198450192", ifscCode: "SBIN0001856" },
    statutory: { pfNo: "TN/MAS/0048123/008", uanNo: "100904819208", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "0h 0m", otHoursDecimal: 0 },
    earnings: { basic: 8000, da: 4000, hra: 4000, conveyance: 1000, spl: 0, medicalAlw: 1250, otherAlw: 16000, earnedGross: 34250, otAmount: 0, grossSalary: 34250 },
    deductions: { pf: 960, esi: 0, advanceLoan: 1000, tds: 0, insurance: 1250, others: 0, totalDeductions: 3210 },
    netSalary: 31040,
    netSalaryWords: "Rupees Thirty-One Thousand Forty Only",
    employerContribution: { pf: 960, esi: 0 }
  },
  {
    empNo: "20036",
    employeeName: "GHOSIA",
    designation: "PRODUCTION ASSISTANT",
    department: "Production",
    doj: "10-09-2020",
    bankDetails: { bankName: "CANARA BANK", accountNo: "1149101094312", ifscCode: "CNRB0001149" },
    statutory: { pfNo: "TN/MAS/0048123/009", uanNo: "100904819209", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "206h 4m", otHoursDecimal: 206.07 },
    earnings: { basic: 5000, da: 2500, hra: 2500, conveyance: 1000, spl: 0, medicalAlw: 900, otherAlw: 10000, earnedGross: 21900, otAmount: 8243, grossSalary: 30143 },
    deductions: { pf: 600, esi: 0, advanceLoan: 5000, tds: 0, insurance: 0, others: 0, totalDeductions: 5600 },
    netSalary: 24543,
    netSalaryWords: "Rupees Twenty-Four Thousand Five Hundred Forty-Three Only",
    employerContribution: { pf: 600, esi: 0 }
  },
  {
    empNo: "20041",
    employeeName: "PITHAM MARNDI",
    designation: "PRODUCTION ASSISTANT",
    department: "Production",
    doj: "01-01-2021",
    bankDetails: { bankName: "STATE BANK OF INDIA", accountNo: "38910294102", ifscCode: "SBIN0001856" },
    statutory: { pfNo: "TN/MAS/0048123/010", uanNo: "100904819210", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "185h 53m", otHoursDecimal: 185.88 },
    earnings: { basic: 5000, da: 2500, hra: 2500, conveyance: 1000, spl: 0, medicalAlw: 900, otherAlw: 9000, earnedGross: 20900, otAmount: 7435, grossSalary: 28335 },
    deductions: { pf: 0, esi: 0, advanceLoan: 0, tds: 0, insurance: 0, others: 0, totalDeductions: 0 },
    netSalary: 28335,
    netSalaryWords: "Rupees Twenty-Eight Thousand Three Hundred Thirty-Five Only",
    employerContribution: { pf: 0, esi: 0 }
  },
  {
    empNo: "20042",
    employeeName: "KANTHAROOPI",
    designation: "PRODUCTION ASSISTANT",
    department: "Production",
    doj: "01-03-2021",
    bankDetails: { bankName: "INDIAN OVERSEAS BANK", accountNo: "088401000019402", ifscCode: "IOBA0000884" },
    statutory: { pfNo: "TN/MAS/0048123/011", uanNo: "100904819211", esiNo: "51000941290001001" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "1h 53m", otHoursDecimal: 1.88 },
    earnings: { basic: 5000, da: 2500, hra: 2500, conveyance: 1000, spl: 0, medicalAlw: 900, otherAlw: 4300, earnedGross: 16200, otAmount: 78, grossSalary: 16278 },
    deductions: { pf: 600, esi: 122, advanceLoan: 1000, tds: 0, insurance: 0, others: 0, totalDeductions: 1722 },
    netSalary: 14556,
    netSalaryWords: "Rupees Fourteen Thousand Five Hundred Fifty-Six Only",
    employerContribution: { pf: 600, esi: 529 }
  },
  {
    empNo: "20043",
    employeeName: "RAMAMURTHY",
    designation: "DRIVER",
    department: "Logistics",
    doj: "15-05-2021",
    bankDetails: { bankName: "HDFC BANK", accountNo: "50100294102914", ifscCode: "HDFC0000017" },
    statutory: { pfNo: "TN/MAS/0048123/012", uanNo: "100904819212", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "44h 17m", otHoursDecimal: 44.28 },
    earnings: { basic: 6000, da: 3000, hra: 3000, conveyance: 1000, spl: 0, medicalAlw: 1200, otherAlw: 10000, earnedGross: 24200, otAmount: 2214, grossSalary: 26414 },
    deductions: { pf: 720, esi: 0, advanceLoan: 0, tds: 0, insurance: 0, others: 0, totalDeductions: 720 },
    netSalary: 25694,
    netSalaryWords: "Rupees Twenty-Five Thousand Six Hundred Ninety-Four Only",
    employerContribution: { pf: 720, esi: 0 }
  },
  {
    empNo: "20045",
    employeeName: "RENTA",
    designation: "PRODUCTION ASSISTANT",
    department: "Production",
    doj: "01-08-2021",
    bankDetails: { bankName: "STATE BANK OF INDIA", accountNo: "39019204910", ifscCode: "SBIN0001856" },
    statutory: { pfNo: "TN/MAS/0048123/013", uanNo: "100904819213", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 2, lopDays: 28, otHoursFormatted: "16h 25m", otHoursDecimal: 16.42 },
    earnings: { basic: 333, da: 167, hra: 167, conveyance: 67, spl: 0, medicalAlw: 60, otherAlw: 393, earnedGross: 1186, otAmount: 657, grossSalary: 1843 },
    deductions: { pf: 0, esi: 0, advanceLoan: 0, tds: 0, insurance: 0, others: 0, totalDeductions: 0 },
    netSalary: 1843,
    netSalaryWords: "Rupees One Thousand Eight Hundred Forty-Three Only",
    employerContribution: { pf: 0, esi: 0 }
  },
  {
    empNo: "20046",
    employeeName: "CHANDRAY SOREN",
    designation: "PRODUCTION ASSISTANT",
    department: "Production",
    doj: "15-09-2021",
    bankDetails: { bankName: "STATE BANK OF INDIA", accountNo: "39019204921", ifscCode: "SBIN0001856" },
    statutory: { pfNo: "TN/MAS/0048123/014", uanNo: "100904819214", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "99h 57m", otHoursDecimal: 99.95 },
    earnings: { basic: 5000, da: 2500, hra: 2500, conveyance: 1000, spl: 0, medicalAlw: 900, otherAlw: 4900, earnedGross: 16800, otAmount: 3998, grossSalary: 20798 },
    deductions: { pf: 0, esi: 0, advanceLoan: 0, tds: 0, insurance: 0, others: 0, totalDeductions: 0 },
    netSalary: 20798,
    netSalaryWords: "Rupees Twenty Thousand Seven Hundred Ninety-Eight Only",
    employerContribution: { pf: 0, esi: 0 }
  },
  {
    empNo: "20047",
    employeeName: "SURAI",
    designation: "PRODUCTION ASSISTANT",
    department: "Production",
    doj: "01-11-2021",
    bankDetails: { bankName: "STATE BANK OF INDIA", accountNo: "39019204932", ifscCode: "SBIN0001856" },
    statutory: { pfNo: "TN/MAS/0048123/015", uanNo: "100904819215", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "101h 23m", otHoursDecimal: 101.38 },
    earnings: { basic: 5000, da: 2500, hra: 2500, conveyance: 1000, spl: 0, medicalAlw: 900, otherAlw: 4900, earnedGross: 16800, otAmount: 4055, grossSalary: 20855 },
    deductions: { pf: 0, esi: 0, advanceLoan: 0, tds: 0, insurance: 0, others: 0, totalDeductions: 0 },
    netSalary: 20855,
    netSalaryWords: "Rupees Twenty Thousand Eight Hundred Fifty-Five Only",
    employerContribution: { pf: 0, esi: 0 }
  },
  {
    empNo: "20048",
    employeeName: "MAHESH G",
    designation: "ADMIN EXECUTIVE",
    department: "Admin",
    doj: "01-01-2022",
    bankDetails: { bankName: "AXIS BANK", accountNo: "918010049102918", ifscCode: "UTIB0000124" },
    statutory: { pfNo: "TN/MAS/0048123/016", uanNo: "100904819216", esiNo: "N/A" },
    attendance: { totalDays: 30, daysWorked: 30, lopDays: 0, otHoursFormatted: "0h 0m", otHoursDecimal: 0 },
    earnings: { basic: 6000, da: 3000, hra: 3000, conveyance: 1000, spl: 0, medicalAlw: 1200, otherAlw: 7800, earnedGross: 22000, otAmount: 0, grossSalary: 22000 },
    deductions: { pf: 720, esi: 0, advanceLoan: 0, tds: 0, insurance: 0, others: 0, totalDeductions: 720 },
    netSalary: 21280,
    netSalaryWords: "Rupees Twenty-One Thousand Two Hundred Eighty Only",
    employerContribution: { pf: 720, esi: 0 }
  }
];

const SEED_PERSONAL_LOANS = [
  { empNo: "20004", employeeName: "K.RAMA", department: "Production", loanSanctioned: 50000, previousBalance: 30000, monthlyDeduction: 1000, closingBalance: 29000, status: "Active" },
  { empNo: "20008", employeeName: "DILSHATH PEGUM", department: "Production", loanSanctioned: 30000, previousBalance: 20000, monthlyDeduction: 1000, closingBalance: 19000, status: "Active" },
  { empNo: "20011", employeeName: "A.NAGARAJAN", department: "Marketing", loanSanctioned: 600000, previousBalance: 520000, monthlyDeduction: 5000, closingBalance: 515000, status: "Active" },
  { empNo: "20029", employeeName: "S.REBEKKA", department: "Production", loanSanctioned: 30000, previousBalance: 20000, monthlyDeduction: 1000, closingBalance: 19000, status: "Active" },
  { empNo: "20034", employeeName: "KAMAKSHI D", department: "Admin", loanSanctioned: 60000, previousBalance: 50000, monthlyDeduction: 1000, closingBalance: 49000, status: "Active" },
  { empNo: "20036", employeeName: "GHOSIA", department: "Production", loanSanctioned: 70000, previousBalance: 46000, monthlyDeduction: 5000, closingBalance: 41000, status: "Active" },
  { empNo: "20042", employeeName: "KANTHAROOPI", department: "Production", loanSanctioned: 25000, previousBalance: 18000, monthlyDeduction: 1000, closingBalance: 17000, status: "Active" }
];

const SEED_LEAVE_REGISTER = [
  { empNo: "20004", employeeName: "K.RAMA", department: "Production", openingLeave: 0.0, monthlyAccrual: 1.5, leaveTaken: 1.0, lopDays: 0.0, closingBalance: 0.5, remarks: "Normal leave" },
  { empNo: "20005", employeeName: "R.RAJESWARI", department: "Admin", openingLeave: 18.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 18.0, remarks: "" },
  { empNo: "20008", employeeName: "DILSHATH PEGUM", department: "Production", openingLeave: 8.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 8.0, remarks: "" },
  { empNo: "20011", employeeName: "A.NAGARAJAN", department: "Marketing", openingLeave: 0.0, monthlyAccrual: 1.5, leaveTaken: 3.5, lopDays: 2.0, closingBalance: 0.0, remarks: "2.0 Days LOP" },
  { empNo: "20026", employeeName: "C.SUBHALAKSHMI", department: "Accounts", openingLeave: 18.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 18.0, remarks: "" },
  { empNo: "20028", employeeName: "S.CHANDRAMOULI", department: "Production", openingLeave: 18.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 18.0, remarks: "" },
  { empNo: "20029", employeeName: "S.REBEKKA", department: "Production", openingLeave: 6.0, monthlyAccrual: 1.5, leaveTaken: 1.0, lopDays: 0.0, closingBalance: 6.5, remarks: "" },
  { empNo: "20034", employeeName: "KAMAKSHI D", department: "Admin", openingLeave: 18.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 18.0, remarks: "" },
  { empNo: "20036", employeeName: "GHOSIA", department: "Production", openingLeave: 16.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 16.0, remarks: "" },
  { empNo: "20041", employeeName: "PITHAM MARNDI", department: "Production", openingLeave: 12.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 12.0, remarks: "" },
  { empNo: "20042", employeeName: "KANTHAROOPI", department: "Production", openingLeave: 8.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 8.0, remarks: "" },
  { empNo: "20043", employeeName: "RAMAMURTHY", department: "Logistics", openingLeave: 9.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 9.0, remarks: "" },
  { empNo: "20045", employeeName: "RENTA", department: "Production", openingLeave: 13.0, monthlyAccrual: 1.5, leaveTaken: 29.5, lopDays: 28.0, closingBalance: 13.0, remarks: "28.0 Days LOP" },
  { empNo: "20046", employeeName: "CHANDRAY SOREN", department: "Production", openingLeave: 18.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 18.0, remarks: "" },
  { empNo: "20047", employeeName: "SURAI", department: "Production", openingLeave: 12.0, monthlyAccrual: 1.5, leaveTaken: 1.5, lopDays: 0.0, closingBalance: 12.0, remarks: "" },
  { empNo: "20048", employeeName: "MAHESH G", department: "Admin", openingLeave: 8.0, monthlyAccrual: 1.5, leaveTaken: 1.0, lopDays: 0.0, closingBalance: 8.5, remarks: "" }
];

// Helper to seed September 2026 data
async function ensureSeedData(month = "2026-09") {
  const count = await Payroll.countDocuments({ month });
  if (count === 0) {
    const payrollDocs = SEED_PAYROLL_DATA.map(p => ({
      ...p,
      month,
      monthDisplay: "September 2026"
    }));
    await Payroll.insertMany(payrollDocs);

    const loanDocs = SEED_PERSONAL_LOANS.map(l => ({ ...l, month }));
    await PersonalLoan.insertMany(loanDocs);

    const leaveDocs = SEED_LEAVE_REGISTER.map(lr => ({ ...lr, month }));
    await LeaveRegister.insertMany(leaveDocs);
    console.log(`[Payroll] Seeded initial data for ${month}`);
  }
}

// 1. GET /api/payroll/statement?month=2026-09
router.get('/statement', async (req, res) => {
  try {
    const month = req.query.month || '2026-09';
    await ensureSeedData(month);

    const records = await Payroll.find({ month }).sort({ empNo: 1 }).lean();

    // Calculate Grand Totals
    const totals = {
      basic: 0,
      da: 0,
      hra: 0,
      conveyance: 0,
      spl: 0,
      medicalAlw: 0,
      otherAlw: 0,
      earnedGross: 0,
      otAmount: 0,
      grossSalary: 0,
      pf: 0,
      esi: 0,
      advanceLoan: 0,
      tds: 0,
      insurance: 0,
      others: 0,
      totalDeductions: 0,
      netSalary: 0,
      employerPf: 0,
      employerEsi: 0,
      totalOtMinutes: 0,
    };

    records.forEach(r => {
      totals.basic += r.earnings?.basic || 0;
      totals.da += r.earnings?.da || 0;
      totals.hra += r.earnings?.hra || 0;
      totals.conveyance += r.earnings?.conveyance || 0;
      totals.spl += r.earnings?.spl || 0;
      totals.medicalAlw += r.earnings?.medicalAlw || 0;
      totals.otherAlw += r.earnings?.otherAlw || 0;
      totals.earnedGross += r.earnings?.earnedGross || 0;
      totals.otAmount += r.earnings?.otAmount || 0;
      totals.grossSalary += r.earnings?.grossSalary || 0;

      totals.pf += r.deductions?.pf || 0;
      totals.esi += r.deductions?.esi || 0;
      totals.advanceLoan += r.deductions?.advanceLoan || 0;
      totals.tds += r.deductions?.tds || 0;
      totals.insurance += r.deductions?.insurance || 0;
      totals.others += r.deductions?.others || 0;
      totals.totalDeductions += r.deductions?.totalDeductions || 0;

      totals.netSalary += r.netSalary || 0;
      totals.employerPf += r.employerContribution?.pf || 0;
      totals.employerEsi += r.employerContribution?.esi || 0;
    });

    res.json({
      success: true,
      month,
      company: {
        name: "EXCLUSIVE DIAMOND PRODUCTS",
        address: "No.62, Eswaran Koil Street, Porur, Chennai 600116",
        title: `SALARY STATEMENT FOR THE MONTH OF ${month === '2026-09' ? 'SEPTEMBER - 2026' : month}`
      },
      count: records.length,
      records,
      totals,
    });
  } catch (err) {
    console.error('Error fetching payroll statement:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 2. GET /api/payroll/bank-transfers?month=2026-09
router.get('/bank-transfers', async (req, res) => {
  try {
    const month = req.query.month || '2026-09';
    await ensureSeedData(month);

    const records = await Payroll.find({ month }, 'empNo employeeName bankDetails netSalary paymentStatus paymentDate').sort({ empNo: 1 }).lean();

    const formatted = records.map((r, index) => ({
      slNo: index + 1,
      empNo: r.empNo,
      employeeName: r.employeeName,
      bankName: r.bankDetails?.bankName || 'State Bank of India',
      accountNo: r.bankDetails?.accountNo || '',
      ifscCode: r.bankDetails?.ifscCode || '',
      amount: r.netSalary,
      paymentStatus: r.paymentStatus,
      paymentDate: r.paymentDate,
    }));

    const totalAmount = formatted.reduce((acc, curr) => acc + curr.amount, 0);

    res.json({
      success: true,
      month,
      company: {
        name: "EXCLUSIVE DIAMOND PRODUCTS",
        address: "NO: 62, ESWARAN KOIL STREET, PORUR, CHENNAI - 600116.",
        title: `ONLINE BANK TRANSFER FOR THE MONTH OF ${month === '2026-09' ? 'SEPTEMBER - 2026' : month}`
      },
      transfers: formatted,
      totalAmount,
      totalEmployees: formatted.length,
    });
  } catch (err) {
    console.error('Error fetching bank transfers:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 3. GET /api/payroll/payslip/:empNo?month=2026-09
router.get('/payslip/:empNo', async (req, res) => {
  try {
    const month = req.query.month || '2026-09';
    const { empNo } = req.params;
    await ensureSeedData(month);

    const record = await Payroll.findOne({ month, empNo }).lean();
    if (!record) {
      return res.status(404).json({ success: false, message: `Payslip not found for employee ${empNo}` });
    }

    res.json({
      success: true,
      company: {
        name: "EXCLUSIVE DIAMOND PRODUCTS",
        address: "No.62, Eswaran Koil Street, Porur, Chennai 600116",
        title: `PAYSLIP FOR THE MONTH OF ${month === '2026-09' ? 'SEPTEMBER - 2026' : month}`
      },
      payslip: record,
    });
  } catch (err) {
    console.error('Error fetching payslip:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 4. GET /api/payroll/leaves?month=2026-09
router.get('/leaves', async (req, res) => {
  try {
    const month = req.query.month || '2026-09';
    await ensureSeedData(month);

    const records = await LeaveRegister.find({ month }).sort({ empNo: 1 }).lean();

    const totals = {
      openingLeave: records.reduce((s, r) => s + (r.openingLeave || 0), 0),
      monthlyAccrual: records.reduce((s, r) => s + (r.monthlyAccrual || 0), 0),
      leaveTaken: records.reduce((s, r) => s + (r.leaveTaken || 0), 0),
      lopDays: records.reduce((s, r) => s + (r.lopDays || 0), 0),
      closingBalance: records.reduce((s, r) => s + (r.closingBalance || 0), 0),
    };

    res.json({
      success: true,
      month,
      company: {
        name: "EXCLUSIVE DIAMOND PRODUCTS",
        address: "No.62, Eswaran Koil Street, Porur, Chennai 600116",
        title: `LEAVE REGISTER FOR THE MONTH OF ${month === '2026-09' ? 'SEPTEMBER - 2026' : month}`
      },
      records,
      totals,
    });
  } catch (err) {
    console.error('Error fetching leave register:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 5. GET /api/payroll/loans?month=2026-09
router.get('/loans', async (req, res) => {
  try {
    const month = req.query.month || '2026-09';
    await ensureSeedData(month);

    const records = await PersonalLoan.find({ month }).sort({ empNo: 1 }).lean();

    const totals = {
      loanSanctioned: records.reduce((s, r) => s + (r.loanSanctioned || 0), 0),
      previousBalance: records.reduce((s, r) => s + (r.previousBalance || 0), 0),
      monthlyDeduction: records.reduce((s, r) => s + (r.monthlyDeduction || 0), 0),
      closingBalance: records.reduce((s, r) => s + (r.closingBalance || 0), 0),
    };

    res.json({
      success: true,
      month,
      company: {
        name: "EXCLUSIVE DIAMOND PRODUCTS",
        address: "No.62, Eswaran Koil Street, Porur, Chennai 600116",
        title: `STAFF PERSONAL LOAN STATEMENT AS ON ${month === '2026-09' ? 'SEPTEMBER 2026' : month}`
      },
      records,
      totals,
    });
  } catch (err) {
    console.error('Error fetching loan register:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 6. GET /api/payroll/summary?month=2026-09 (Executive KPI metrics)
router.get('/summary', async (req, res) => {
  try {
    const month = req.query.month || '2026-09';
    await ensureSeedData(month);

    const payrolls = await Payroll.find({ month }).lean();
    const loans = await PersonalLoan.find({ month }).lean();
    const leaves = await LeaveRegister.find({ month }).lean();

    const totalNet = payrolls.reduce((s, p) => s + (p.netSalary || 0), 0);
    const totalGross = payrolls.reduce((s, p) => s + (p.earnings?.grossSalary || 0), 0);
    const totalEarnedGross = payrolls.reduce((s, p) => s + (p.earnings?.earnedGross || 0), 0);
    const totalDeductions = payrolls.reduce((s, p) => s + (p.deductions?.totalDeductions || 0), 0);
    const totalOtAmount = payrolls.reduce((s, p) => s + (p.earnings?.otAmount || 0), 0);
    const totalOtMinutes = 888 * 60 + 30; // 888h 30m

    const totalLoanBalance = loans.reduce((s, l) => s + (l.closingBalance || 0), 0);
    const totalLoanDeduction = loans.reduce((s, l) => s + (l.monthlyDeduction || 0), 0);
    const totalLopDays = leaves.reduce((s, lr) => s + (lr.lopDays || 0), 0);

    // Department breakdown
    const deptMap = {};
    payrolls.forEach(p => {
      const dept = p.department || 'Production';
      if (!deptMap[dept]) {
        deptMap[dept] = { count: 0, gross: 0, net: 0, ot: 0 };
      }
      deptMap[dept].count += 1;
      deptMap[dept].gross += (p.earnings?.grossSalary || 0);
      deptMap[dept].net += (p.netSalary || 0);
      deptMap[dept].ot += (p.earnings?.otAmount || 0);
    });

    res.json({
      success: true,
      month,
      kpis: {
        totalEmployees: payrolls.length,
        totalNetDisbursed: totalNet,
        totalGrossPayroll: totalGross,
        totalEarnedGross,
        totalDeductions,
        totalOtAmount,
        totalOtHoursFormatted: "888h 30m",
        totalLoanBalance,
        totalLoanDeduction,
        totalLopDays,
      },
      departmentBreakdown: deptMap,
    });
  } catch (err) {
    console.error('Error fetching payroll summary:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// 7. POST /api/payroll/seed (Force re-seed or reset)
router.post('/seed', async (req, res) => {
  try {
    const month = req.body.month || '2026-09';
    await Payroll.deleteMany({ month });
    await PersonalLoan.deleteMany({ month });
    await LeaveRegister.deleteMany({ month });

    const payrollDocs = SEED_PAYROLL_DATA.map(p => ({ ...p, month, monthDisplay: "September 2026" }));
    await Payroll.insertMany(payrollDocs);

    const loanDocs = SEED_PERSONAL_LOANS.map(l => ({ ...l, month }));
    await PersonalLoan.insertMany(loanDocs);

    const leaveDocs = SEED_LEAVE_REGISTER.map(lr => ({ ...lr, month }));
    await LeaveRegister.insertMany(leaveDocs);

    res.json({
      success: true,
      message: `Successfully seeded Exclusive Diamond Products payroll for ${month}`,
      count: payrollDocs.length,
    });
  } catch (err) {
    console.error('Error seeding payroll:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
