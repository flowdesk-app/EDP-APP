const mongoose = require('mongoose');

const warehouseSchema = new mongoose.Schema({
  itemName: { type: String, required: true },
  quantity: { type: Number, required: true, default: 0 },
  pendingQuantity: { type: Number, default: 0 },
  material: { type: String },
  supplierIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Supplier' }],
  processHistory: [{ type: String }],
}, { timestamps: true });

module.exports = mongoose.model('Warehouse', warehouseSchema);
