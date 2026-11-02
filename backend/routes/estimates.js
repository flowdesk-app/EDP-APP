const express = require('express');
const router = express.Router();
const Estimate = require('../models/Estimate');
const Job = require('../models/Job');
const auth = require('../middleware/auth');

// @route   GET api/estimates
// @desc    Get all estimates (optional ?jobId=... or ?search=...)
router.get('/', auth, async (req, res) => {
  try {
    const filter = {};
    if (req.query.jobId) {
      filter.jobId = req.query.jobId;
    }
    if (req.query.search) {
      const q = req.query.search.trim();
      filter.$or = [
        { calculationNo: { $regex: q, $options: 'i' } },
        { customerName: { $regex: q, $options: 'i' } },
        { itemDescription: { $regex: q, $options: 'i' } },
        { jobId: { $regex: q, $options: 'i' } },
        { drawingNo: { $regex: q, $options: 'i' } },
      ];
    }
    const estimates = await Estimate.find(filter).sort({ createdAt: -1 });
    res.json(estimates);
  } catch (err) {
    console.error('Error fetching estimates:', err);
    res.status(500).json({ msg: 'Server error fetching estimates' });
  }
});

// @route   GET api/estimates/job/:jobId
// @desc    Get estimate for a specific jobId
router.get('/job/:jobId', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findOne({ jobId: req.params.jobId }).sort({ createdAt: -1 });
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found for this job' });
    }
    res.json(estimate);
  } catch (err) {
    console.error('Error fetching estimate by jobId:', err);
    res.status(500).json({ msg: 'Server error' });
  }
});

// @route   GET api/estimates/:id
// @desc    Get single estimate by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findById(req.params.id);
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found' });
    }
    res.json(estimate);
  } catch (err) {
    console.error('Error fetching estimate:', err);
    res.status(500).json({ msg: 'Server error' });
  }
});

// @route   POST api/estimates
// @desc    Create new estimate
router.post('/', auth, async (req, res) => {
  try {
    const payload = { ...req.body };
    if (req.user && req.user.id) {
      payload.createdBy = req.user.id;
    }

    // Auto-generate calculation number if not provided or empty
    if (!payload.calculationNo || payload.calculationNo.trim() === '') {
      const count = await Estimate.countDocuments();
      payload.calculationNo = String(count + 1).padStart(8, '0');
    }

    const estimate = new Estimate(payload);
    await estimate.save();

    // If linked to a job, update the job record
    if (payload.jobId) {
      try {
        await Job.findOneAndUpdate(
          { jobId: payload.jobId },
          { $set: { remarks: (payload.qtnPrice ? `Estimated QTN Price: ₹${payload.qtnPrice}` : undefined) } }
        );
      } catch (jobErr) {
        console.error('Could not update job note:', jobErr);
      }
    }

    res.status(201).json(estimate);
  } catch (err) {
    console.error('Error saving estimate:', err);
    res.status(500).json({ msg: 'Server error saving estimate', error: err.message });
  }
});

// @route   PUT api/estimates/:id
// @desc    Update existing estimate
router.put('/:id', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true }
    );
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found' });
    }

    // If linked to a job, update the job record
    if (estimate.jobId && req.body.qtnPrice) {
      try {
        await Job.findOneAndUpdate(
          { jobId: estimate.jobId },
          { $set: { remarks: `Estimated QTN Price: ₹${req.body.qtnPrice}` } }
        );
      } catch (jobErr) {
        console.error('Could not update job note:', jobErr);
      }
    }

    res.json(estimate);
  } catch (err) {
    console.error('Error updating estimate:', err);
    res.status(500).json({ msg: 'Server error updating estimate' });
  }
});

// @route   DELETE api/estimates/:id
// @desc    Delete an estimate
router.delete('/:id', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findByIdAndDelete(req.params.id);
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found' });
    }
    res.json({ msg: 'Estimate deleted successfully', id: req.params.id });
  } catch (err) {
    console.error('Error deleting estimate:', err);
    res.status(500).json({ msg: 'Server error deleting estimate' });
  }
});

module.exports = router;
