const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const hashExistingPasswords = async () => {
    try {
        const users = await User.find();
        console.log(`Checking ${users.length} users for plain text passwords...`);

        let updatedCount = 0;

        for (const user of users) {
            const isHashed = user.password && user.password.startsWith('$2') && user.password.length === 60;
            
            if (!isHashed) {
                console.log(`Hashing password for user: ${user.email}`);
                const salt = await bcrypt.genSalt(10);
                const hashedPassword = await bcrypt.hash(user.password, salt);
                
                await User.updateOne({ _id: user._id }, { $set: { password: hashedPassword } });
                updatedCount++;
            }
        }

        if (updatedCount > 0) {
            console.log(`Migration Complete. Successfully hashed ${updatedCount} plain text passwords.`);
        }
    } catch (error) {
        console.error('Password migration failed:', error);
    }
};

module.exports = hashExistingPasswords;
