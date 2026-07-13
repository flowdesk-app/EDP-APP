const mongoose = require('mongoose');
require('dotenv').config({ path: __dirname + '/../.env' });
const Spare = require('../models/Spare');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const spares = await Spare.find().sort({createdAt: -1}).limit(10);
    console.log("Recent Spares:");
    spares.forEach(s => console.log(`ID: ${s._id}, Part: ${s.partNumber}, Status: ${s.status}, JobType: ${s.jobType}, Supplier: ${s.currentSupplier}`));
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
