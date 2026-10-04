import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_entries = """  CompanyStorage(name: 'BREMSKERL Friction', prefixes: ['BREM']),
"""

content = content.replace("];", new_entries + "];")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
