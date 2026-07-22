const express = require('express');
const router = express.Router();
const RawMaterial = require('../models/RawMaterial');
const auth = require('../middleware/auth');

// GET all raw materials
router.get('/', auth, async (req, res) => {
  try {
    const materials = await RawMaterial.find().sort({ createdAt: -1 });
    res.json(materials);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST a new raw material
router.post('/', auth, async (req, res) => {
  const { name, availableQuantity, availableUnit, minimumQuantity, minimumUnit } = req.body;

  if (!name || availableQuantity == null || !availableUnit || minimumQuantity == null || !minimumUnit) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const rawMaterial = new RawMaterial({
    name,
    availableQuantity,
    availableUnit,
    minimumQuantity,
    minimumUnit,
  });

  try {
    const newRawMaterial = await rawMaterial.save();
    res.status(201).json(newRawMaterial);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE a raw material
router.delete('/:id', auth, async (req, res) => {
  try {
    const rawMaterial = await RawMaterial.findById(req.params.id);
    if (!rawMaterial) {
      return res.status(404).json({ message: 'Raw material not found' });
    }
    await rawMaterial.deleteOne();
    res.json({ message: 'Raw material deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
