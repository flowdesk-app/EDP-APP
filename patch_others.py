import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_companies = """  CompanyStorage(name: 'Others', prefixes: ['EDP-16CM', 'EDP-16MM']),
  CompanyStorage(name: 'SEVOX', prefixes: ['SEVOX']),"""
content = content.replace("CompanyStorage(name: 'SEVOX', prefixes: ['SEVOX']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
