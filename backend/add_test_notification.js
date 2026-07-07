const mongoose = require('mongoose');
const Notification = require('./models/Notification');
const dotenv = require('dotenv');

dotenv.config();

const addNotification = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/flowdesk');
        
        console.log('Connected to MongoDB...');
        
        const newNotif = new Notification({
            message: 'Warning: JOB-001 is severely delayed at the supplier site.',
            type: 'delayed',
            read: false
        });
        
        await newNotif.save();
        console.log('Test notification added successfully!');
        
        process.exit(0);
    } catch (err) {
        console.error('Error adding notification:', err);
        process.exit(1);
    }
};

addNotification();
