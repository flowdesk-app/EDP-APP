import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_companies = """  CompanyStorage(name: 'SEVOX', prefixes: ['SEVOX']),
  CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC', 'SWA', 'SWAS']),"""
content = content.replace("CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC', 'SWA', 'SWAS']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
