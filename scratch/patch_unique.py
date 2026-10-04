import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

# Replace ['UNQ'] with ['UNQ', 'UNI', 'UNIQ'] for Unique Industries
content = content.replace("CompanyStorage(name: 'Unique Industries', prefixes: ['UNQ']),",
                          "CompanyStorage(name: 'Unique Industries', prefixes: ['UNQ', 'UNI', 'UNIQ']),")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
