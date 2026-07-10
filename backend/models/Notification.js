const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  message: { type: String, required: true },
  type: { type: String, enum: ['completed', 'delayed', 'info', 'delivered'] },
  read: { type: Boolean, default: false },
  jobId: { type: String },
  alertKey: { type: String },
  isDeleted: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
