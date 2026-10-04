require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const result = await ItemDatabase.deleteMany({
    itemName: { $regex: '^LIPIN', $options: 'i' }
  });
  
  console.log('Deleted count:', result.deletedCount);
  
  await mongoose.disconnect();
}

run().catch(console.error);
