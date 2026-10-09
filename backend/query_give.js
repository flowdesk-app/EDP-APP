require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    const items = await ItemDatabase.find({ itemName: { $regex: /give/i } }).limit(5);
    console.log("GIVE items:", items.map(i => i.itemName));
    
    const exl = await ItemDatabase.find({ itemName: { $regex: /EXL/i } }).limit(5);
    console.log("EXL items:", exl.map(i => i.itemName));
    
    process.exit(0);
  });
