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
    enum: ['Kg', 'Litre', 'Numbers', 'Carat', 'Grams'],
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
    enum: ['Kg', 'Litre', 'Numbers', 'Carat', 'Grams'],
    required: false,
  },
  category: {
    type: String,
    enum: ['Raw Material', 'Lapping Compound'],
    default: 'Raw Material',
  }
}, { timestamps: true });

const RawMaterial = mongoose.model('RawMaterial', rawMaterialSchema);

module.exports = RawMaterial;
