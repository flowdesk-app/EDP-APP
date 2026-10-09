import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

content = content.replace("CompanyStorage(name: 'SRI Venus', prefixes: ['SRI-VENUS', 'SRIVENUS']),", "CompanyStorage(name: 'SRI Venus', prefixes: ['SRI-VENUS', 'SRIVENUS', 'SREE-VINUS', 'SREEVINUS']),")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
