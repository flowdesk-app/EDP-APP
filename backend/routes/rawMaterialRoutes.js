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
  const { name, availableQuantity, availableUnit, minimumQuantity, minimumUnit, gritSize } = req.body;

  if (!name || availableQuantity == null || !availableUnit) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  try {
    // Check if material with same name and gritSize exists
    const query = { name: name.trim() };
    if (gritSize) {
      query.gritSize = gritSize.trim();
    } else {
      query.gritSize = { $exists: false }; // or null depending on how it's saved. Using string check:
    }
    
    // Safer query for gritSize since it might be empty string or missing
    const existingMaterial = await RawMaterial.findOne({
      name: name.trim(),
      $or: [
        { gritSize: gritSize ? gritSize.trim() : { $exists: false } },
        { gritSize: gritSize ? gritSize.trim() : "" },
        { gritSize: gritSize ? gritSize.trim() : null }
      ]
    });

    if (existingMaterial) {
      // Aggregate quantity
      existingMaterial.availableQuantity += Number(availableQuantity);
      // We keep the existing minimumQuantity and unit.
      const updatedMaterial = await existingMaterial.save();
      return res.status(201).json(updatedMaterial);
    }

    // Create new
    const rawMaterial = new RawMaterial({
      name: name.trim(),
      availableQuantity: Number(availableQuantity),
      availableUnit,
      minimumQuantity: minimumQuantity != null ? Number(minimumQuantity) : 0,
      minimumUnit: minimumUnit || 'Kg',
      gritSize: gritSize ? gritSize.trim() : undefined,
    });

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
