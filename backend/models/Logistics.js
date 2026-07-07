const mongoose = require('mongoose');

const logisticsSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true }
}, { timestamps: true });

module.exports = mongoose.model('Logistics', logisticsSchema);
