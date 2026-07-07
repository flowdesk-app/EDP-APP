const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./models/User');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
      const users = await User.find({}).limit(5);
      console.log(users.map(u => u.email));
    } catch (e) {
      console.error(e.message);
    }
    process.exit();
  });
