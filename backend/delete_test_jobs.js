const mongoose = require('mongoose');
require('dotenv').config();
const Job = require('./models/Job');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
      await Job.deleteMany({ jobId: { $regex: /^TEST-/ } });
      await Job.deleteMany({ jobId: "JOB-12345" });
      console.log('Cleaned up test jobs');
    } catch (e) {
      console.error(e.message);
    }
    process.exit();
  });
