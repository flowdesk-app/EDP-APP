const mongoose = require('mongoose');
const Job = require('./models/Job');
require('dotenv').config({path: './.env'});

mongoose.connect('mongodb://127.0.0.1/flowdesk')
  .then(async () => {
    const jobs = await Job.find({ status: 'Removed' }).sort({ createdAt: -1 }).limit(1);
    if (jobs.length > 0) {
      console.log(`Job: ${jobs[0].jobId}, Status: ${jobs[0].status}`);
      console.log(`History length: ${jobs[0].statusHistory ? jobs[0].statusHistory.length : 'undefined'}`);
      console.log(`History:`, JSON.stringify(jobs[0].statusHistory, null, 2));
    } else {
      console.log("No removed jobs found.");
    }
    process.exit(0);
  });
