require('dotenv').config({ path: 'backend/.env' });
const mongoose = require('mongoose');

async function run() {
  await mongoose.connect(process.env.MONGODB_URI);
  
  // Use the ItemDatabase model
  const ItemDatabase = require('./backend/models/ItemDatabase');
  
  const result = await ItemDatabase.deleteMany({
    $or: [
      { itemName: { $regex: '^ZEN', $options: 'i' } },
      { itemName: { $regex: '^ZPPL', $options: 'i' } }
    ]
  });
  
  console.log('Deleted count:', result.deletedCount);
  
  await mongoose.disconnect();
}

run().catch(console.error);
