const express = require('express');
const router = express.Router();
const Logistics = require('../models/Logistics');
const auth = require('../middleware/auth');

// @route   GET api/logistics
router.get('/', auth, async (req, res) => {
    try {
        const logistics = await Logistics.find().sort({ name: 1 });
        res.json(logistics);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/logistics
router.post('/', auth, async (req, res) => {
    try {
        const newLogistics = new Logistics({ name: req.body.name });
        const logistics = await newLogistics.save();
        res.json(logistics);
    } catch (err) {
        if (err.code === 11000) return res.status(400).json({ msg: 'Logistics name already exists' });
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/logistics/:id
router.delete('/:id', auth, async (req, res) => {
    try {
        await Logistics.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Logistics deleted' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
