const mongoose = require('mongoose');

const binBoxReturnSchema = new mongoose.Schema({
  destinationName: { type: String, required: true },
  returnedBins: { type: Number, default: 0 },
  returnedBoxes: { type: Number, default: 0 },
  date: { type: Date, default: Date.now },
});

module.exports = mongoose.model('BinBoxReturn', binBoxReturnSchema);
