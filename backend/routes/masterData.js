const express = require('express');
const router = express.Router();
const MasterData = require('../models/MasterData');
const auth = require('../middleware/auth');

// @route   GET api/master-data
// @desc    Get all master data
router.get('/', auth, async (req, res) => {
    try {
        const masterData = await MasterData.find().sort({ value: 1 });
        res.json(masterData);
    } catch (err) {
        console.error('Error fetching master data:', err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/master-data/:id
// @desc    Delete a master data entry
router.delete('/:id', auth, async (req, res) => {
    try {
        const item = await MasterData.findById(req.params.id);
        if (!item) {
            return res.status(404).json({ msg: 'Master data not found' });
        }
        await item.deleteOne();
        res.json({ msg: 'Master data removed' });
    } catch (err) {
        console.error('Error deleting master data:', err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Master data not found' });
        }
        res.status(500).send('Server Error');
    }
});

module.exports = router;
