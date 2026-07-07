const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const Job = require('./models/Job');
    const Part = require('./models/Part');
    const JobMovement = require('./models/JobMovement');

    console.log("Connected to MongoDB...");

    // Create a generic Part
    let part = await Part.findOne({ partNumber: 'PART-001' });
    if (!part) {
        part = await Part.create({
            partNumber: 'PART-001',
            partDescription: 'Industrial Gears (Type A)',
            customer: 'INEL',
            quantity: 100,
        });
    }

    // 1. Create Job 
    const newJob = await Job.create({
      jobId: 'JOB-' + Date.now(),
      partNumber: part.partNumber,
      partDescription: part.partDescription,
      quantity: 100,
      destinationType: 'Supplier',
      destinationName: 'VRS',
      processType: 'CNC Machining',
      vehicleNumber: 'TN-01-AB-1234',
      driverName: 'Raju',
      driverMobile: '9876543210',
      status: 'Dispatched',
      currentLocation: 'Transit'
    });
    console.log("Created Job:", newJob.jobId);

    // 2. Create Job Movement
    await JobMovement.create({
      jobId: newJob.jobId,
      partNumber: newJob.partNumber,
      quantity: 100,
      source: 'JyoAsh Engineers',
      destination: 'VRS',
      vehicleNumber: 'TN-01-AB-1234',
      driverName: 'Raju',
      driverMobile: '9876543210',
    });
    console.log("Created Job Movement for:", newJob.jobId);

    console.log("Data seeded successfully!");
    process.exit(0);
  }).catch(err => {
    console.error(err);
    process.exit(1);
  });
