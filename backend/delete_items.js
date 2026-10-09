require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const toDeleteExact = [
      "PIN Blanks",
      "Bright Pins",
      "Nylocast Spacers",
      "EDPT-40/60 red"
    ];

    console.log("Starting deletion...");

    for (let name of toDeleteExact) {
      const res = await ItemDatabase.deleteMany({ itemName: name });
      console.log(`Deleted ${res.deletedCount} items for exactly "${name}"`);
    }

    // Also all starting with TTT
    const resTTT = await ItemDatabase.deleteMany({ itemName: { $regex: /^TTT/i } });
    console.log(`Deleted ${resTTT.deletedCount} items starting with "TTT"`);

    console.log("Done.");
    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
