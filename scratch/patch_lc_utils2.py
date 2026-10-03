import sys

with open('lib/utils/company_utils.dart', 'r') as f:
    content = f.read()

target = "if (upperName.startsWith('LC-') || upperName.contains('-LC-') || upperName.contains(' LC ') || upperName.contains(' LC-')) {"
replacement = "if (upperName.startsWith('LC-') || upperName.contains('-LC-') || upperName.contains(' LC ') || upperName.contains(' LC-') || upperName.contains('-LC ')) {"

content = content.replace(target, replacement)

with open('lib/utils/company_utils.dart', 'w') as f:
    f.write(content)
