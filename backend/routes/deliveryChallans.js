const express = require('express');
const router = express.Router();
const DeliveryChallan = require('../models/DeliveryChallan');
const Job = require('../models/Job');
const auth = require('../middleware/auth');

async function generateNextDcNumber() {
  const now = new Date();
  const currentMonth = now.getMonth(); // 0 = Jan, 3 = April
  const currentYear = now.getFullYear();

  let startYear = currentYear;
  let endYear = currentYear + 1;
  if (currentMonth < 3) {
    startYear = currentYear - 1;
    endYear = currentYear;
  }

  const fyCode = `${String(startYear).slice(-2)}${String(endYear).slice(-2)}`;
  const prefix = `DC${fyCode}-`;

  const challans = await DeliveryChallan.find({
    dcNumber: new RegExp(`^${prefix}`),
    isDeleted: { $ne: true },
  }).select('dcNumber').lean();

  let maxNum = 231; // User's latest sample is DC2627-00231
  for (const c of challans) {
    const parts = c.dcNumber.split('-');
    if (parts.length > 1) {
      const num = parseInt(parts[1], 10);
      if (!isNaN(num) && num > maxNum) {
        maxNum = num;
      }
    }
  }

  const nextNum = maxNum + 1;
  return `${prefix}${String(nextNum).padStart(5, '0')}`;
}

// @route   GET api/delivery-challans/next-number
// @desc    Get next sequential DC number
router.get('/next-number', auth, async (req, res) => {
  try {
    const nextDcNumber = await generateNextDcNumber();
    res.json({ nextDcNumber });
  } catch (err) {
    console.error('Error getting next DC number:', err);
    res.status(500).json({ msg: 'Server error generating DC number' });
  }
});

// @route   GET api/delivery-challans
// @desc    Get all delivery challans
router.get('/', auth, async (req, res) => {
  try {
    const filter = { isDeleted: { $ne: true } };

    if (req.query.supplier) {
      filter.supplierName = { $regex: req.query.supplier.trim(), $options: 'i' };
    }

    if (req.query.jobId) {
      filter.$or = [
        { jobIds: req.query.jobId },
        { 'items.jobId': req.query.jobId },
      ];
    }

    if (req.query.search) {
      const q = req.query.search.trim();
      filter.$or = [
        { dcNumber: { $regex: q, $options: 'i' } },
        { supplierName: { $regex: q, $options: 'i' } },
        { reference: { $regex: q, $options: 'i' } },
        { 'items.description': { $regex: q, $options: 'i' } },
        { jobIds: { $regex: q, $options: 'i' } },
      ];
    }

    const challans = await DeliveryChallan.find(filter).sort({ createdAt: -1 });
    res.json(challans);
  } catch (err) {
    console.error('Error fetching delivery challans:', err);
    res.status(500).json({ msg: 'Server error fetching delivery challans' });
  }
});

// @route   GET api/delivery-challans/job/:jobId
// @desc    Get delivery challan(s) linked to a specific job
router.get('/job/:jobId', auth, async (req, res) => {
  try {
    const jobId = req.params.jobId;
    const challans = await DeliveryChallan.find({
      isDeleted: { $ne: true },
      $or: [
        { jobIds: jobId },
        { 'items.jobId': jobId },
      ],
    }).sort({ createdAt: -1 });

    res.json(challans);
  } catch (err) {
    console.error('Error fetching delivery challans for job:', err);
    res.status(500).json({ msg: 'Server error' });
  }
});

// @route   GET api/delivery-challans/:id
// @desc    Get single delivery challan by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const challan = await DeliveryChallan.findById(req.params.id);
    if (!challan || challan.isDeleted) {
      return res.status(404).json({ msg: 'Delivery challan not found' });
    }
    res.json(challan);
  } catch (err) {
    console.error('Error fetching delivery challan:', err);
    res.status(500).json({ msg: 'Server error' });
  }
});

// @route   POST api/delivery-challans
// @desc    Create new delivery challan
router.post('/', auth, async (req, res) => {
  try {
    const payload = { ...req.body };

    if (req.user && req.user.id) {
      payload.createdBy = req.user.id;
    }

    if (!payload.dcNumber || payload.dcNumber.trim() === '') {
      payload.dcNumber = await generateNextDcNumber();
    }

    // Collect jobIds from items if not provided
    if (!payload.jobIds || payload.jobIds.length === 0) {
      payload.jobIds = [];
      if (Array.isArray(payload.items)) {
        payload.items.forEach(it => {
          if (it.jobId && !payload.jobIds.includes(it.jobId)) {
            payload.jobIds.push(it.jobId);
          }
        });
      }
    }

    // Default supplier details if SKMT
    if (!payload.supplierAddress && payload.supplierName && payload.supplierName.toUpperCase().includes('SKMT')) {
      payload.supplierAddress = '63, Sarangapani Street, Sivabootham\nVanagaram, Chennai - 600095,\n-';
      payload.supplierGstin = payload.supplierGstin || 'GSTIN 33AFFPV1640H1ZK';
    }

    const challan = new DeliveryChallan(payload);
    await challan.save();

    // Link DC number to jobs
    if (payload.jobIds && payload.jobIds.length > 0) {
      try {
        await Job.updateMany(
          { jobId: { $in: payload.jobIds } },
          {
            $set: {
              deliveryChalanNumber: challan.dcNumber,
              deliveryChalanDate: challan.date,
            },
          }
        );
      } catch (jobErr) {
        console.error('Error updating job DC info:', jobErr);
      }
    }

    res.status(201).json(challan);
  } catch (err) {
    console.error('Error saving delivery challan:', err);
    res.status(500).json({ msg: 'Server error saving delivery challan', error: err.message });
  }
});

// @route   PUT api/delivery-challans/:id
// @desc    Update delivery challan
router.put('/:id', auth, async (req, res) => {
  try {
    const challan = await DeliveryChallan.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true }
    );
    if (!challan) {
      return res.status(404).json({ msg: 'Delivery challan not found' });
    }

    // Update job records if DC number or date changed
    if (challan.jobIds && challan.jobIds.length > 0) {
      try {
        await Job.updateMany(
          { jobId: { $in: challan.jobIds } },
          {
            $set: {
              deliveryChalanNumber: challan.dcNumber,
              deliveryChalanDate: challan.date,
            },
          }
        );
      } catch (jobErr) {
        console.error('Error updating job DC info:', jobErr);
      }
    }

    res.json(challan);
  } catch (err) {
    console.error('Error updating delivery challan:', err);
    res.status(500).json({ msg: 'Server error updating delivery challan' });
  }
});

// @route   DELETE api/delivery-challans/:id
// @desc    Delete delivery challan (soft delete)
router.delete('/:id', auth, async (req, res) => {
  try {
    const challan = await DeliveryChallan.findByIdAndUpdate(
      req.params.id,
      { $set: { isDeleted: true } },
      { new: true }
    );
    if (!challan) {
      return res.status(404).json({ msg: 'Delivery challan not found' });
    }
    res.json({ msg: 'Delivery challan deleted successfully', id: req.params.id });
  } catch (err) {
    console.error('Error deleting delivery challan:', err);
    res.status(500).json({ msg: 'Server error deleting delivery challan' });
  }
});

module.exports = router;
