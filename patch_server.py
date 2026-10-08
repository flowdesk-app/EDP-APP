import sys
import re

with open('backend/server.js', 'r') as f:
    content = f.read()

if "require('./routes/companies')" not in content:
    content = content.replace("app.use('/api/item-database', require('./routes/itemDatabase'));", "app.use('/api/item-database', require('./routes/itemDatabase'));\napp.use('/api/companies', require('./routes/companies'));")

with open('backend/server.js', 'w') as f:
    f.write(content)
