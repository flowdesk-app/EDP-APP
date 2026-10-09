import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

content = content.replace("CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC']),", "CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC', 'SWA', 'SWAS']),")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
