const mongoose = require('mongoose');

const spareSupplierSchema = new mongoose.Schema({
  supplierName: { type: String, required: true, unique: true },
  contactInfo: String,
  location: String,
}, { timestamps: true });

module.exports = mongoose.model('SpareSupplier', spareSupplierSchema);
