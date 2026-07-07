const express = require('express');
const router = express.Router();
const Supplier = require('../models/Supplier');
const auth = require('../middleware/auth');

// @route   GET api/suppliers
router.get('/', auth, async (req, res) => {
    try {
        const suppliers = await Supplier.find();
        res.json(suppliers);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/suppliers
router.post('/', auth, async (req, res) => {
    try {
        const newSupplier = new Supplier(req.body);
        const supplier = await newSupplier.save();

        res.json(supplier);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/suppliers/:id
router.delete('/:id', auth, async (req, res) => {
    try {
        const supplier = await Supplier.findById(req.params.id);
        if (!supplier) {
            return res.status(404).json({ msg: 'Supplier not found' });
        }
        await Supplier.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Supplier removed' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
