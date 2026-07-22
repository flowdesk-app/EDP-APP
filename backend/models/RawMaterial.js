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
  gritSize: {
    type: String,
    required: false,
  },
  minimumQuantity: {
    type: Number,
    required: false,
    default: 0,
  },
  minimumUnit: {
    type: String,
    enum: ['Kg', 'Liter', 'Numbers', 'Carat'],
    required: false,
  }
}, { timestamps: true });

const RawMaterial = mongoose.model('RawMaterial', rawMaterialSchema);

module.exports = RawMaterial;
