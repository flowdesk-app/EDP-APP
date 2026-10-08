import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

if "CompanyStorage(name: 'ADMAC'" not in content:
    content = content.replace("CompanyStorage(name: 'Bharat Rubber', prefixes: ['BHA']),", "CompanyStorage(name: 'Bharat Rubber', prefixes: ['BHA']),\n  CompanyStorage(name: 'ADMAC', prefixes: ['ADMAC', 'ADMACH']),")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)

