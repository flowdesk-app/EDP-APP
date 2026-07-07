const mongoose = require('mongoose');

const spareSchema = new mongoose.Schema({
    partNumber: { type: String, required: true },
    description: { type: String },
    gritSize: { type: String },
    quantity: { type: Number, required: true, default: 1 },
    status: { type: String, enum: ['Blank', 'Finished'], default: 'Blank' },
    sourceJobId: { type: String }, // Job ID it was extracted from
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Spare', spareSchema);
