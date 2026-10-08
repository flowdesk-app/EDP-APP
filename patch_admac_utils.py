import sys

with open('lib/utils/company_utils.dart', 'r') as f:
    content = f.read()

admac_rule = """
  // Special handling for ADMAC
  if (upperName.contains('ADMAC') || upperName.contains('ADMACH')) {
    return ['ADMAC'];
  }
"""

if "Special handling for ADMAC" not in content:
    content = content.replace("// Special handling for Lapping Compound", admac_rule + "\n  // Special handling for Lapping Compound")

with open('lib/utils/company_utils.dart', 'w') as f:
    f.write(content)

