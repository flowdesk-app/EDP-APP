const mongoose = require('mongoose');

const payrollAlertSchema = new mongoose.Schema({
  type: { type: String, default: 'loan_settlement' },
  empNo: { type: String, required: true },
  employeeName: { type: String, required: true },
  amount: { type: Number, default: 0 },
  message: { type: String, required: true },
  resolved: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('PayrollAlert', payrollAlertSchema);
