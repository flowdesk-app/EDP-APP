require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log("Starting deletion of IN1...");

    const res = await ItemDatabase.deleteMany({ itemName: { $regex: /^IN1/i } });
    console.log(`Deleted ${res.deletedCount} items starting with "IN1"`);

    console.log("Done.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
