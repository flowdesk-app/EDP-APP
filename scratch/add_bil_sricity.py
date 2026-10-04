import sys

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

new_entries = """  CompanyStorage(name: 'Brakes india limited SRICITY', prefixes: []),
"""

content = content.replace("];", new_entries + "];")

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)

with open('lib/utils/company_utils.dart', 'r') as f:
    utils_content = f.read()

bil_sricity_logic = """
  // Special handling for BIL SRICITY
  if (upperName.startsWith('BIL') && (upperName.contains('SRIC') || upperName.contains('SRI CITY') || upperName.contains('SRI-CITY') || upperName.contains('BILSRI'))) {
    return ['Brakes india limited SRICITY'];
  }
"""

utils_content = utils_content.replace(
    "// Special handling for RBL with explicit locations",
    bil_sricity_logic + "\n  // Special handling for RBL with explicit locations"
)

with open('lib/utils/company_utils.dart', 'w') as f:
    f.write(utils_content)
