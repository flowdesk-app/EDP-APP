const mongoose = require('mongoose');

const jobMovementSchema = new mongoose.Schema({
  jobId: { type: String, required: true },
  partNumber: { type: String },
  quantity: { type: Number },
  source: { type: String, required: true }, // e.g. EDP, Supplier X
  destination: { type: String }, // e.g. Supplier Y, Customer Z
  movementDate: { type: Date, default: Date.now },
  vehicleNumber: { type: String },
  driverName: { type: String },
  driverMobile: { type: String },
  remarks: { type: String },
  recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('JobMovement', jobMovementSchema);
