const mongoose = require('mongoose');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const User = require('./models/User');

dotenv.config();

const addUsers = async () => {
    await connectDB();
    
    const users = [
        { email: 'employee1@flowdesk.com', password: 'password123', role: 'employee1' },
        { email: 'employee2@flowdesk.com', password: 'password123', role: 'employee2' },
        { email: 'employee3@flowdesk.com', password: 'password123', role: 'employee3' }
    ];
    
    for (const u of users) {
        const exists = await User.findOne({ email: u.email });
        if (!exists) {
            await User.create(u);
            console.log('Added ' + u.email);
        } else {
            console.log(u.email + ' already exists');
        }
    }
    
    process.exit();
};

addUsers();
