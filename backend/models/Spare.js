const mongoose = require('mongoose');

const spareSchema = new mongoose.Schema({
    partNumber: { type: String, required: true },
    description: { type: String },
    gritSize: { type: String },
    quantity: { type: Number, required: true, default: 1 },
    status: { type: String, enum: ['Blank', 'Finished'], default: 'Blank' },
    sourceJobId: { type: String }, // Job ID it was extracted from
    jobType: { type: String }, // 'New' or 'Re-coating'
    personResponsible: { type: String },
    expectedCompletionDate: { type: String },
    currentSupplier: { type: String }, // Supplier name where it is currently located, or null if at EDP
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Spare', spareSchema);
