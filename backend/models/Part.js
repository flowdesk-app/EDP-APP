const mongoose = require('mongoose');

const partSchema = new mongoose.Schema({
  partNumber: { type: String, required: true, unique: true },
  partDescription: { type: String, required: true },
  category: { type: String, default: 'General' },
  unit: { type: String, default: 'Nos' },
  customer: { type: String, required: true }, // e.g. INEL
  totalDispatched: { type: Number, default: 0 },
  totalReturned: { type: Number, default: 0 },
  totalDelivered: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('Part', partSchema);
