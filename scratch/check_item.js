require('dotenv').config({ path: 'backend/.env' });
const mongoose = require('mongoose');
const ItemDatabase = require('./backend/models/ItemDatabase');

mongoose.connect(process.env.MONGO_URI).then(async () => {
    const item = await ItemDatabase.findOne({ itemName: /BILS-29/ });
    console.log(item);
    mongoose.connection.close();
});
