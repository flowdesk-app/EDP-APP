const express = require('express');
const router = express.Router();
const Job = require('../models/Job');
const Lead = require('../models/Lead');
const auth = require('../middleware/auth');

const getDashboardStats = async (matchQuery) => {
    matchQuery.status = { $ne: 'Removed' };
    const jobs = await Job.find(matchQuery);
    
    // For leads, we just use the date part of the matchQuery
    const leadMatchQuery = { ...matchQuery };
    delete leadMatchQuery.status;
    
    const newStatusLeads = await Lead.countDocuments({
        ...leadMatchQuery,
        status: { $in: ['Quotation Pending', 'Negotiation Pending'] }
    });
    
    const declinedLeads = await Lead.countDocuments({
        ...leadMatchQuery,
        status: 'Declined'
    });

    let totalJobsCreated = jobs.length;
    let activeJobs = 0;
    let completedJobs = 0;
    let delayedJobs = 0;
    let totalPartsSent = 0;
    let totalPartsReceived = 0;
    let totalDeliveries = 0;
    let suppliersUsed = new Set();

    jobs.forEach(job => {
        if (job.status === 'Delivered' || job.status === 'Closed') {
            completedJobs++;
        } else {
            activeJobs++;
        }

        if (job.status === 'Delayed') {
            delayedJobs++;
        }

        if (job.destinationType === 'Supplier' && (job.status !== 'Created' && job.status !== 'Closed')) {
            // Count all parts that have been dispatched to supplier
            if (job.status === 'Dispatched' || job.status === 'At Supplier' || job.status === 'In Process') {
                totalPartsSent += job.quantity || 0;
            }
        }

        if (job.status === 'Returned' || (job.currentLocation === 'EDP' && job.status !== 'Created')) {
            totalPartsReceived += job.quantity || 0;
        }

        if (job.destinationType === 'Customer' && job.status === 'Delivered') {
            totalDeliveries++;
        }

        if (job.supplier && job.destinationType === 'Supplier') {
            suppliersUsed.add(job.supplier);
        }
    });

    return {
        totalJobsCreated,
        activeJobs,
        completedJobs,
        delayedJobs,
        totalPartsSent,
        totalPartsReceived,
        totalDeliveries,
        totalSuppliersUsed: suppliersUsed.size,
        newStatusCount: newStatusLeads,
        declinedCount: declinedLeads
    };
};

// @route   GET api/dashboard/month/:month
router.get('/month/:month', auth, async (req, res) => {
    try {
        const parts = req.params.month.split('-');
        if (parts.length !== 2) return res.status(400).send('Invalid month format. Use YYYY-MM');
        
        const y = parseInt(parts[0], 10);
        const m = parseInt(parts[1], 10);
        const start = new Date(y, m - 1, 1);
        const end = new Date(y, m, 0, 23, 59, 59, 999);
        
        const stats = await getDashboardStats({ createdAt: { $gte: start, $lte: end } });
        res.json(stats);
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/dashboard/date/:date
router.get('/date/:date', auth, async (req, res) => {
    try {
        const date = new Date(req.params.date);
        date.setHours(0,0,0,0);
        const end = new Date(req.params.date);
        end.setHours(23,59,59,999);
        
        const stats = await getDashboardStats({ createdAt: { $gte: date, $lte: end } });
        
        // Include the actual jobs created on this date for detailed view
        const jobs = await Job.find({ createdAt: { $gte: date, $lte: end }, status: { $ne: 'Removed' } }).sort({ createdAt: -1 });
        
        res.json({ stats, jobs });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
