require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const result = await ItemDatabase.deleteMany({
    $or: [
      { itemName: { $regex: '^PT 100 SENSOR', $options: 'i' } },
      { itemName: { $regex: '^DIGITAL CONTROL PANEL BOX', $options: 'i' } },
      { itemName: { $regex: '^Plastic Packing Boxes for Tools', $options: 'i' } }
    ]
  });
  
  console.log('Deleted count:', result.deletedCount);
  
  await mongoose.disconnect();
}

run().catch(console.error);
