const mongoose = require('mongoose');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const User = require('./models/User');
const Supplier = require('./models/Supplier');
const Warehouse = require('./models/Warehouse');
const Job = require('./models/Job');

dotenv.config();

const seedDB = async () => {
    await connectDB();
    await User.deleteMany();
    await Supplier.deleteMany();
    await Warehouse.deleteMany();
    await Job.deleteMany();

    const admin = await User.create({ email: 'admin@flowdesk.com', password: 'password123', role: 'admin' });
    const employee = await User.create({ email: 'employee@flowdesk.com', password: 'password123', role: 'employee' });

    console.log('Database Seeded!');
    process.exit();
};

seedDB();
