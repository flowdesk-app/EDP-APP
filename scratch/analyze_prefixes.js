const fs = require('fs');

function parseCSV(text) {
  const lines = text.split('\n').filter(l => l.trim() !== '');
  const headers = lines[0].split(',').map(h => h.trim());
  const results = [];
  
  for (let i = 1; i < lines.length; i++) {
    let line = lines[i];
    while ((line.match(/"/g) || []).length % 2 !== 0 && i < lines.length - 1) {
      i++;
      line += '\n' + lines[i];
    }
    
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
      'Item Name': 'itemName',
    };

    for (let j = 0; j < headers.length; j++) {
      if (keyMap[headers[j]]) {
        obj[keyMap[headers[j]]] = values[j] ? values[j].replace(/^"|"$/g, '') : '';
      }
    }
    
    if (obj.itemName) {
      results.push(obj);
    }
  }
  return results;
}

const csvText = fs.readFileSync('/Users/siddarth-mac/.gemini/antigravity/brain/ed7196ec-da69-4194-986b-8cae9dfbf6e5/.user_uploaded/media_1790606594156.csv', 'utf8');
const items = parseCSV(csvText);

const prefixes = {};

items.forEach(item => {
    let name = item.itemName.trim();
    // Usually the prefix is before the first hyphen. 
    // e.g. RBL-Model1 -> RBL
    // Or if there's no hyphen, maybe before the first space.
    let prefix = name.split(/[- ]/)[0].toUpperCase();
    
    // Clean up prefix if it contains non-alphanumeric (just in case)
    prefix = prefix.replace(/[^A-Z0-9]/g, '');
    
    if (prefix) {
        prefixes[prefix] = (prefixes[prefix] || 0) + 1;
    }
});

// Sort by count descending
const sorted = Object.entries(prefixes).sort((a, b) => b[1] - a[1]);

console.log("Found " + sorted.length + " distinct prefixes.");
sorted.forEach(([prefix, count]) => {
    console.log(`${prefix}: ${count}`);
});
