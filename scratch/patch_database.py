import sys

with open('lib/screens/owner/item_database_screen.dart', 'r') as f:
    content = f.read()

# Add import
import_stmt = "import '../../models/item_database_model.dart';\nimport '../../utils/company_utils.dart';\n"
content = content.replace("import '../../models/item_database_model.dart';", import_stmt)

# Add filter
target = "final items = await ApiService().getDatabaseItems(search);"
replacement = target + "\n      final unassignedItems = items.where((i) => getCompanyForPrefix(i.itemName) == null).toList();"

content = content.replace(target, replacement)
content = content.replace("items.sort((a, b)", "unassignedItems.sort((a, b)")
content = content.replace("_items = items;", "_items = unassignedItems;")

with open('lib/screens/owner/item_database_screen.dart', 'w') as f:
    f.write(content)
