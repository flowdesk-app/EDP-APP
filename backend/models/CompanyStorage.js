const mongoose = require('mongoose');

const CompanyStorageSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true
    },
    aliases: [{
        type: String
    }],
    prefixes: [{
        type: String
    }],
    billingAddress: {
        type: String,
        default: ''
    },
    shippingAddress: {
        type: String,
        default: ''
    },
    gstin: {
        type: String,
        default: ''
    },
    vendorCode: {
        type: String,
        default: ''
    },
    placeOfSupply: {
        type: String,
        default: ''
    },
    state: {
        type: String,
        default: ''
    },
    pincode: {
        type: String,
        default: ''
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('CompanyStorage', CompanyStorageSchema);
