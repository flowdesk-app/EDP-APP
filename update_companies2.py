import sys
import re

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

# Add new companies
new_companies = """  CompanyStorage(name: 'SIGI', prefixes: ['SIGI']),
  CompanyStorage(name: 'Ashok LeyLand', prefixes: ['ASHOK']),
  CompanyStorage(name: 'AKM', prefixes: ['AKM', 'EDP-AKM']),
"""
content = content.replace("CompanyStorage(name: 'AKM', prefixes: ['AKM', 'EDP-AKM']),", new_companies)

# Modify Rane Brake Lining Limited Trichy
content = content.replace("CompanyStorage(name: 'Rane Brake Lining Limited Trichy', prefixes: ['RBLT', 'RBL']),", "CompanyStorage(name: 'Rane Brake Lining Limited Trichy', prefixes: ['RBLT', 'RBL', 'YCA']),")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
