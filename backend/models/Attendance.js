const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  employeeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  employeeEmail: { type: String, required: true },
  employeeName: { type: String, required: true },
  role: { type: String },
  department: { type: String },
  date: { type: String, required: true }, // Format: YYYY-MM-DD
  clockInTime: { type: Date },
  clockOutTime: { type: Date },
  totalDurationMinutes: { type: Number, default: 0 },
  regularHours: { type: Number, default: 0 }, // Capped at 8.0 hrs
  overtimeHours: { type: Number, default: 0 }, // Duration exceeding 8.0 hrs
  status: {
    type: String,
    enum: ['Clocked In', 'Completed', 'Partial'],
    default: 'Clocked In',
  },
  scanMethod: {
    type: String,
    enum: ['face_recognition', 'manual'],
    default: 'face_recognition',
  },
  notes: { type: String },
}, { timestamps: true });

// Helper method to compute duration & overtime
attendanceSchema.methods.calculateShift = function () {
  if (this.clockInTime && this.clockOutTime) {
    const diffMs = this.clockOutTime.getTime() - this.clockInTime.getTime();
    const diffMins = Math.max(0, Math.round(diffMs / (1000 * 60)));
    this.totalDurationMinutes = diffMins;

    const totalHours = diffMins / 60.0;
    if (totalHours <= 8.0) {
      this.regularHours = parseFloat(totalHours.toFixed(2));
      this.overtimeHours = 0.0;
    } else {
      this.regularHours = 8.0;
      this.overtimeHours = parseFloat((totalHours - 8.0).toFixed(2));
    }
    this.status = 'Completed';
  } else if (this.clockInTime && !this.clockOutTime) {
    this.status = 'Clocked In';
    this.totalDurationMinutes = 0;
    this.regularHours = 0;
    this.overtimeHours = 0;
  }
};

attendanceSchema.index({ employeeEmail: 1, date: 1 });
attendanceSchema.index({ date: 1 });

module.exports = mongoose.model('Attendance', attendanceSchema);
