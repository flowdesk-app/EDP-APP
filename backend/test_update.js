const mongoose = require('mongoose');
const Job = require('./models/Job');

mongoose.connect('mongodb+srv://flowdeskapps_db_user:BwCjyTWnXnC9d87Y@cluster1.ylhvhpr.mongodb.net/flowdesk?retryWrites=true&w=majority&appName=Cluster1').then(async () => {
    await Job.updateOne({ jobId: 'JOB-52037795' }, {
        $set: {
            expectedExtractionDate: new Date('2026-07-05T18:30:00.000Z'),
            expectedProductionDate: new Date('2026-07-06T18:30:00.000Z')
        }
    });
    console.log("Updated");
    process.exit(0);
}).catch(console.error);
