const express = require('express');
const router = express.Router();
const JobMovement = require('../models/JobMovement');
const Delivery = require('../models/Delivery');
const Receipt = require('../models/Receipt');
const Job = require('../models/Job');
const AuditLog = require('../models/AuditLog');
const auth = require('../middleware/auth');

// @route   POST api/movements/receive
router.post('/receive', auth, async (req, res) => {
    try {
        const receipt = new Receipt({ ...req.body, recordedBy: req.user.id });
        await receipt.save();

        const job = await Job.findOne({ jobId: req.body.jobId });
        if (job) {
            job.status = 'Returned';
            job.currentLocation = 'EDP';
            await job.save();

            await JobMovement.create({
                jobId: job.jobId,
                partNumber: job.partNumber,
                quantity: req.body.receivedQuantity,
                source: req.body.supplierId, // Should fetch name in real app
                destination: 'EDP',
                recordedBy: req.user.id
            });
        }

        await AuditLog.create({
            userId: req.user.id,
            action: 'Material Received',
            details: { jobId: req.body.jobId, receivedQty: req.body.receivedQuantity }
        });

        res.json(receipt);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/movements/deliver
router.post('/deliver', auth, async (req, res) => {
    try {
        const delivery = new Delivery({ ...req.body, recordedBy: req.user.id });
        await delivery.save();

        if (req.body.jobId) {
            const job = await Job.findOne({ jobId: req.body.jobId });
            if (job) {
                job.status = 'Delivered';
                await job.save();
            }
        }

        await AuditLog.create({
            userId: req.user.id,
            action: 'Material Delivered',
            details: { customer: req.body.customerName, qty: req.body.quantity }
        });

        res.json(delivery);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
