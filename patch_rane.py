import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_companies = """  CompanyStorage(name: 'RANE PONNERI', prefixes: ['RANE MADRAS LTD PONNERI', 'RANE MADRAS LTD PONEERI']),
  CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC']),"""
content = content.replace("CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
