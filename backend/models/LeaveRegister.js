const mongoose = require('mongoose');

const leaveRegisterSchema = new mongoose.Schema({
  month: { type: String, required: true }, // Format "YYYY-MM", e.g. "2026-09"
  empNo: { type: String, required: true },
  employeeName: { type: String, required: true },
  department: { type: String, default: 'Production' },
  openingLeave: { type: Number, default: 0 },
  monthlyAccrual: { type: Number, default: 1.5 },
  leaveTaken: { type: Number, default: 0 },
  lopDays: { type: Number, default: 0 },
  closingBalance: { type: Number, default: 0 },
  remarks: { type: String, default: '' },
}, { timestamps: true });

leaveRegisterSchema.index({ month: 1, empNo: 1 }, { unique: true });

module.exports = mongoose.model('LeaveRegister', leaveRegisterSchema);
