const mongoose = require('mongoose');
require('dotenv').config();

const jobSchema = new mongoose.Schema({}, { strict: false });
const Job = mongoose.model('Job', jobSchema);

async function run() {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb+srv://siddarth:siddarth@cluster0.n1b8c.mongodb.net/edp?retryWrites=true&w=majority');
  
  const jobs = await Job.find({});
  
  const productionJobs = jobs.filter(j => {
    return j.status !== 'Removed' && 
           j.status !== 'Closed' && 
           j.status !== 'Delivered' && 
           j.status !== 'Returned' && 
           j.status !== 'Completed' && 
           j.status !== 'Blank Order' && 
           j.sentToSpare !== true && 
           !(j.jobType === 'Re-coating' && (j.status === 'Created' || j.status === 'Arrived' || j.status === 'Extracted'));
  });
  
  console.log(`Found ${productionJobs.length} production jobs total.`);
  for (const j of productionJobs) {
    const d = new Date(j.dispatchDate || j.createdAt);
    if (d.getFullYear() === 2026 && d.getMonth() === 6) { // July 2026
        console.log(`Job ID: ${j.jobId}, Status: ${j.status}, Type: ${j.jobType}, Location: ${j.currentLocation}, PO: ${j.poNotGiven}, SentToSpare: ${j.sentToSpare}`);
    }
  }
  
  process.exit(0);
}
run();
