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

// Delete single item from database by ID, itemId, or itemName
router.delete('/:identifier', auth, async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const identifier = decodeURIComponent(req.params.identifier).trim();
    if (!identifier) {
      return res.status(400).json({ error: 'Item identifier is required' });
    }

    let deleted = null;
    if (mongoose.Types.ObjectId.isValid(identifier)) {
      deleted = await ItemDatabase.findByIdAndDelete(identifier);
    }
    if (!deleted) {
      deleted = await ItemDatabase.findOneAndDelete({ itemId: identifier });
    }
    if (!deleted) {
      deleted = await ItemDatabase.findOneAndDelete({ itemName: identifier });
    }

    if (!deleted) {
      return res.status(404).json({ error: 'Item not found in database' });
    }

    res.json({ message: 'Item deleted from database successfully', item: deleted });
  } catch (err) {
    console.error('Error deleting item from database:', err);
    res.status(500).json({ error: 'Server error deleting item' });
  }
});

// Bulk delete items by ids or itemNames
router.post('/bulk-delete', auth, async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const { ids, names } = req.body;
    let deletedCount = 0;

    if (ids && Array.isArray(ids) && ids.length > 0) {
      const validObjIds = ids.filter(id => mongoose.Types.ObjectId.isValid(id));
      const result = await ItemDatabase.deleteMany({
        $or: [
          { _id: { $in: validObjIds } },
          { itemId: { $in: ids } }
        ]
      });
      deletedCount += result.deletedCount;
    }

    if (names && Array.isArray(names) && names.length > 0) {
      const result = await ItemDatabase.deleteMany({ itemName: { $in: names } });
      deletedCount += result.deletedCount;
    }

    res.json({ message: `Successfully deleted ${deletedCount} item(s)`, deletedCount });
  } catch (err) {
    console.error('Error bulk deleting items:', err);
    res.status(500).json({ error: 'Server error bulk deleting items' });
  }
});

module.exports = router;
