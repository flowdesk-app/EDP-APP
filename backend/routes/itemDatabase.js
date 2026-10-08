const express = require('express');
const router = express.Router();
const ItemDatabase = require('../models/ItemDatabase');
const auth = require('../middleware/auth');

// Get all items or search
router.get('/', auth, async (req, res) => {
  try {
    const { search } = req.query;
    let query = {};

    if (search) {
      const searchRegex = new RegExp(search, 'i');
      query = {
        $or: [
          { itemName: searchRegex },
          { description: searchRegex },
          { itemId: searchRegex },
          { productName: searchRegex }
        ]
      };
    }

    const items = await ItemDatabase.find(query).limit(1000);
    res.json(items);
  } catch (err) {
    res.status(500).json({ error: 'Server error fetching items' });
  }
});

// Import bulk CSV data
router.post('/import', auth, async (req, res) => {
  try {
    const items = req.body.items;
    if (!items || !Array.isArray(items)) {
      return res.status(400).json({ error: 'Items array is required' });
    }

    let importedCount = 0;
    for (const item of items) {
      // Use upsert to avoid duplicate key errors on itemId
      if (item.itemId) {
        await ItemDatabase.findOneAndUpdate(
          { itemId: item.itemId },
          item,
          { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        importedCount++;
      }
    }

    res.json({ message: `Successfully imported ${importedCount} items` });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error importing items' });
  }
});

// Create or update single item by itemName
router.post('/', auth, async (req, res) => {
  try {
    const { itemName, description, sku, category } = req.body;
    if (!itemName) {
      return res.status(400).json({ error: 'itemName is required' });
    }
    
    // Auto-generate a dummy ID for now or leave it empty if schema allows
    const timestamp = Date.now().toString();
    const itemId = `GEN-${timestamp}`;
    
    const existing = await ItemDatabase.findOne({ itemName });
    if (existing) {
      existing.description = description || existing.description;
      await existing.save();
      return res.json(existing);
    }
    
    const newItem = new ItemDatabase({
      itemName: itemName,
      description: description || '',
      itemId: itemId,
      sku: sku || '',
      category: category || 'Sales'
    });
    
    await newItem.save();
    res.json(newItem);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error creating item' });
  }
});

module.exports = router;
