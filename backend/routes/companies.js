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
      if (prefixes) {
        existing.prefixes = [...new Set([...existing.prefixes, ...prefixes])];
        await existing.save();
      }
      return res.json(existing);
    }

    const company = new CompanyStorage({
      name,
      prefixes: prefixes || [name.split(' ')[0].toUpperCase()]
    });
    await company.save();
    res.json(company);
  } catch (err) {
    res.status(500).json({ error: 'Server error creating company' });
  }
});

module.exports = router;
