const express = require('express');
const router = express.Router();
const SpareSupplier = require('../models/SpareSupplier');
const auth = require('../middleware/auth');

// @route   GET api/spare-suppliers
router.get('/', auth, async (req, res) => {
    try {
        const suppliers = await SpareSupplier.find();
        res.json(suppliers);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/spare-suppliers
router.post('/', auth, async (req, res) => {
    try {
        const newSupplier = new SpareSupplier(req.body);
        const supplier = await newSupplier.save();

        res.json(supplier);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/spare-suppliers/:id
router.delete('/:id', auth, async (req, res) => {
    try {
        const supplier = await SpareSupplier.findById(req.params.id);
        if (!supplier) {
            return res.status(404).json({ msg: 'Spare Supplier not found' });
        }
        await SpareSupplier.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Spare Supplier removed' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
