import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_companies = """  CompanyStorage(name: 'SWASTIC', prefixes: ['SWASTIC']),
  CompanyStorage(name: 'SRI Venus', prefixes: ['SRI-VENUS', 'SRIVENUS']),"""
content = content.replace("CompanyStorage(name: 'SRI Venus', prefixes: ['SRI-VENUS', 'SRIVENUS']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
