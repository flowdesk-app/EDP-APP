const fs = require('fs');
const mongoose = require('mongoose');
require('dotenv').config({ path: '../backend/.env' });
const ItemDatabase = require('../backend/models/ItemDatabase');

// Simple CSV parser
function parseCSV(text) {
  const lines = text.split('\n').filter(l => l.trim() !== '');
  const headers = lines[0].split(',').map(h => h.trim());
  const results = [];
  
  for (let i = 1; i < lines.length; i++) {
    let line = lines[i];
    // Handle multiline quotes very naively, if the line has an odd number of quotes, append next line
    while ((line.match(/"/g) || []).length % 2 !== 0 && i < lines.length - 1) {
      i++;
      line += '\n' + lines[i];
    }
    
    // Split by comma but ignore commas inside quotes
    const values = [];
    let current = '';
    let inQuotes = false;
    for (let char of line) {
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        values.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    values.push(current.trim());
    
    const obj = {};
    const keyMap = {
      'Item ID': 'itemId',
      'Item Name': 'itemName',
      'SKU': 'sku',
      'HSN/SAC': 'hsnSac',
      'Is Tax Calculated on Label Price': 'isTaxCalculatedOnLabelPrice',
      'Description': 'description',
      'Rate': 'rate',
      'Account': 'account',
      'Account Code': 'accountCode',
      'Taxable': 'taxable',
      'Exemption Reason': 'exemptionReason',
      'Taxability Type': 'taxabilityType',
      'Product Type': 'productType',
      'Product Name': 'productName',
      'Intra State Tax Name': 'intraStateTaxName',
      'Intra State Tax Rate': 'intraStateTaxRate',
      'Intra State Tax Type': 'intraStateTaxType',
      'Inter State Tax Name': 'interStateTaxName',
      'Inter State Tax Rate': 'interStateTaxRate',
      'Inter State Tax Type': 'interStateTaxType',
      'Source': 'source',
      'Reference ID': 'referenceId',
      'Last Sync Time': 'lastSyncTime',
      'Status': 'status',
      'Usage unit': 'usageUnit',
      'Unit Name': 'unitName',
      'Purchase Rate': 'purchaseRate',
      'Purchase Account': 'purchaseAccount',
      'Purchase Account Code': 'purchaseAccountCode',
      'Purchase Description': 'purchaseDescription',
      'Inventory Account': 'inventoryAccount',
      'Inventory Account Code': 'inventoryAccountCode',
      'Inventory Valuation Method': 'inventoryValuationMethod',
      'Reorder Point': 'reorderPoint',
      'Vendor': 'vendor',
      'Opening Stock': 'openingStock',
      'Opening Stock Value': 'openingStockValue',
      'Stock On Hand': 'stockOnHand',
      'Item Type': 'itemType',
      'Sellable': 'sellable',
      'Purchasable': 'purchasable',
      'Track Inventory': 'trackInventory'
    };

    for (let j = 0; j < headers.length; j++) {
      if (keyMap[headers[j]]) {
        obj[keyMap[headers[j]]] = values[j] ? values[j].replace(/^"|"$/g, '') : '';
      }
    }
    
    if (obj.itemId && obj.itemName) {
      results.push(obj);
    }
  }
  return results;
}

const csvText = fs.readFileSync('/Users/siddarth-mac/.gemini/antigravity/brain/ed7196ec-da69-4194-986b-8cae9dfbf6e5/.user_uploaded/media_1790606594156.csv', 'utf8');
const items = parseCSV(csvText);

console.log(`Parsed ${items.length} items from CSV.`);

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    let imported = 0;
    for (const item of items) {
      try {
        await ItemDatabase.findOneAndUpdate(
          { itemId: item.itemId },
          item,
          { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        imported++;
      } catch (err) {
        console.error(`Failed to import ${item.itemId}:`, err);
      }
    }
    console.log(`Successfully imported ${imported} items.`);
    mongoose.connection.close();
  })
  .catch(err => {
    console.error('Connection error', err);
  });
