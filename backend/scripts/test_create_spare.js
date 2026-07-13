const mongoose = require('mongoose');
require('dotenv').config({ path: __dirname + '/../.env' });
const Spare = require('../models/Spare');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
      const newSpare = new Spare({
          partNumber: '1417',
          quantity: 12,
          description: '200x4',
          gritSize: '20/40',
          status: 'Blank',
          sourceJobId: null,
          jobType: 'New',
          personResponsible: 'Guru',
          history: [{ supplier: 'EDP Spare Production', date: new Date() }],
          createdBy: "667e4e04ed9211075fc8c558"
      });
      const savedSpare = await newSpare.save();
      console.log('Saved successfully:', savedSpare);
    } catch (err) {
      console.error('Error saving spare:', err);
    }
    process.exit();
  });
