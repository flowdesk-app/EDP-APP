const express = require('express');
const router = express.Router();
const Job = require('../models/Job');
const BinBoxReturn = require('../models/BinBoxReturn');

// GET /api/binbox/balances
router.get('/balances', async (req, res) => {
  try {
    const jobStats = await Job.aggregate([
      {
        $group: {
          _id: '$initialDestinationName',
          totalSentBins: { $sum: '$numberOfBins' },
          totalSentBoxes: { $sum: '$numberOfBoxes' }
        }
      }
    ]);

    const returnStats = await BinBoxReturn.aggregate([
      {
        $group: {
          _id: '$destinationName',
          totalReturnedBins: { $sum: '$returnedBins' },
          totalReturnedBoxes: { $sum: '$returnedBoxes' }
        }
      }
    ]);

    const returnMap = {};
    for (const r of returnStats) {
      returnMap[r._id] = r;
    }

    const balances = jobStats.map(j => {
      const dest = j._id;
      const returned = returnMap[dest] || { totalReturnedBins: 0, totalReturnedBoxes: 0 };
      return {
        destinationName: dest,
        totalSentBins: j.totalSentBins || 0,
        totalSentBoxes: j.totalSentBoxes || 0,
        totalReturnedBins: returned.totalReturnedBins || 0,
        totalReturnedBoxes: returned.totalReturnedBoxes || 0,
        netBins: (j.totalSentBins || 0) - (returned.totalReturnedBins || 0),
        netBoxes: (j.totalSentBoxes || 0) - (returned.totalReturnedBoxes || 0),
      };
    });

    res.json(balances);
  } catch (err) {
    console.error('BinBox Balances error:', err);
    res.status(500).json({ error: 'Server error fetching balances' });
  }
});

// POST /api/binbox/return
router.post('/return', async (req, res) => {
  try {
    const { destinationName, returnedBins, returnedBoxes } = req.body;
    if (!destinationName) return res.status(400).json({ error: 'destinationName is required' });

    const newReturn = new BinBoxReturn({
      destinationName,
      returnedBins: returnedBins || 0,
      returnedBoxes: returnedBoxes || 0
    });
    await newReturn.save();
    res.json({ success: true, message: 'Return logged successfully', data: newReturn });
  } catch (err) {
    console.error('BinBox Return error:', err);
    res.status(500).json({ error: 'Server error logging return' });
  }
});

// GET /api/binbox/history
router.get('/history', async (req, res) => {
  try {
    const { month } = req.query;
    let query = {};
    if (month) {
      const date = new Date(`${month} 1`);
      if (!isNaN(date)) {
        const start = new Date(date.getFullYear(), date.getMonth(), 1);
        const end = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);
        query.date = { $gte: start, $lte: end };
      }
    }
    const history = await BinBoxReturn.find(query).sort({ date: -1 });
    res.json(history);
  } catch (err) {
    console.error('BinBox History error:', err);
    res.status(500).json({ error: 'Server error fetching history' });
  }
});

// DELETE /api/binbox/return/:id
router.delete('/return/:id', async (req, res) => {
  try {
    const deleted = await BinBoxReturn.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Return not found' });
    res.json({ success: true, message: 'Return deleted' });
  } catch (err) {
    console.error('BinBox Delete error:', err);
    res.status(500).json({ error: 'Server error deleting return' });
  }
});

module.exports = router;
