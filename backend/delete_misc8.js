require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const result = await ItemDatabase.deleteMany({
    $or: [
      { itemName: { $regex: '^General', $options: 'i' } },
      { itemName: { $regex: '^Chemical', $options: 'i' } },
      { itemName: { $regex: '^Rectifier', $options: 'i' } },
      { itemName: { $regex: '^Audit Fees', $options: 'i' } },
      { itemName: { $regex: '^De-Mineralised Water', $options: 'i' } },
      { itemName: { $regex: '^Transport Charges', $options: 'i' } },
      { itemName: { $regex: '^ATC', $options: 'i' } }
    ]
  });
  
  console.log('Deleted count:', result.deletedCount);
  
  await mongoose.disconnect();
}

run().catch(console.error);
