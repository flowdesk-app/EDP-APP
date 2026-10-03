import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_entries = """  CompanyStorage(name: 'CPIN', prefixes: ['CPIN']),
  CompanyStorage(name: 'DPIN', prefixes: ['DPIN']),
"""

content = content.replace("];", new_entries + "];")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
