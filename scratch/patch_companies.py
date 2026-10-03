import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "CompanyStorage(name: 'Rane Brake Lining Limited Trichy', prefixes: ['RBLT']),",
    "CompanyStorage(name: 'Rane Brake Lining Limited Trichy', prefixes: ['RBLT', 'RBL']),"
)
content = content.replace(
    "CompanyStorage(name: 'Rane Brakelining Limited Pondicherry', prefixes: ['RBLP']),",
    "CompanyStorage(name: 'Rane Brakelining Limited Pondicherry', prefixes: ['RBLP', 'RBL']),"
)
content = content.replace(
    "CompanyStorage(name: 'Rane Brake Lining Limited Ambattur', prefixes: ['RBLA']),",
    "CompanyStorage(name: 'Rane Brake Lining Limited Ambattur', prefixes: ['RBLA', 'RBL']),"
)
content = content.replace(
    "CompanyStorage(name: 'Rane Brakelining Limited Medak', prefixes: ['RBLM']),",
    "CompanyStorage(name: 'Rane Brakelining Limited Medak', prefixes: ['RBLM', 'RBL']),"
)

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
