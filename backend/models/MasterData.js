const mongoose = require('mongoose');

const masterDataSchema = new mongoose.Schema({
  jobType: { type: String, enum: ['New', 'Re-coating'], required: true },
  field: { type: String, required: true }, // e.g., 'Customer Name', 'Part Number', 'Description', 'Grit Size', 'Person Responsible'
  value: { type: String, required: true }
}, { timestamps: true });

// Prevent duplicate entries for the same jobType and field
masterDataSchema.index({ jobType: 1, field: 1, value: 1 }, { unique: true });

module.exports = mongoose.model('MasterData', masterDataSchema);
