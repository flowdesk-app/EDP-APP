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
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('CompanyStorage', CompanyStorageSchema);
