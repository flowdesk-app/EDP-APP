const express = require('express');
const router = express.Router();
const CompanyStorage = require('../models/CompanyStorage');
const auth = require('../middleware/auth');
const mongoose = require('mongoose');

router.get('/', auth, async (req, res) => {
  try {
    const companies = await CompanyStorage.find({ isDeleted: false }).sort({ name: 1 });
    res.json(companies);
  } catch (err) {
    res.status(500).json({ error: 'Server error fetching companies' });
  }
});

router.post('/', auth, async (req, res) => {
  try {
    const {
      name,
      aliases,
      prefixes,
      billingAddress,
      shippingAddress,
      gstin,
      vendorCode,
      placeOfSupply,
      state,
      pincode
    } = req.body;
    if (!name) return res.status(400).json({ error: 'Name is required' });

    const trimmedName = name.trim();
    let company = await CompanyStorage.findOne({
      $or: [
        { name: trimmedName },
        { aliases: trimmedName }
      ]
    });

    if (company) {
      company.isDeleted = false;
      if (prefixes && Array.isArray(prefixes)) {
        company.prefixes = [...new Set([...company.prefixes, ...prefixes])];
      }
      if (aliases && Array.isArray(aliases)) {
        company.aliases = [...new Set([...company.aliases, ...aliases])];
      }
      if (billingAddress !== undefined) company.billingAddress = billingAddress;
      if (shippingAddress !== undefined) company.shippingAddress = shippingAddress;
      if (gstin !== undefined) company.gstin = gstin;
      if (vendorCode !== undefined) company.vendorCode = vendorCode;
      if (placeOfSupply !== undefined) company.placeOfSupply = placeOfSupply;
      if (state !== undefined) company.state = state;
      if (pincode !== undefined) company.pincode = pincode;
      company.updatedAt = new Date();
      await company.save();
      return res.json(company);
    }

    company = new CompanyStorage({
      name: trimmedName,
      aliases: aliases || [],
      prefixes: prefixes || [trimmedName.split(' ')[0].toUpperCase()],
      billingAddress: billingAddress || '',
      shippingAddress: shippingAddress || '',
      gstin: gstin || '',
      vendorCode: vendorCode || '',
      placeOfSupply: placeOfSupply || '',
      state: state || '',
      pincode: pincode || '',
      isDeleted: false,
      updatedAt: new Date()
    });
    await company.save();
    res.json(company);
  } catch (err) {
    console.error('Error creating company:', err);
    res.status(500).json({ error: 'Server error creating company' });
  }
});

// Update company details (Owner / Admin)
router.put('/:identifier', auth, async (req, res) => {
  try {
    const identifier = decodeURIComponent(req.params.identifier).trim();
    if (!identifier) {
      return res.status(400).json({ error: 'Company identifier is required' });
    }

    let query = { name: { $regex: new RegExp(`^${identifier.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } };
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      query = { $or: [{ _id: identifier }, { name: identifier }] };
    }

    const {
      name,
      aliases,
      prefixes,
      billingAddress,
      shippingAddress,
      gstin,
      vendorCode,
      placeOfSupply,
      state,
      pincode
    } = req.body;

    const updateData = { updatedAt: new Date() };
    if (name) updateData.name = name.trim();
    if (aliases !== undefined) updateData.aliases = aliases;
    if (prefixes !== undefined) updateData.prefixes = prefixes;
    if (billingAddress !== undefined) updateData.billingAddress = billingAddress;
    if (shippingAddress !== undefined) updateData.shippingAddress = shippingAddress;
    if (gstin !== undefined) updateData.gstin = gstin;
    if (vendorCode !== undefined) updateData.vendorCode = vendorCode;
    if (placeOfSupply !== undefined) updateData.placeOfSupply = placeOfSupply;
    if (state !== undefined) updateData.state = state;
    if (pincode !== undefined) updateData.pincode = pincode;

    const updated = await CompanyStorage.findOneAndUpdate(
      query,
      { $set: updateData },
      { new: true, upsert: false }
    );

    if (!updated) {
      return res.status(404).json({ error: 'Company not found' });
    }

    res.json(updated);
  } catch (err) {
    console.error('Error updating company:', err);
    res.status(500).json({ error: 'Server error updating company' });
  }
});

// Delete company from database by name or ID (Owner only)
router.delete('/:identifier', auth, async (req, res) => {
  try {
    if (req.user && req.user.role !== 'owner') {
      return res.status(403).json({ error: 'Access denied: Only owner can delete from database' });
    }

    const identifier = decodeURIComponent(req.params.identifier).trim();
    if (!identifier) {
      return res.status(400).json({ error: 'Company identifier is required' });
    }

    let query = { name: { $regex: new RegExp(`^${identifier.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') } };
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      query = { $or: [{ _id: identifier }, { name: identifier }] };
    }

    const updated = await CompanyStorage.findOneAndUpdate(
      query,
      { $set: { isDeleted: true, updatedAt: new Date() } },
      { upsert: true, new: true }
    );

    res.json({ message: 'Company removed from database successfully', company: updated });
  } catch (err) {
    console.error('Error deleting company:', err);
    res.status(500).json({ error: 'Server error deleting company' });
  }
});

module.exports = router;
