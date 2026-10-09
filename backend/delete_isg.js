require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log("Starting deletion of ISG...");

    const res = await ItemDatabase.deleteMany({ itemName: { $regex: /^ISG/i } });
    console.log(`Deleted ${res.deletedCount} items starting with ISG`);

    console.log("Done.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
