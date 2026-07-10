const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const Job = require('../models/Job');
const auth = require('../middleware/auth');

// @route   GET api/notifications
router.get('/', auth, async (req, res) => {
    try {
        // Auto-generate alerts for crossed dates
        const jobs = await Job.find({ status: { $nin: ['Delivered', 'Closed', 'Removed', 'Completed'] } });
        const now = new Date();
        now.setHours(0, 0, 0, 0);

        for (const job of jobs) {
            // Check expected extraction date
            if (job.expectedExtractionDate && new Date(job.expectedExtractionDate) < now) {
                const exists = await Notification.findOne({ jobId: job.jobId, alertKey: 'expectedExtractionDate' });
                if (!exists) {
                    await Notification.create({
                        jobId: job.jobId,
                        alertKey: 'expectedExtractionDate',
                        message: `Part No. ${job.partNumber || 'N/A'} (${job.customerName || 'N/A'}) crossed Expected Extraction Date.`,
                        type: 'delayed'
                    });
                }
            }
            
            // Check expected production date
            if (job.expectedProductionDate && new Date(job.expectedProductionDate) < now) {
                const exists = await Notification.findOne({ jobId: job.jobId, alertKey: 'expectedProductionDate' });
                if (!exists) {
                    await Notification.create({
                        jobId: job.jobId,
                        alertKey: 'expectedProductionDate',
                        message: `Part No. ${job.partNumber || 'N/A'} (${job.customerName || 'N/A'}) crossed Expected Production Date.`,
                        type: 'delayed'
                    });
                }
            }
        }

        const notifications = await Notification.find({ isDeleted: false }).sort({ createdAt: -1 });
        res.json(notifications);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/notifications/delete-bulk
router.post('/delete-bulk', auth, async (req, res) => {
    try {
        const { ids } = req.body;
        if (!ids || !Array.isArray(ids)) {
            return res.status(400).json({ msg: 'Please provide an array of notification ids.' });
        }
        await Notification.updateMany({ _id: { $in: ids } }, { $set: { isDeleted: true } });
        res.json({ msg: 'Notifications deleted successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
