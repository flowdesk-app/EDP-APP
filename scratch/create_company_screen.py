import sys

with open('lib/screens/owner/item_database_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("class ItemDatabaseScreen", "class CompanyItemsScreen")
content = content.replace("class _ItemDatabaseScreenState", "class _CompanyItemsScreenState")
content = content.replace("_ItemDatabaseScreenState", "_CompanyItemsScreenState")
content = content.replace("ItemDatabaseScreen", "CompanyItemsScreen")

# Add company field
content = content.replace(
    "class CompanyItemsScreen extends StatefulWidget {",
    "import '../../models/company_storage.dart';\n\nclass CompanyItemsScreen extends StatefulWidget {\n  final CompanyStorage company;"
)
content = content.replace(
    "const CompanyItemsScreen({super.key});",
    "const CompanyItemsScreen({super.key, required this.company});"
)

# Update fetch filtering
content = content.replace(
    "final unassignedItems = items.where((i) => getCompanyForPrefix(i.itemName) == null).toList();",
    "final unassignedItems = items.where((i) => getCompanyForPrefix(i.itemName) == widget.company.name).toList();"
)

# Replace Title text
content = content.replace("'Item Database'", "widget.company.name")
content = content.replace("'Browse and manage item master records.'", "'Browse items in this company storage.'")

# Add AppBar back button support (wrap Padding in Scaffold body, add appBar)
# The item_database_screen already returns a Scaffold. We just need to add appBar: AppBar()
content = content.replace(
    "return Scaffold(",
    "return Scaffold(\n      appBar: AppBar(title: Text(widget.company.name), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),"
)

with open('lib/screens/owner/company_items_screen.dart', 'w') as f:
    f.write(content)
