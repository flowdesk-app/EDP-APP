const mongoose = require('mongoose');

const CustomerSchema = new mongoose.Schema({
    customerName: {
        type: String,
        required: true,
        unique: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Customer', CustomerSchema);
