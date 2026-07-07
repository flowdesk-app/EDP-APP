const mongoose = require('mongoose');
const Job = require('./models/Job');
const dotenv = require('dotenv');

dotenv.config();

const seedJobs = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/flowdesk');
        console.log('Connected to MongoDB...');

        const fakeJobs = [
            {
                jobId: 'JOB-9001',
                partNumber: 'PART-A100',
                partDescription: 'Gearbox Housing',
                quantity: 50,
                destinationType: 'Supplier',
                destinationName: 'Acme Parts Ltd',
                supplier: 'Acme Parts Ltd',
                processType: 'Machining',
                status: 'Created',
                currentLocation: 'JyoAsh Engineers',
            },
            {
                jobId: 'JOB-9002',
                partNumber: 'PART-B200',
                partDescription: 'Drive Shaft',
                quantity: 120,
                destinationType: 'Supplier',
                destinationName: 'Globex Corp',
                supplier: 'Globex Corp',
                processType: 'Heat Treatment',
                status: 'Dispatched',
                currentLocation: 'In Transit',
            },
            {
                jobId: 'JOB-9003',
                partNumber: 'PART-C300',
                partDescription: 'Bearings',
                quantity: 500,
                destinationType: 'Supplier',
                destinationName: 'Stark Industries',
                supplier: 'Stark Industries',
                processType: 'Coating',
                status: 'In Process',
                currentLocation: 'Stark Industries',
            },
            {
                jobId: 'JOB-9004',
                partNumber: 'PART-D400',
                partDescription: 'Valve Assembly',
                quantity: 75,
                destinationType: 'Supplier',
                destinationName: 'Wayne Enterprises',
                supplier: 'Wayne Enterprises',
                processType: 'Testing',
                status: 'Delayed',
                currentLocation: 'Wayne Enterprises',
            },
            {
                jobId: 'JOB-9005',
                partNumber: 'PART-E500',
                partDescription: 'Piston Rings',
                quantity: 1000,
                destinationType: 'Supplier',
                destinationName: 'Acme Parts Ltd',
                supplier: 'Acme Parts Ltd',
                processType: 'Forging',
                status: 'At Supplier',
                currentLocation: 'Acme Parts Ltd',
            }
        ];

        for (const jobData of fakeJobs) {
            // Upsert based on jobId so we can run multiple times safely
            await Job.findOneAndUpdate({ jobId: jobData.jobId }, jobData, { upsert: true, new: true });
        }

        console.log('Successfully seeded 5 active fake jobs!');
        process.exit(0);
    } catch (err) {
        console.error('Error seeding jobs:', err);
        process.exit(1);
    }
};

seedJobs();
