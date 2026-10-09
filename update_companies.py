import sys
import re

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

# Excel Diamond Tools
content = content.replace("CompanyStorage(name: 'Excel Diamond Tools', prefixes: ['EDT']),", "CompanyStorage(name: 'Excel Diamond Tools', prefixes: ['EDT', 'EXL', 'EXL-CBNSTRIP']),")

# Add new companies to kCompanyStorages list
new_companies = """  CompanyStorage(name: 'ADMAC', prefixes: ['ADMAC', 'ADMACH']),
  CompanyStorage(name: 'CAMFAST', prefixes: ['CAM']),
  CompanyStorage(name: 'VINKO', prefixes: ['VINK']),
  CompanyStorage(name: 'Give&take enterprises', prefixes: ['GIVETAKE', 'GIVE', 'GIVE&TAKE']),
  CompanyStorage(name: 'AKM', prefixes: ['AKM', 'EDP-AKM']),
"""

content = content.replace("CompanyStorage(name: 'ADMAC', prefixes: ['ADMAC', 'ADMACH']),", new_companies)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
