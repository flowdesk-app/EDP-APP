const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Job = require('./models/Job');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
        const jobs = await Job.find({ status: { $ne: 'Removed' } });
        const ledger = {};

        jobs.forEach(job => {
            const part = job.partNumber;
            if (!part) return;

            if (!ledger[part]) {
                ledger[part] = {
                    partNumber: part,
                    dispatched: 0,
                    delivered: 0,
                    returned: 0,
                    closingStock: 0
                };
            }

            if (job.status === 'Returned') {
                ledger[part].returned += job.quantity;
            } else {
                ledger[part].dispatched += job.quantity;
                if (job.status === 'Delivered') {
                    ledger[part].delivered += job.quantity;
                } else {
                    ledger[part].delivered += (job.deliveredQuantity || 0);
                }
            }
        });

        Object.values(ledger).forEach(l => {
            l.closingStock = l.dispatched - l.delivered - l.returned;
        });

        console.log("Ledger length:", Object.values(ledger).length);
        console.log(JSON.stringify(Object.values(ledger).slice(0, 2), null, 2));
    } catch(e) { console.error("Error", e); }
    process.exit(0);
  })
  .catch(console.error);
