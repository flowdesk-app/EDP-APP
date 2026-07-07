const express = require('express');
const router = express.Router();
const Part = require('../models/Part');
const auth = require('../middleware/auth');

// @route   GET api/parts
router.get('/', auth, async (req, res) => {
    try {
        const parts = await Part.find().sort({ partNumber: 1 });
        res.json(parts);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   POST api/parts
router.post('/', auth, async (req, res) => {
    try {
        const newPart = new Part(req.body);
        const part = await newPart.save();
        res.json(part);
    } catch (err) {
        if (err.code === 11000) return res.status(400).json({ msg: 'Part number already exists' });
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/parts/:id
router.put('/:id', auth, async (req, res) => {
    try {
        const part = await Part.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json(part);
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/parts/:id
router.delete('/:id', auth, async (req, res) => {
    try {
        await Part.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Part deleted' });
    } catch (err) {
        res.status(500).send('Server Error');
    }
});

module.exports = router;
