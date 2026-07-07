const mongoose = require('mongoose');
require('dotenv').config({path: './backend/.env'});
mongoose.connect(process.env.MONGO_URI).then(async () => {
    const Job = require('./backend/models/Job');
    const jobs = await Job.find({ status: { $ne: 'Removed' } });
    console.log(`Found ${jobs.length} jobs.`);
    if (jobs.length > 0) {
        console.log('Sample job:', JSON.stringify(jobs[0], null, 2));
        console.log('Unique Part Numbers:', [...new Set(jobs.map(j => j.partNumber))]);
    }
    process.exit(0);
});
