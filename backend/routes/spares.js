const express = require('express');
const router = express.Router();
const Spare = require('../models/Spare');
const Job = require('../models/Job');
const auth = require('../middleware/auth');

// @route   POST api/spares
// @desc    Create a new spare from an extracted job
router.post('/', auth, async (req, res) => {
    try {
        const { partNumber, quantity, description, gritSize, sourceJobId, jobType, personResponsible, expectedCompletionDate } = req.body;
        
        const newSpare = new Spare({
            partNumber,
            quantity: quantity || 1,
            description,
            gritSize,
            status: 'Blank',
            sourceJobId,
            jobType: jobType || 'Re-coating', // default to Re-coating if not provided
            personResponsible,
            expectedCompletionDate,
            createdBy: req.user.id
        });
        
        const savedSpare = await newSpare.save();
        
        // If it came from a job, mark it as sentToSpare
        if (sourceJobId) {
            await Job.findOneAndUpdate({ jobId: sourceJobId }, { sentToSpare: true });
        }
        
        res.json(savedSpare);
    } catch (err) {
        console.error("POST /spares Error:", err);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/spares/undo-send
// @desc    Undo sending a job to spare
router.post('/undo-send', auth, async (req, res) => {
    try {
        const { jobId } = req.body;
        if (!jobId) return res.status(400).json({ msg: 'Job ID is required' });
        
        // Find and delete the spare that was created from this job (only if it is still a Blank and hasn't been modified further)
        // Actually, let's just delete it if it exists.
        await Spare.findOneAndDelete({ sourceJobId: jobId });
        
        // Revert the job's sentToSpare flag
        await Job.findOneAndUpdate({ jobId }, { sentToSpare: false });
        
        res.json({ msg: 'Undo successful' });
    } catch (err) {
        console.error("POST /spares/undo-send Error:", err);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/spares
// @desc    Get all spares
router.get('/', auth, async (req, res) => {
    try {
        const spares = await Spare.find().sort({ createdAt: -1 });
        res.json(spares);
    } catch (err) {
        console.error("GET /spares Error:", err);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/spares/:id/status
// @desc    Update spare status (e.g. Blank to Finished)
router.put('/:id/status', auth, async (req, res) => {
    try {
        const spare = await Spare.findById(req.params.id);
        if (!spare) return res.status(404).json({ msg: 'Spare not found' });
        
        spare.status = req.body.status || 'Finished';
        await spare.save();
        
        res.json(spare);
    } catch (err) {
        console.error("PUT /spares/:id/status Error:", err);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/spares/:id/consume
// @desc    Consume a spare for a job
router.put('/:id/consume', auth, async (req, res) => {
    try {
        const spare = await Spare.findById(req.params.id);
        if (!spare) return res.status(404).json({ msg: 'Spare not found' });
        
        const consumeQuantity = req.body.quantity || 1;
        const targetJobId = req.body.targetJobId;
        
        if (spare.quantity > consumeQuantity) {
            spare.quantity -= consumeQuantity;
            await spare.save();
        } else {
            await Spare.findByIdAndDelete(req.params.id);
        }
        
        // Mark the target job with usedSpareId so they can proceed to Production
        if (targetJobId) {
            await Job.findOneAndUpdate({ jobId: targetJobId }, { usedSpareId: spare._id });
        }
        
        res.json({ msg: 'Spare consumed successfully' });
    } catch (err) {
        console.error("PUT /spares/:id/consume Error:", err);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/spares/:id
// @desc    Delete a spare entirely
router.delete('/:id', auth, async (req, res) => {
    try {
        await Spare.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Spare deleted' });
    } catch (err) {
        console.error("DELETE /spares/:id Error:", err);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
