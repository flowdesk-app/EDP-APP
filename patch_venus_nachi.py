import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_companies = """  CompanyStorage(name: 'SRI Venus', prefixes: ['SRI-VENUS', 'SRIVENUS']),
  CompanyStorage(name: 'Nachi', prefixes: ['NACHI']),
  CompanyStorage(name: 'SIGI', prefixes: ['SIGI']),"""
content = content.replace("CompanyStorage(name: 'SIGI', prefixes: ['SIGI']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
