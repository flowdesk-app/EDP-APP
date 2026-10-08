import sys

# Fix imports in create_job_screen.dart
with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

if "import 'storage_selection_dialog.dart';" not in content:
    content = "import 'storage_selection_dialog.dart';\nimport '../../models/item_database_model.dart';\n" + content

with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)

# Fix storage_selection_dialog.dart
with open('lib/screens/owner/storage_selection_dialog.dart', 'r') as f:
    dialog_content = f.read()

dialog_content = dialog_content.replace('ApiService().fetchItemDatabase()', 'ApiService().getDatabaseItems()')
dialog_content = dialog_content.replace('item.itemId != null', 'item.itemId.isNotEmpty') # sku and itemId are not null usually or we can just check if they are not empty?
# Wait, sku is nullable in ItemDatabaseModel? Let's check model.
# Just use (item.sku ?? '').toLowerCase().contains...
dialog_content = dialog_content.replace(
    '(item.sku != null && item.sku!.toLowerCase().contains(query.toLowerCase()))',
    '((item.sku ?? "").toLowerCase().contains(query.toLowerCase()))'
)
dialog_content = dialog_content.replace(
    '(item.itemId != null && item.itemId!.toLowerCase().contains(query.toLowerCase()))',
    '((item.itemId).toLowerCase().contains(query.toLowerCase()))'
)
dialog_content = dialog_content.replace('item.itemId ?? "N/A"', 'item.itemId')

with open('lib/screens/owner/storage_selection_dialog.dart', 'w') as f:
    f.write(dialog_content)

