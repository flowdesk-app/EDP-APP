const mongoose = require('mongoose');
const Job = require('./backend/models/Job');

mongoose.connect('mongodb+srv://flowdeskapps_db_user:BwCjyTWnXnC9d87Y@cluster1.ylhvhpr.mongodb.net/flowdesk?retryWrites=true&w=majority&appName=Cluster1').then(async () => {
    const job = await Job.findOne({ jobId: '1555' });
    console.log(job);
    process.exit(0);
}).catch(console.error);
