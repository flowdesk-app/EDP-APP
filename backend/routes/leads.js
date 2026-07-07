const express = require('express');
const router = express.Router();
const Lead = require('../models/Lead');
const auth = require('../middleware/auth');

// @route   GET api/leads/new-status
// @desc    Get all leads with 'Quotation Pending' or 'Negotiation Pending'
router.get('/new-status', auth, async (req, res) => {
  console.log('HIT GET /api/leads/new-status');
  try {
    const leads = await Lead.find({ status: { $in: ['Quotation Pending', 'Negotiation Pending'] } }).sort({ createdAt: -1 });
    res.json(leads);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET api/leads/declined
// @desc    Get all leads with 'Declined' status
router.get('/declined', auth, async (req, res) => {
  try {
    const leads = await Lead.find({ status: 'Declined' }).sort({ createdAt: -1 });
    res.json(leads);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   POST api/leads
// @desc    Create a new Lead
router.post('/', auth, async (req, res) => {
  console.log('HIT POST /api/leads', req.body);
  const { customerName, wheelSize, diamondPowderGritSize, assignedWorker, quotationGiven, negotiationDone, outcome, status } = req.body;
  try {
    const newLead = new Lead({
      customerName,
      wheelSize,
      diamondPowderGritSize,
      assignedWorker,
      quotationGiven: quotationGiven || false,
      negotiationDone: negotiationDone || false,
      outcome: outcome || 'Pending',
      status: status || 'Quotation Pending',
      createdBy: req.user.id
    });

    const lead = await newLead.save();
    res.json(lead);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   PUT api/leads/:id
// @desc    Update a Lead's status
router.put('/:id', auth, async (req, res) => {
  const { wheelSize, diamondPowderGritSize, assignedWorker, quotationGiven, negotiationDone, outcome, status } = req.body;

  try {
    let lead = await Lead.findById(req.params.id);
    if (!lead) {
      return res.status(404).json({ msg: 'Lead not found' });
    }

    if (wheelSize !== undefined) lead.wheelSize = wheelSize;
    if (diamondPowderGritSize !== undefined) lead.diamondPowderGritSize = diamondPowderGritSize;
    if (assignedWorker !== undefined) lead.assignedWorker = assignedWorker;
    if (quotationGiven !== undefined) lead.quotationGiven = quotationGiven;
    if (negotiationDone !== undefined) lead.negotiationDone = negotiationDone;
    if (outcome !== undefined) lead.outcome = outcome;
    if (status !== undefined) lead.status = status;

    await lead.save();
    res.json(lead);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;
