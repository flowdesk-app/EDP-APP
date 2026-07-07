const mongoose = require('mongoose');
const Job = require('./models/Job');

mongoose.connect('mongodb+srv://flowdeskapps_db_user:BwCjyTWnXnC9d87Y@cluster1.ylhvhpr.mongodb.net/flowdesk?retryWrites=true&w=majority&appName=Cluster1').then(async () => {
    const job = await Job.findOne({ customerName: /Sundar/i });
    console.log(job);
    process.exit(0);
}).catch(console.error);
