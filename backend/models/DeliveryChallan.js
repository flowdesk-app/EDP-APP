const mongoose = require('mongoose');

const deliveryChallanItemSchema = new mongoose.Schema({
  itemNumber: { type: Number, required: true },
  jobId: { type: String },
  description: { type: String, required: true },
  quantity: { type: Number, default: 1 },
  unit: { type: String, default: 'No(s)' },
  approxValue: { type: Number, default: 1.00 },
});

const deliveryChallanSchema = new mongoose.Schema({
  dcNumber: { type: String, required: true, unique: true, index: true },
  date: { type: Date, default: Date.now },
  supplierName: { type: String, required: true },
  supplierAddress: { type: String, default: '' },
  supplierGstin: { type: String, default: '' },
  placeOfSupply: { type: String, default: 'Tamil Nadu (33)' },
  reference: { type: String, default: '' },
  challanType: { type: String, default: 'Job Work' },
  items: [deliveryChallanItemSchema],
  authorizedSignatoryFor: { type: String, default: 'Exclusive Diamond Products' },
  jobIds: [{ type: String }],
  status: { type: String, default: 'Active' },
  isDeleted: { type: Boolean, default: false },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('DeliveryChallan', deliveryChallanSchema);
