const mongoose = require('mongoose');

const CompanyStorageSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true
    },
    prefixes: [{
        type: String
    }],
    isDeleted: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('CompanyStorage', CompanyStorageSchema);
