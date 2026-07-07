const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Job = require('../models/Job');
const JobMovement = require('../models/JobMovement');
const AuditLog = require('../models/AuditLog');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Supplier = require('../models/Supplier');
const auth = require('../middleware/auth');

// @route   GET api/jobs/workers
// @desc    Get a list of distinct assigned workers
router.get('/workers', auth, async (req, res) => {
    try {
        const workers = await Job.distinct('assignedWorker');
        // Filter out nulls or empty strings
        const filteredWorkers = workers.filter(w => w && w.trim() !== '');
        res.json(filteredWorkers);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/jobs
router.get('/', auth, async (req, res) => {
    try {
        const jobs = await Job.find().sort({ createdAt: -1 });
        res.json(jobs);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/jobs
router.post('/', auth, async (req, res) => {
    try {
        const payload = { ...req.body };
        if (payload.destinationType === 'Supplier') {
            payload.supplier = payload.destinationName;
            payload.supplierChain = [payload.destinationName];
        } else if (payload.destinationType === 'Customer') {
            payload.supplier = null;
            payload.supplierChain = [];
        }
        const newJob = new Job({ ...payload, createdBy: req.user.id, initialDestinationName: payload.destinationName });
        newJob.statusHistory = [{
            status: 'Created',
            date: new Date(),
            location: 'EDP'
        }];
        const job = await newJob.save();

        // Log the initial movement
        await JobMovement.create({
            jobId: job.jobId,
            partNumber: job.partNumber,
            quantity: job.quantity,
            source: 'EDP',
            destination: job.destinationName,
            vehicleNumber: job.vehicleNumber,
            driverName: job.driverName,
            driverMobile: job.driverMobile,
            recordedBy: req.user.id
        });

        await AuditLog.create({
            userId: req.user.id,
            action: 'Job Created',
            details: { jobId: job.jobId, destination: job.destinationName }
        });

        const MasterData = require('../models/MasterData');
        const jobType = job.jobType || 'New';
        const fieldsToSave = [
            { field: 'Customer Name', value: job.customerName },
            { field: 'Part Number', value: job.partNumber },
            { field: 'Description', value: job.wheelSize || job.partDescription },
            { field: 'Grit Size', value: job.diamondPowderGritSize },
            { field: 'Person Responsible', value: job.assignedWorker }
        ];

        for (let f of fieldsToSave) {
            if (f.value && f.value.trim() !== '') {
                await MasterData.updateOne(
                    { jobType, field: f.field, value: f.value.trim() },
                    { $set: { jobType, field: f.field, value: f.value.trim() } },
                    { upsert: true }
                ).catch(e => console.error('Error saving master data:', e));
            }
        }

        res.json(job);
    } catch (err) {
        console.error("POST /jobs Error:", err.stack || err);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/jobs/:id
router.put('/:id', auth, async (req, res) => {
    try {
        let job = await Job.findById(req.params.id).catch(() => null);
        if (!job) {
            job = await Job.findOne({ jobId: req.params.id });
        }
        if (!job) return res.status(404).send('Job not found');

        job = await Job.findByIdAndUpdate(job._id, req.body, { new: true });
        
        await AuditLog.create({
            userId: req.user.id,
            action: 'Job Edited',
            details: { jobId: job.jobId }
        });

        res.json(job);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/jobs/:id/status
router.put('/:id/status', auth, async (req, res) => {
    try {
        const { status, currentLocation, deliveredQuantity, extractionDate, expectedExtractionDate, extractionCompletedDate, productionDate, expectedProductionDate, inspectionReportNumber, invoiceNumber } = req.body;

        let job = await Job.findById(req.params.id).catch(() => null);
        if (!job) job = await Job.findOne({ jobId: req.params.id });
        if (!job) return res.status(404).send('Job not found');

        let oldStatus = job.status;

        if (status === 'Delivered' && deliveredQuantity) {
            if (inspectionReportNumber) job.inspectionReportNumber = inspectionReportNumber;
            if (invoiceNumber) job.invoiceNumber = invoiceNumber;
            const qty = parseInt(deliveredQuantity, 10);
            const jobAvailable = job.quantity - (job.deliveredQuantity || 0);

            if (qty > 0 && qty < jobAvailable) {
                // Partial Delivery
                job.deliveredQuantity = (job.deliveredQuantity || 0) + qty;
                if (!job.supplierChain) job.supplierChain = [];
                job.supplierChain.push(`Delivered (${currentLocation || 'Unknown'}) ${qty} parts`);
                
                if (!job.statusHistory) job.statusHistory = [];
                job.statusHistory.push({
                    status: 'Partial Delivery',
                    date: new Date(),
                    location: currentLocation || job.currentLocation
                });
            } else if (qty >= jobAvailable) {
                // Full Delivery
                job.deliveredQuantity = job.quantity;
                job.status = 'Delivered';
                if (currentLocation) {
                    job.currentLocation = currentLocation;
                    job.destinationName = currentLocation;
                    job.destinationType = 'Customer';
                }
                if (!job.supplierChain) job.supplierChain = [];
                job.supplierChain.push(`Delivered (${currentLocation || 'Unknown'}) ${jobAvailable} parts`);
                
                if (!job.statusHistory) job.statusHistory = [];
                job.statusHistory.push({
                    status: 'Delivered',
                    date: new Date(),
                    location: job.currentLocation
                });
            }
        } else {
            job.status = status;
            if (extractionDate) job.extractionDate = extractionDate;
            if (expectedExtractionDate) job.expectedExtractionDate = expectedExtractionDate;
            if (extractionCompletedDate) job.extractionCompletedDate = extractionCompletedDate;
            if (productionDate) job.productionDate = productionDate;
            if (expectedProductionDate) job.expectedProductionDate = expectedProductionDate;
            
            if (currentLocation) {
                job.currentLocation = currentLocation;
                if (status === 'Delivered') {
                    job.destinationName = currentLocation;
                    job.destinationType = 'Customer';
                    // Also update the supplier chain to include the final customer
                    if (job.supplierChain) {
                        job.supplierChain.push(currentLocation);
                    }
                }
            } else {
                // Automatically determine current location based on status mapping
                if (status === 'Dispatched' || status === 'At Supplier') {
                    job.currentLocation = job.destinationName;
                } else if (status === 'Returned') {
                    job.currentLocation = 'EDP';
                } else if (status === 'Delivered') {
                    job.currentLocation = job.destinationName;
                } else if (status === 'Closed') {
                    job.currentLocation = 'Delivered';
                } else if (status === 'Created') {
                    job.currentLocation = 'EDP';
                }
            }

            if (!job.statusHistory) {
                job.statusHistory = [];
            }
            job.statusHistory.push({
                status,
                date: new Date(),
                location: job.currentLocation
            });
        }

        await job.save();

        await AuditLog.create({
            userId: req.user.id,
            action: 'Status Updated',
            details: { jobId: job.jobId, newStatus: status, newLocation: job.currentLocation }
        });

        if (status === 'Delayed') {
            await Notification.create({
                message: `Warning: ${job.partNumber} is severely delayed at the supplier site.`,
                type: 'delayed'
            });
        }

        res.json(job);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/jobs/:id/forward
router.put('/:id/forward', auth, async (req, res) => {
    try {
        const { nextSupplier } = req.body;
        let job = await Job.findById(req.params.id).catch(() => null);
        if (!job) job = await Job.findOne({ jobId: req.params.id });
        if (!job) return res.status(404).send('Job not found');

        if (!job.supplierChain || job.supplierChain.length === 0) {
            job.supplierChain = job.supplier ? [job.supplier] : [];
        }
        // Filter out empty strings if any, then push
        job.supplierChain = job.supplierChain.filter(s => s);
        job.supplierChain.push(nextSupplier);

        job.supplier = nextSupplier;
        job.destinationName = nextSupplier;
        job.destinationType = 'Supplier';
        job.status = 'At Supplier'; // Mark it 'At Supplier' so the badge reflects where it is
        job.currentLocation = nextSupplier;

        if (!job.statusHistory) {
            job.statusHistory = [];
        }
        job.statusHistory.push({
            status: 'Forwarded to ' + nextSupplier,
            date: new Date(),
            location: job.currentLocation
        });

        await job.save();

        await AuditLog.create({
            userId: req.user.id,
            action: 'Job Forwarded',
            details: { jobId: job.jobId, nextSupplier }
        });

        res.json(job);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/jobs/:id
router.delete('/:id', auth, async (req, res) => {
    try {
        let job = await Job.findById(req.params.id).catch(() => null);
        if (!job) job = await Job.findOne({ jobId: req.params.id });
        if (!job) return res.status(404).send('Job not found');

        await Job.findByIdAndDelete(job._id);

        await AuditLog.create({
            userId: req.user.id,
            action: 'Job Deleted',
            details: { jobId: job.jobId }
        });

        res.json({ msg: 'Job permanently deleted' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/jobs/:id/undo
// @desc    Undo the last action of a job
// @access  Private
router.put('/:id/undo', auth, async (req, res) => {
    try {
        let job = await Job.findById(req.params.id).catch(() => null);
        if (!job) job = await Job.findOne({ jobId: req.params.id });
        if (!job) return res.status(404).send('Job not found');

        if (!job.statusHistory || job.statusHistory.length <= 1) {
            return res.status(400).json({ msg: 'Job is already at initial state' });
        }

        const undoneHistory = job.statusHistory.pop();
        const previousHistory = job.statusHistory[job.statusHistory.length - 1];

        if (undoneHistory.status.startsWith('Forwarded to ') || undoneHistory.status === 'Delivered' || undoneHistory.status === 'Partial Delivery' || undoneHistory.status === 'Returned') {
            if (job.supplierChain && job.supplierChain.length > 0) {
                job.supplierChain.pop();
            }
        }

        // Recalculate deliveredQuantity and returnedQuantity based on remaining supplierChain
        let totalReturned = 0;
        let deliveredRemaining = 0;
        if (job.supplierChain) {
            job.supplierChain.forEach(item => {
                if (item.startsWith('Delivered')) {
                    const match = item.match(/(\d+)\s+parts/);
                    if (match) {
                        deliveredRemaining += parseInt(match[1], 10);
                    }
                } else if (item.startsWith('Returned')) {
                    const match = item.match(/(\d+)\s+parts/);
                    if (match) {
                        const qty = parseInt(match[1], 10);
                        totalReturned += qty;
                        if (deliveredRemaining > 0) {
                            deliveredRemaining = Math.max(0, deliveredRemaining - qty);
                        }
                    }
                }
            });
        }
        job.deliveredQuantity = deliveredRemaining > 0 ? deliveredRemaining : null;
        job.returnedQuantity = totalReturned > 0 ? totalReturned : 0;

        let actualStatus = 'Created';
        let actualLocation = 'Unknown';
        for (let i = job.statusHistory.length - 1; i >= 0; i--) {
            if (job.statusHistory[i].status !== 'Partial Delivery') {
                actualStatus = job.statusHistory[i].status;
                actualLocation = job.statusHistory[i].location;
                break;
            }
        }

        let newStatus = actualStatus;
        if (newStatus.startsWith('Forwarded to ')) {
            newStatus = 'At Supplier';
        }
        job.status = newStatus;
        job.currentLocation = actualLocation;

        if (job.supplierChain && job.supplierChain.length > 0) {
            job.supplier = job.supplierChain[job.supplierChain.length - 1];
            job.destinationName = job.supplier;
            job.destinationType = 'Supplier';
        } else {
            // Restore original destination
            const initialMovement = await JobMovement.findOne({ jobId: job.jobId }).sort({ createdAt: 1 });
            if (initialMovement) {
                job.destinationName = initialMovement.destination;
                job.supplier = null;
                const isSupplier = await Supplier.findOne({ supplierName: initialMovement.destination });
                if (isSupplier) {
                    job.destinationType = 'Supplier';
                    job.supplier = initialMovement.destination;
                    job.supplierChain = [initialMovement.destination];
                } else {
                    job.destinationType = 'Customer';
                }
            } else {
                job.supplier = null;
                job.destinationName = 'Unknown';
            }
        }

        await job.save();

        await AuditLog.create({
            userId: req.user.id,
            action: 'Job Undo',
            details: { jobId: job.jobId, revertedFrom: undoneHistory.status, revertedTo: job.status }
        });

        res.json(job);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/jobs/:id/restore
// @desc    Restore a removed job to its previous status
// @access  Private
router.put('/:id/restore', auth, async (req, res) => {
    try {
        const job = await Job.findOne({ jobId: req.params.id });
        if (!job) return res.status(404).json({ msg: 'Job not found' });

        if (job.status !== 'Removed') {
            return res.status(400).json({ msg: 'Job is not removed' });
        }

        // Find the most recent status before 'Removed'
        let previousStatus = 'Created';
        if (job.statusHistory && job.statusHistory.length > 0) {
            // Traverse backwards to find the first status that is not 'Removed'
            for (let i = job.statusHistory.length - 1; i >= 0; i--) {
                if (job.statusHistory[i].status !== 'Removed') {
                    previousStatus = job.statusHistory[i].status;
                    break;
                }
            }
        }

        job.status = previousStatus;
        if (!job.statusHistory) {
            job.statusHistory = [];
        }
        job.statusHistory.push({
            status: previousStatus,
            date: new Date(),
            location: 'System Restored'
        });

        await job.save();

        res.json({ msg: 'Job restored', job });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/jobs/supplier
// @desc    Get jobs assigned to the logged-in supplier
// @access  Private
router.get('/supplier', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user || !user.supplierId) {
            return res.status(400).json({ msg: 'User is not a supplier' });
        }
        const supplier = await Supplier.findById(user.supplierId);
        if (!supplier) {
            return res.status(404).json({ msg: 'Supplier not found' });
        }

        const jobs = await Job.find({ 
            destinationType: 'Supplier', 
            destinationName: supplier.supplierName 
        }).sort({ createdAt: -1 });

        res.json(jobs);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/jobs/filter
router.get('/filter', auth, async (req, res) => {
    try {
        const { month, date, supplier, partNumber, status } = req.query;
        let query = {};
        
        if (month) {
            // month format e.g. "2026-06"
            const parts = month.split('-');
            if (parts.length === 2) {
                const y = parseInt(parts[0], 10);
                const m = parseInt(parts[1], 10);
                const start = new Date(y, m - 1, 1);
                const end = new Date(y, m, 0, 23, 59, 59, 999);
                query.createdAt = { $gte: start, $lte: end };
            }
        }
        if (date) {
            // date format e.g. "2026-04-15"
            const start = new Date(date);
            start.setHours(0,0,0,0);
            const end = new Date(date);
            end.setHours(23,59,59,999);
            query.createdAt = { $gte: start, $lte: end };
        }
        if (supplier) query.supplier = supplier;
        if (partNumber) query.partNumber = partNumber;
        if (status) {
            query.status = status;
        } else {
            query.status = { $ne: 'Removed' };
        }

        const jobs = await Job.find(query).sort({ createdAt: -1 });
        res.json(jobs);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/jobs/search
router.get('/search', auth, async (req, res) => {
    try {
        const { q } = req.query;
        if (!q) return res.json([]);
        
        const jobs = await Job.find({
            $or: [
                { jobId: { $regex: q, $options: 'i' } },
                { partNumber: { $regex: q, $options: 'i' } }
            ]
        }).sort({ createdAt: -1 });
        res.json(jobs);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/jobs/ready-for-delivery
router.get('/ready-for-delivery', auth, async (req, res) => {
    try {
        const jobs = await Job.find({ status: { $in: ['Completed', 'Delivered'] } }).sort({ createdAt: 1 });
        const aggregated = {};
        jobs.forEach(job => {
            const available = job.quantity - (job.deliveredQuantity || 0);
            if (available > 0) {
                if (!aggregated[job.partNumber]) {
                    aggregated[job.partNumber] = {
                        partNumber: job.partNumber,
                        totalQuantity: 0,
                        oldestJobDate: job.createdAt,
                        jobs: []
                    };
                }
                aggregated[job.partNumber].totalQuantity += available;
                aggregated[job.partNumber].jobs.push({
                    jobId: job.jobId,
                    availableQuantity: available,
                    originalQuantity: job.quantity,
                    date: job.createdAt,
                    job: job
                });
            }
        });
        res.json(Object.values(aggregated).sort((a, b) => new Date(a.oldestJobDate) - new Date(b.oldestJobDate)));
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/jobs/deliver-partial
router.post('/deliver-partial', auth, async (req, res) => {
    try {
        const { partNumber, deliveryQuantity } = req.body;
        if (!partNumber || deliveryQuantity <= 0) return res.status(400).send('Invalid data');

        const jobs = await Job.find({ partNumber, status: { $in: ['Completed', 'Delivered'] } }).sort({ createdAt: 1 });
        let remainingToDeliver = deliveryQuantity;

        for (let job of jobs) {
            if (remainingToDeliver <= 0) break;

            const jobAvailable = job.quantity - (job.deliveredQuantity || 0);
            if (jobAvailable <= 0) continue;

            if (jobAvailable <= remainingToDeliver) {
                // Fully deliver the rest of this job
                remainingToDeliver -= jobAvailable;
                job.deliveredQuantity = job.quantity;
                job.status = 'Delivered';
                await job.save();
                
                await AuditLog.create({
                    userId: req.user.id,
                    action: 'Job Delivered (Full)',
                    details: { jobId: job.jobId, deliveredQuantity: jobAvailable }
                });
            } else {
                // Partially deliver this job (NO SPLITTING)
                job.deliveredQuantity = (job.deliveredQuantity || 0) + remainingToDeliver;
                await job.save();

                await AuditLog.create({
                    userId: req.user.id,
                    action: 'Job Delivered (Partial)',
                    details: { jobId: job.jobId, deliveredQuantity: remainingToDeliver }
                });

                remainingToDeliver = 0;
            }
        }
        res.json({ msg: 'Delivery successful' });
    } catch (err) {
        console.error(err);
        res.status(500).send(err.message || 'Server Error');
    }
});

// @route   PUT api/jobs/remove-aggregated
router.put('/remove-aggregated', auth, async (req, res) => {
    try {
        const { partNumbers } = req.body;
        if (!Array.isArray(partNumbers) || partNumbers.length === 0) return res.status(400).send('Invalid data');

        await Job.updateMany(
            { partNumber: { $in: partNumbers }, status: { $in: ['Completed', 'Delivered'] } },
            { $set: { status: 'Removed' } }
        );
        res.json({ msg: 'Jobs removed successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/jobs/:id/return-partial
router.post('/:id/return-partial', auth, async (req, res) => {
    try {
        const { returnQuantity } = req.body;
        if (!returnQuantity || returnQuantity <= 0) return res.status(400).send('Invalid return quantity');

        let job = await Job.findById(req.params.id).catch(() => null);
        if (!job) job = await Job.findOne({ jobId: req.params.id });
        if (!job) return res.status(404).send('Job not found');

        if (!['Completed', 'Delivered', 'Closed', 'At Supplier', 'Returned'].includes(job.status)) {
            // Check availableQty > 0 later
        }

        let availableQty = 0;
        if (job.status === 'Completed') {
            availableQty = job.quantity - (job.deliveredQuantity || 0);
        } else {
            availableQty = job.deliveredQuantity || 0;
        }

        if (availableQty <= 0) {
            return res.status(400).send('No parts available to return');
        }

        if (returnQuantity > availableQty) {
            return res.status(400).send('Return quantity cannot exceed available quantity');
        }

        const returnStr = `Returned (${job.destinationName}) ${returnQuantity} parts`;

        // Update quantities
        job.returnedQuantity = (job.returnedQuantity || 0) + returnQuantity;
        if (job.deliveredQuantity) {
            job.deliveredQuantity = Math.max(0, job.deliveredQuantity - returnQuantity);
        }

        // Update supplier chain
        if (!job.supplierChain) job.supplierChain = [];
        job.supplierChain.push(returnStr);

        // Update status history to track return
        if (!job.statusHistory) job.statusHistory = [];
        job.statusHistory.push({
            status: 'Returned',
            date: new Date(),
            location: 'VRS'
        });

        // We can keep the status as it was, or if it's fully returned we might change it?
        // Let's just set the status to 'Returned' for the latest action
        job.status = 'Returned';

        await job.save();

        await AuditLog.create({
            userId: req.user.id,
            action: 'Job Returned',
            details: { jobId: job.jobId, returnedQuantity: returnQuantity }
        });

        res.json({ msg: 'Return processed successfully' });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

function getDaysInMonth(year, month) {
    return new Date(year, month, 0).getDate();
}

// @route   GET api/jobs/stock-summary
router.get('/stock-summary', auth, async (req, res) => {
    try {
        const { month, date } = req.query;
        const jobs = await Job.find({ status: { $ne: 'Removed' } });
        
        let startDate, endDate;
        if (date) {
            const dt = new Date(date);
            const y = dt.getFullYear();
            const m = dt.getMonth() + 1;
            const d = dt.getDate();
            startDate = new Date(y, m - 1, d, 0, 0, 0).getTime();
            endDate = new Date(y, m - 1, d, 23, 59, 59, 999).getTime();
        } else if (month) {
            const parts = month.split('-');
            const y = parseInt(parts[0], 10);
            const m = parseInt(parts[1], 10);
            startDate = new Date(y, m - 1, 1).getTime();
            endDate = new Date(y, m, 0, 23, 59, 59, 999).getTime();
        } else {
            const today = new Date();
            const y = today.getFullYear();
            const m = today.getMonth() + 1;
            const d = today.getDate();
            startDate = new Date(y, m - 1, d, 0, 0, 0).getTime();
            endDate = new Date(y, m - 1, d, 23, 59, 59, 999).getTime();
        }

        const summaryMap = {};

        jobs.forEach(job => {
            const part = job.partNumber;
            if (!part) return;
            
            if (!summaryMap[part]) {
                summaryMap[part] = { partNumber: part, openingStock: 0, closingStock: 0, availability: 0, returnedStock: 0 };
            }

            // Determine if it's currently at VRS
            let isAtVRS = false;
            if (job.status !== 'Delivered') {
                if (job.supplierChain && job.supplierChain.length > 0) {
                    // Find the last index of 'VRS'
                    const vrsIndex = job.supplierChain.lastIndexOf('VRS');
                    if (vrsIndex !== -1) {
                        isAtVRS = true;
                        // Check if any node AFTER VRS is NOT a 'Delivered' node
                        for (let i = vrsIndex + 1; i < job.supplierChain.length; i++) {
                            if (!job.supplierChain[i].startsWith('Delivered') && !job.supplierChain[i].startsWith('Returned')) {
                                isAtVRS = false;
                                break;
                            }
                        }
                    }
                } else {
                    isAtVRS = (job.currentLocation === 'VRS');
                }
            } else if (job.status === 'Returned') {
                isAtVRS = true; // Returned parts are also technically at VRS
            }

            if (isAtVRS) {
                summaryMap[part].availability += (job.quantity - (job.deliveredQuantity || 0) - (job.returnedQuantity || 0));
            }

            // Check if created in this timeframe (Opening Stock)
            const createdTime = new Date(job.createdAt).getTime();
            if (createdTime >= startDate && createdTime <= endDate) {
                summaryMap[part].openingStock += job.quantity;
            }

            // Check if returned in this timeframe (Returned Stock)
            if (job.status === 'Returned') {
                let returnedTime = new Date(job.updatedAt).getTime();
                if (job.statusHistory) {
                    const retEntry = job.statusHistory.find(h => h.status === 'Returned');
                    if (retEntry && retEntry.date) {
                        returnedTime = new Date(retEntry.date).getTime();
                    }
                }
                
                if (returnedTime >= startDate && returnedTime <= endDate) {
                    summaryMap[part].returnedStock += (job.returnedQuantity || job.quantity);
                }
            }

            // Check if delivered in this timeframe (Closing Stock)
            if (job.status === 'Delivered' || (job.deliveredQuantity && job.deliveredQuantity > 0)) {
                let deliveryTime = new Date(job.updatedAt).getTime();
                if (job.status === 'Delivered' && job.statusHistory) {
                    const delEntry = job.statusHistory.find(h => h.status === 'Delivered');
                    if (delEntry && delEntry.date) {
                        deliveryTime = new Date(delEntry.date).getTime();
                    }
                }
                
                if (deliveryTime >= startDate && deliveryTime <= endDate) {
                    summaryMap[part].closingStock += (job.status === 'Delivered' ? job.quantity : job.deliveredQuantity);
                }
            }
        });

        // Filter out parts that have 0 opening, 0 closing, 0 returned and 0 availability for this timeframe
        const result = Object.values(summaryMap).filter(s => s.openingStock > 0 || s.closingStock > 0 || s.availability > 0 || s.returnedStock > 0);
        
        // Sort alphabetically by partNumber
        result.sort((a, b) => a.partNumber.localeCompare(b.partNumber));

        res.json(result);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
