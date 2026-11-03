const mongoose = require('mongoose');

const personalLoanSchema = new mongoose.Schema({
  empNo: { type: String, required: true },
  employeeName: { type: String, required: true },
  department: { type: String, default: 'Production' },
  month: { type: String, required: true }, // Format "YYYY-MM", e.g. "2026-09"
  loanSanctioned: { type: Number, default: 0 },
  sanctionDate: { type: String, default: '01-01-2025' },
  previousBalance: { type: Number, default: 0 },
  monthlyDeduction: { type: Number, default: 0 },
  closingBalance: { type: Number, default: 0 },
  status: { type: String, enum: ['Active', 'Completed'], default: 'Active' },
  notes: { type: String, default: 'Monthly salary deduction' },
}, { timestamps: true });

personalLoanSchema.index({ month: 1, empNo: 1 }, { unique: true });

module.exports = mongoose.model('PersonalLoan', personalLoanSchema);
