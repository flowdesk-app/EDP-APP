import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

# Add Accurate machines
new_entries = """  CompanyStorage(name: 'Accurate machines', prefixes: ['ACCU']),
"""
content = content.replace("];", new_entries + "];")

# Update KAYES Industries to include KAY
content = content.replace(
    "CompanyStorage(name: 'KAYES Industries', prefixes: ['KAYES']),",
    "CompanyStorage(name: 'KAYES Industries', prefixes: ['KAYES', 'KAY']),"
)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
