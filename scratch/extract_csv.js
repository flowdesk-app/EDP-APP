const fs = require('fs');
const lines = fs.readFileSync('/Users/siddarth-mac/.gemini/antigravity/brain/ed7196ec-da69-4194-986b-8cae9dfbf6e5/.system_generated/logs/transcript_full.jsonl', 'utf8').split('\n');

for (let i = lines.length - 1; i >= 0; i--) {
  if (!lines[i]) continue;
  try {
    const log = JSON.parse(lines[i]);
    if (log.type === 'USER_INPUT') {
      let text = '';
      if (Array.isArray(log.content)) {
        for (const part of log.content) {
          if (part.type === 'text') text += part.text;
        }
      } else {
        text = log.content;
      }
      
      if (text.includes('Item ID,Item Name')) {
        const parts = text.split('Item ID,Item Name');
        const csvData = 'Item ID,Item Name' + parts[1];
        fs.writeFileSync('scratch/items.csv', csvData);
        console.log('Successfully extracted CSV.');
        break;
      }
    }
  } catch (e) {
    console.error(e);
  }
}
