const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const Job = require('./models/Job');
    const Warehouse = require('./models/Warehouse');
    const Notification = require('./models/Notification');

    console.log("Connected to MongoDB, clearing fake data...");

    await Job.deleteMany({});
    console.log("Cleared all Jobs.");

    await Warehouse.deleteMany({});
    console.log("Cleared all Warehouse items.");

    await Notification.deleteMany({});
    console.log("Cleared all Notifications.");

    console.log("Database cleaned. Only Users and Suppliers remain.");
    process.exit(0);
  }).catch(err => {
    console.error(err);
    process.exit(1);
  });
