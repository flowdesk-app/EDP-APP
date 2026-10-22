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

        // Ensure default users exist
        const defaultUsers = [
            { email: 'owner@flowdesk.com', password: 'password123', role: 'owner' },
            { email: 'admin@flowdesk.com', password: 'password123', role: 'admin' },
            { email: 'employee@flowdesk.com', password: 'password123', role: 'employee' },
            { email: 'employee1@flowdesk.com', password: 'password123', role: 'employee1' },
            { email: 'employee2@flowdesk.com', password: 'password123', role: 'employee2' },
            { email: 'employee3@flowdesk.com', password: 'password123', role: 'employee3' },
        ];

        for (const defUser of defaultUsers) {
            const existing = await User.findOne({ email: defUser.email });
            if (!existing) {
                await User.create({ email: defUser.email, password: defUser.password, role: defUser.role });
                console.log(`Created default user: ${defUser.email} (${defUser.role})`);
            } else {
                const isPwMatch = await bcrypt.compare(defUser.password, existing.password);
                if (!isPwMatch) {
                    existing.password = defUser.password;
                    await existing.save();
                    console.log(`Reset password for: ${defUser.email}`);
                }
                if (existing.role !== defUser.role) {
                    existing.role = defUser.role;
                    await existing.save();
                    console.log(`Updated user role: ${defUser.email} to ${defUser.role}`);
                }
            }
        }
    } catch (error) {
        console.error('Password migration failed:', error);
    }
};

module.exports = hashExistingPasswords;
