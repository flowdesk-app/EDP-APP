const mongoose = require('mongoose');

const payrollSchema = new mongoose.Schema({
  month: { type: String, required: true }, // Format: "YYYY-MM", e.g. "2026-09"
  monthDisplay: { type: String, default: "September 2026" },
  empNo: { type: String, required: true }, // e.g. "20004"
  employeeName: { type: String, required: true },
  designation: { type: String, required: true },
  department: { type: String, default: 'Production' },
  doj: { type: String, default: '01-04-2020' },
  bankDetails: {
    bankName: { type: String, default: 'State Bank of India' },
    accountNo: { type: String, default: '' },
    ifscCode: { type: String, default: '' },
  },
  statutory: {
    pfNo: { type: String, default: '' },
    uanNo: { type: String, default: '' },
    esiNo: { type: String, default: '' },
  },
  attendance: {
    totalDays: { type: Number, default: 30 },
    daysWorked: { type: Number, default: 30 },
    lopDays: { type: Number, default: 0 },
    otHoursFormatted: { type: String, default: '0h 0m' }, // e.g. "201.30" or "201h 30m"
    otHoursDecimal: { type: Number, default: 0 },
  },
  earnings: {
    basic: { type: Number, default: 0 },
    da: { type: Number, default: 0 },
    hra: { type: Number, default: 0 },
    conveyance: { type: Number, default: 0 },
    spl: { type: Number, default: 0 },
    medicalAlw: { type: Number, default: 0 },
    otherAlw: { type: Number, default: 0 },
    earnedGross: { type: Number, default: 0 },
    otAmount: { type: Number, default: 0 },
    grossSalary: { type: Number, default: 0 },
  },
  deductions: {
    pf: { type: Number, default: 0 },
    esi: { type: Number, default: 0 },
    advanceLoan: { type: Number, default: 0 },
    tds: { type: Number, default: 0 },
    insurance: { type: Number, default: 0 },
    others: { type: Number, default: 0 },
    totalDeductions: { type: Number, default: 0 },
  },
  netSalary: { type: Number, default: 0 },
  netSalaryWords: { type: String, default: '' },
  employerContribution: {
    pf: { type: Number, default: 0 },
    esi: { type: Number, default: 0 },
  },
  paymentStatus: { type: String, enum: ['Paid', 'Processing', 'Pending'], default: 'Paid' },
  paymentDate: { type: String, default: '05-10-2026' },
  paymentMode: { type: String, default: 'Online Bank Transfer' },
}, { timestamps: true });

payrollSchema.index({ month: 1, empNo: 1 }, { unique: true });

module.exports = mongoose.model('Payroll', payrollSchema);
