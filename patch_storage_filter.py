import sys

with open('lib/screens/owner/storage_selection_dialog.dart', 'r') as f:
    content = f.read()

# Replace the Lapping compound condition
old_lapping = "if (company.name == 'Lapping Compound' && upperName.startsWith('LC')) {"
new_lapping = "if (company.name == 'Lapping Compound' && (upperName.contains('LC-') || upperName.contains(' LC '))) {"

if old_lapping in content:
    content = content.replace(old_lapping, new_lapping)

with open('lib/screens/owner/storage_selection_dialog.dart', 'w') as f:
    f.write(content)

