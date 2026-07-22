const mongoose = require('mongoose');
const Job = require('./models/Job');

mongoose.connect('mongodb://127.0.0.1:27017/flowdesk').then(async () => { 
  const jobs = await Job.find({}, 'jobId jobType status currentLocation customerName partNumber sentToSpare').lean(); 
  console.log(jobs.filter(j => !['Removed', 'Closed', 'Delivered', 'Returned', 'Completed'].includes(j.status))); 
  process.exit(0); 
});
