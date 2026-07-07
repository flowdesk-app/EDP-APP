const mongoose = require('mongoose');
const uri = "mongodb+srv://flowdeskapps_db_user:Yf8tNUCmgj5vVtAK@cluster0.oryugt6.mongodb.net/flowdesk?retryWrites=true&w=majority&appName=Cluster0";
mongoose.connect(uri);
const Job = mongoose.model('Job', new mongoose.Schema({}, { strict: false }));
async function run() {
    const jobs = await Job.find({ status: { $ne: 'Removed' } });
    const vrsJobs = jobs.filter(j => j.supplierChain && j.supplierChain.some(s => s.includes('VRS')));
    console.log("Jobs with VRS in chain:", vrsJobs.map(j => ({ part: j.partNumber, qty: j.quantity, dqty: j.deliveredQuantity, currLoc: j.currentLocation, status: j.status, chain: j.supplierChain })));
    process.exit(0);
}
run();
