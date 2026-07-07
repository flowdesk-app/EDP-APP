const mongoose = require('mongoose');
const Job = require('./backend/models/Job');
require('dotenv').config({path: './backend/.env'});

mongoose.connect('mongodb://localhost:27017/edp_erp_db', { useNewUrlParser: true, useUnifiedTopology: true })
  .then(async () => {
    try {
      const job = new Job({
        jobId: 'TEST-123',
        jobType: 'New',
        status: 'Blank Order'
      });
      await job.save();
      console.log('Saved');
    } catch (e) {
      console.error(e);
    }
    process.exit();
  });
