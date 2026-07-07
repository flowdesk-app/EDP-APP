const mongoose = require('mongoose');
require('dotenv').config({path: './backend/.env'});
const Job = require('./backend/models/Job');
const JobMovement = require('./backend/models/JobMovement');
const AuditLog = require('./backend/models/AuditLog');

mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(async () => {
    try {
      console.log('Connected to Atlas');
      // find a user for audit log
      const User = require('./backend/models/User');
      const user = await User.findOne({role: 'admin'});
      
      const payload = {
        jobId: 'TEST-127',
        jobType: 'New',
        status: 'Blank Order',
        currentLocation: 'EDP',
        createdDate: new Date()
      };
      
      const newJob = new Job({ ...payload, createdBy: user._id, initialDestinationName: payload.destinationName });
        newJob.statusHistory = [{
            status: 'Created',
            date: new Date(),
            location: 'EDP'
        }];
        const job = await newJob.save();
        console.log('Job saved');
        
        await JobMovement.create({
            jobId: job.jobId,
            partNumber: job.partNumber,
            quantity: job.quantity,
            source: 'EDP',
            destination: job.destinationName,
            vehicleNumber: job.vehicleNumber,
            driverName: job.driverName,
            driverMobile: job.driverMobile,
            recordedBy: user._id
        });
        console.log('JobMovement saved');
        
    } catch (e) {
      console.error("ERROR CAUGHT:");
      console.error(e.message);
    }
    process.exit();
  });
