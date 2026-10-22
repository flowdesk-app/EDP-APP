const Job = require('../models/Job');

async function migrateJobAccess() {
    try {
        const result = await Job.updateMany(
            { accessGranted: { $exists: false } },
            { $set: { accessGranted: true, accessRequested: false } }
        );
        if (result.modifiedCount > 0) {
            console.log(`Migrated ${result.modifiedCount} existing jobs to accessGranted: true`);
        }
    } catch (e) {
        console.error('Error running migrateJobAccess:', e);
    }
}

module.exports = migrateJobAccess;
