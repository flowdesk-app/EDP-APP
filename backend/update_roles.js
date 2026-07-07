const mongoose = require('mongoose');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const User = require('./models/User');

dotenv.config();

const updateRoles = async () => {
    await connectDB();
    
    // Clear existing users to start fresh with Admin and Employee
    await User.deleteMany();

    await User.create({ email: 'admin@flowdesk.com', password: 'password123', role: 'admin' });
    await User.create({ email: 'employee@flowdesk.com', password: 'password123', role: 'employee' });

    console.log('Roles Updated to Admin and Employee!');
    process.exit();
};

updateRoles();
