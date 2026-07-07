const mongoose = require('mongoose');

const leadSchema = new mongoose.Schema({
  customerName: { type: String, required: true },
  wheelSize: { type: String, required: true },
  diamondPowderGritSize: { type: String, required: true },
  assignedWorker: { type: String, required: true },
  quotationGiven: { type: Boolean, default: false },
  negotiationDone: { type: Boolean, default: false },
  outcome: { type: String, enum: ['Pending', 'Accepted', 'Declined'], default: 'Pending' },
  status: { type: String, enum: ['Quotation Pending', 'Negotiation Pending', 'Outcome Pending', 'Declined', 'Converted'], default: 'Quotation Pending' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

leadSchema.index({ customerName: 1 });
leadSchema.index({ status: 1 });
leadSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Lead', leadSchema);
