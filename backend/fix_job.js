const mongoose = require('mongoose');
const uri = "mongodb+srv://flowdeskapps_db_user:Yf8tNUCmgj5vVtAK@cluster0.oryugt6.mongodb.net/flowdesk?retryWrites=true&w=majority&appName=Cluster0";
mongoose.connect(uri);
const Job = mongoose.model('Job', new mongoose.Schema({}, { strict: false }));
async function run() {
    const job = await Job.findOne({ jobId: 'JOB-51704617' });
    if (job) {
        job.deliveredQuantity = null;
        job.currentLocation = 'VRS';
        if (job.statusHistory && job.statusHistory.length === 2 && job.statusHistory[1].status === 'Forwarded to Star') {
            job.statusHistory.push({
                status: 'Forwarded to VRS',
                date: new Date(),
                location: 'VRS'
            });
        }
        await job.save();
        console.log("Job fixed!");
    }
    process.exit(0);
}
run();
