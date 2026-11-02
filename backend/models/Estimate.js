const mongoose = require('mongoose');

const estimateSchema = new mongoose.Schema({
  calculationNo: { type: String, required: true },
  date: { type: Date, default: Date.now },
  jobId: { type: String }, // Optional link to a Job
  customerName: { type: String, required: true },
  itemDescription: { type: String },
  drawingNo: { type: String },
  type: { type: String, default: 'N' }, // 'N' for New, 'R' for Re-coating, 'C' for Coating, etc.
  calculationsNotes: { type: String },

  // Diamond & Coating Calculations
  effectiveCoatingArea: { type: Number, default: 0 },
  gritSize: { type: String },
  factor: { type: Number, default: 0 },
  diamondRequirement: { type: Number, default: 0 }, // carats (cts)
  diamondRate: { type: Number, default: 25 }, // INR / ct
  diamondCost: { type: Number, default: 0 },

  // Direct Operational Costs
  blankCost: { type: Number, default: 0 },
  grindingCost: { type: Number, default: 0 },
  extractionCost: { type: Number, default: 0 },
  balancingCost: { type: Number, default: 0 },
  transportationCost: { type: Number, default: 0 },

  // Margin & Process Cost
  directCostSum: { type: Number, default: 0 },
  marginPercentage: { type: Number, default: 25 }, // e.g. 25% or 20%
  subTotalInclMargin: { type: Number, default: 0 },
  processCost: { type: Number, default: 0 },
  totalCost: { type: Number, default: 0 },

  // Discount & Final Quotation
  discountProvisionPercentage: { type: Number, default: 15 }, // e.g. 15% or 20%
  provisionForDiscount: { type: Number, default: 0 },
  discountPercentage: { type: Number, default: 10 },
  qtnPrice: { type: Number, default: 0 }, // Final QTN price
  minOrderQty: { type: String },
  delivery: { type: String },
  qtnNoAndDate: { type: String },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

estimateSchema.index({ calculationNo: 1 });
estimateSchema.index({ jobId: 1 });
estimateSchema.index({ customerName: 1 });
estimateSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Estimate', estimateSchema);
