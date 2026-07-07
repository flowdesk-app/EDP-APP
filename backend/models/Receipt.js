const mongoose = require('mongoose');

const receiptSchema = new mongoose.Schema({
  jobId: { type: String, required: true },
  supplierId: { type: mongoose.Schema.Types.ObjectId, ref: 'Supplier', required: true },
  receivedQuantity: { type: Number, required: true },
  rejectedQuantity: { type: Number, default: 0 },
  receivedDate: { type: Date, default: Date.now },
  remarks: { type: String },
  recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Receipt', receiptSchema);
