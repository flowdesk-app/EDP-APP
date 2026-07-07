const mongoose = require('mongoose');
require('dotenv').config();
const Job = require('./models/Job');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
      const jobs = await Job.find({status: 'Blank Order'}).sort({createdAt: -1}).limit(5);
      console.log(JSON.stringify(jobs.map(j => ({id: j.jobId, created: j.createdAt, status: j.status})), null, 2));
    } catch (e) {
      console.error(e.message);
    }
    process.exit();
  });
