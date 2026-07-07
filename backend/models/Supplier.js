const mongoose = require('mongoose');

const supplierSchema = new mongoose.Schema({
  supplierName: { type: String, required: true, unique: true },
  contactInfo: String,
  location: String,
}, { timestamps: true });

module.exports = mongoose.model('Supplier', supplierSchema);
