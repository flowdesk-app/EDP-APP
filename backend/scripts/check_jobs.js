const mongoose = require('mongoose');
require('dotenv').config({ path: __dirname + '/../.env' });
const Job = require('../models/Job');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const jobs = await Job.find({ partNumber: "1417" }).sort({createdAt: -1}).limit(5);
    console.log("Recent Jobs for 1417:");
    jobs.forEach(j => console.log(`ID: ${j.jobId}, Part: ${j.partNumber}, Status: ${j.status}, sentToSpare: ${j.sentToSpare}, CreatedAt: ${j.createdAt}`));
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
