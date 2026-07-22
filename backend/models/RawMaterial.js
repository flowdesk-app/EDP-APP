const mongoose = require('mongoose');

const rawMaterialSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  availableQuantity: {
    type: Number,
    required: true,
    default: 0,
  },
  availableUnit: {
    type: String,
    enum: ['Kg', 'Liter', 'Numbers', 'Carat'],
    required: true,
  },
  minimumQuantity: {
    type: Number,
    required: true,
    default: 0,
  },
  minimumUnit: {
    type: String,
    enum: ['Kg', 'Liter', 'Numbers', 'Carat'],
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update the updatedAt field before saving
rawMaterialSchema.pre('save', function (next) {
  this.updatedAt = Date.now();
  next();
});

const RawMaterial = mongoose.model('RawMaterial', rawMaterialSchema);

module.exports = RawMaterial;
