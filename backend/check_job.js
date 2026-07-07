const mongoose = require('mongoose');
const uri = "mongodb+srv://flowdeskapps_db_user:Yf8tNUCmgj5vVtAK@cluster0.oryugt6.mongodb.net/flowdesk?retryWrites=true&w=majority&appName=Cluster0";
mongoose.connect(uri);
const Job = mongoose.model('Job', new mongoose.Schema({}, { strict: false }));
async function run() {
    const job = await Job.findOne({ jobId: 'JOB-51704617' });
    console.log("Job statusHistory:", job.statusHistory);
    console.log("Job supplierChain:", job.supplierChain);
    console.log("Job deliveredQuantity:", job.deliveredQuantity);
    process.exit(0);
}
run();
