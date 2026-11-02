const express = require('express');
const router = express.Router();
const CompanyStorage = require('../models/CompanyStorage');
const auth = require('../middleware/auth');

router.get('/', auth, async (req, res) => {
  try {
    const companies = await CompanyStorage.find();
    res.json(companies);
  } catch (err) {
    res.status(500).json({ error: 'Server error fetching companies' });
  }
});

router.post('/', auth, async (req, res) => {
  try {
    const { name, prefixes } = req.body;
    if (!name) return res.status(400).json({ error: 'Name is required' });

    const existing = await CompanyStorage.findOne({ name });
    if (existing) {
      existing.isDeleted = false;
      if (prefixes) {
        existing.prefixes = [...new Set([...existing.prefixes, ...prefixes])];
      }
      await existing.save();
      return res.json(existing);
    }

    const company = new CompanyStorage({
      name,
      prefixes: prefixes || [name.split(' ')[0].toUpperCase()],
      isDeleted: false
    });
    await company.save();
    res.json(company);
  } catch (err) {
    res.status(500).json({ error: 'Server error creating company' });
  }
});

// Delete company from database by name or ID
router.delete('/:identifier', auth, async (req, res) => {
  try {
    const identifier = decodeURIComponent(req.params.identifier).trim();
    if (!identifier) {
      return res.status(400).json({ error: 'Company identifier is required' });
    }

    // Try finding by name or by ObjectId
    const mongoose = require('mongoose');
    let query = { name: { $regex: new RegExp(`^${identifier.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } };
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      query = { $or: [{ _id: identifier }, { name: identifier }] };
    }

    const updated = await CompanyStorage.findOneAndUpdate(
      query,
      { $set: { isDeleted: true } },
      { upsert: true, new: true }
    );

    res.json({ message: 'Company removed from database successfully', company: updated });
  } catch (err) {
    console.error('Error deleting company:', err);
    res.status(500).json({ error: 'Server error deleting company' });
  }
});

module.exports = router;
