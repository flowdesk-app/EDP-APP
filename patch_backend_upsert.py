import sys
import re

with open('backend/routes/itemDatabase.js', 'r') as f:
    content = f.read()

new_route = """// Create or update single item by itemName
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
"""

content = re.sub(r'// Create single item.*?module\.exports = router;', new_route + '\nmodule.exports = router;', content, flags=re.DOTALL)

with open('backend/routes/itemDatabase.js', 'w') as f:
    f.write(content)
