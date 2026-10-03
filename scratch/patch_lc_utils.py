import sys

with open('lib/utils/company_utils.dart', 'r') as f:
    content = f.read()

lc_logic = """
  // Special handling for Lapping Compound (LC)
  if (upperName.startsWith('LC-') || upperName.contains('-LC-') || upperName.contains(' LC ') || upperName.contains(' LC-')) {
    return ['Lapping Compound'];
  }
"""

content = content.replace(
    "// Special handling for RBL with explicit locations",
    lc_logic + "\n  // Special handling for RBL with explicit locations"
)

with open('lib/utils/company_utils.dart', 'w') as f:
    f.write(content)
