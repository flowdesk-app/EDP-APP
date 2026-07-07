const express = require('express');
const router = express.Router();
const Customer = require('../models/Customer');
const auth = require('../middleware/auth');

// @route   GET api/customers
// @desc    Get all customers
// @access  Private
router.get('/', auth, async (req, res) => {
    try {
        const customers = await Customer.find().sort({ customerName: 1 });
        res.json(customers);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/customers
// @desc    Add new customer
// @access  Private (Admin)
router.post('/', auth, async (req, res) => {
    try {
        const { customerName } = req.body;

        if (!customerName) {
            return res.status(400).json({ msg: 'Please include customerName' });
        }

        let customer = await Customer.findOne({ customerName: new RegExp(`^${customerName}$`, 'i') });
        if (customer) {
            return res.status(400).json({ msg: 'Customer already exists' });
        }

        customer = new Customer({
            customerName
        });

        await customer.save();
        res.json(customer);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/customers/:id
// @desc    Delete customer
// @access  Private (Admin)
router.delete('/:id', auth, async (req, res) => {
    try {
        const customer = await Customer.findById(req.params.id);

        if (!customer) {
            return res.status(404).json({ msg: 'Customer not found' });
        }

        await customer.remove();
        res.json({ msg: 'Customer removed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
