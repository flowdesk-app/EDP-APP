import sys
import re

with open('backend/routes/itemDatabase.js', 'r') as f:
    content = f.read()

new_route = """// Create single item
router.post('/', auth, async (req, res) => {
  try {
    const { itemName, description, sku, category } = req.body;
    
    // Auto-generate a dummy ID for now or leave it empty if schema allows
    const timestamp = Date.now().toString();
    const newItem = new ItemDatabase({
      itemName: itemName || 'Unknown',
      description: description || '',
      itemId: `GEN-${timestamp}`,
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

module.exports = router;"""

if "// Create single item" not in content:
    content = content.replace("module.exports = router;", new_route)

with open('backend/routes/itemDatabase.js', 'w') as f:
    f.write(content)
