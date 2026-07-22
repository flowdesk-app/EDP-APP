const mongoose = require('mongoose');

const jobSchema = new mongoose.Schema({
  jobId: { type: String, required: true, unique: true },
  partNumber: { type: String },
  partDescription: { type: String },
  quantity: { type: Number },
  numberOfBins: { type: Number, default: 0 },
  numberOfBoxes: { type: Number, default: 0 },
  logisticsName: { type: String },
  deliveredQuantity: { type: Number, default: 0 },
  returnedQuantity: { type: Number, default: 0 },
  destinationType: { type: String, enum: ['Supplier', 'Customer', 'Internal Transfer'] },
  destinationName: { type: String },
  initialDestinationName: { type: String },
  processType: { type: String },
  vehicleNumber: { type: String },
  driverName: { type: String },
  driverMobile: { type: String },
  dispatchDate: { type: Date, default: Date.now },
  status: { type: String, enum: ['Created', 'Blank Order', 'PO Not Given', 'Dispatched', 'At Supplier', 'In Process', 'Returned', 'Delivered', 'Closed', 'Completed', 'Removed', 'Arrived', 'Extracted', 'Production', 'Delivery'], default: 'Created' },
  currentLocation: { type: String, default: 'EDP' },
  remarks: { type: String },
  supplier: { type: String },
  supplierChain: [{ type: String }],
  expectedReturnDate: { type: Date },
  attachments: [{ type: String }],
  statusHistory: [{
    status: { type: String },
    date: { type: Date },
    location: { type: String }
  }],
  supplierMovements: [{
    supplierName: { type: String },
    sentDate: { type: Date },
    receivedDate: { type: Date }
  }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  jobType: { type: String, enum: ['New', 'Re-coating'] },
  customerName: { type: String },
  wheelSize: { type: String },
  diamondPowderGritSize: { type: String },
  assignedWorker: { type: String },
  deliveryDate: { type: Date },
  customerOrderDate: { type: Date },
  customerSentDate: { type: Date },
  receivedDate: { type: Date },
  negotiationDone: { type: Boolean },
  returnableGatePassNumber: { type: String },
  returnableGatePassDate: { type: Date },
  extractionDate: { type: Date },
  expectedExtractionDate: { type: Date },
  extractionCompletedDate: { type: Date },
  productionDate: { type: Date },
  expectedProductionDate: { type: Date },
  purchaseOrderReceived: { type: Boolean },
  purchaseOrderNumber: { type: String },
  purchaseOrderDate: { type: Date },
  poNotGiven: { type: Boolean, default: false },
  inspectionReportNumber: { type: String },
  invoiceNumber: { type: String },
  sentToSpare: { type: Boolean, default: false },
  usedSpareId: { type: mongoose.Schema.Types.ObjectId, ref: 'Spare' },
  edpPurchaseOrderNumber: { type: String },
  edpPurchaseOrderDate: { type: Date },
  supplierPurchaseOrderNumber: { type: String },
  supplierPurchaseOrderDate: { type: Date }
}, { timestamps: true });

jobSchema.index({ jobId: 1 });
jobSchema.index({ partNumber: 1 });
jobSchema.index({ supplier: 1 });
jobSchema.index({ status: 1 });
jobSchema.index({ dispatchDate: -1 });
jobSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Job', jobSchema);
