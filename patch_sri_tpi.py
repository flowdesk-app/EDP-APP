import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

# Modify TPi Composites
content = content.replace("CompanyStorage(name: 'TPi Composites', prefixes: ['TPI']),", "CompanyStorage(name: 'TPi Composites', prefixes: ['TPI', 'EDP-TPI']),")

# Add SRISAI
new_companies = """  CompanyStorage(name: 'SRISAI', prefixes: ['SRISAI', 'SRI-SAI']),
  CompanyStorage(name: 'SIGI', prefixes: ['SIGI']),"""
content = content.replace("CompanyStorage(name: 'SIGI', prefixes: ['SIGI']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
