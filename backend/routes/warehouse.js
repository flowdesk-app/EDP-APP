const express = require('express');
const router = express.Router();
const Warehouse = require('../models/Warehouse');
const auth = require('../middleware/auth');

// @route   GET api/warehouse
router.get('/', auth, async (req, res) => {
    try {
        const items = await Warehouse.find().populate('supplierIds', 'supplierName');
        res.json(items);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
