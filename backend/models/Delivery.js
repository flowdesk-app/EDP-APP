const mongoose = require('mongoose');

const deliverySchema = new mongoose.Schema({
  customerName: { type: String, required: true },
  partNumber: { type: String, required: true },
  quantity: { type: Number, required: true },
  vehicleNumber: { type: String },
  dispatchDate: { type: Date, default: Date.now },
  deliveryNoteNumber: { type: String },
  jobId: { type: String }, // Optional link to specific job
  recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Delivery', deliverySchema);
