require('dotenv').config();
const mongoose = require('mongoose');
const ItemDatabase = require('./models/ItemDatabase');

mongoose.connect(process.env.MONGO_URI).then(async () => {
    const item = await ItemDatabase.findOne({ itemName: /BILS-29LU0165/ });
    console.log(item);
    mongoose.connection.close();
});
