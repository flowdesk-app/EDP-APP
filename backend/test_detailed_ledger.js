const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Job = require('./models/Job');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
        const jobs = await Job.find({ status: { $ne: 'Removed' } }).sort({ createdAt: 1 });
        let ledgerRows = [];
        let runningStock = {};
        
        jobs.forEach(job => {
            const part = job.partNumber;
            if (!part) return;
            if (!runningStock[part]) runningStock[part] = 0;

            if (job.status === 'Returned') {
                runningStock[part] -= job.quantity;
                ledgerRows.push({
                    date: job.createdAt,
                    partNumber: part,
                    supplier: job.initialDestinationName || 'Unknown',
                    dispatched: 0,
                    customer: '-',
                    delivered: 0,
                    rejected: job.quantity,
                    closingStock: runningStock[part]
                });
            } else {
                runningStock[part] += job.quantity;
                ledgerRows.push({
                    date: job.createdAt,
                    partNumber: part,
                    supplier: job.initialDestinationName || job.destinationName || 'Unknown',
                    dispatched: job.quantity,
                    customer: '-',
                    delivered: 0,
                    rejected: 0,
                    closingStock: runningStock[part]
                });

                if (job.status === 'Delivered') {
                    runningStock[part] -= job.quantity;
                    ledgerRows.push({
                        date: job.updatedAt,
                        partNumber: part,
                        supplier: '-',
                        dispatched: 0,
                        customer: job.destinationName || 'Customer',
                        delivered: job.quantity,
                        rejected: 0,
                        closingStock: runningStock[part]
                    });
                } else if (job.deliveredQuantity && job.deliveredQuantity > 0) {
                    runningStock[part] -= job.deliveredQuantity;
                    ledgerRows.push({
                        date: job.updatedAt,
                        partNumber: part,
                        supplier: '-',
                        dispatched: 0,
                        customer: job.destinationName || 'Customer',
                        delivered: job.deliveredQuantity,
                        rejected: 0,
                        closingStock: runningStock[part]
                    });
                }
            }
        });
        
        ledgerRows.sort((a, b) => new Date(b.date) - new Date(a.date));
        console.log("Total rows:", ledgerRows.length);
        console.log(JSON.stringify(ledgerRows.slice(0, 3), null, 2));
    } catch(e) { console.error("Error", e); }
    process.exit(0);
  })
  .catch(console.error);
