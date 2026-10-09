import sys

with open('lib/screens/owner/main_layout.dart', 'r') as f:
    content = f.read()

# Remove the ItemDatabaseScreen line
content = content.replace("        const ItemDatabaseScreen(), // 10. Item Database\n", "")
# Rename Storage to Database, keep Storage icon or change to Database icon?
# The user said "name the storage section as Database". Let's give it the storage icon since it's now called Database.
content = content.replace("        const NavigationRailDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: Text('Database')),\n", "")
content = content.replace("        const NavigationRailDestination(icon: Icon(Icons.business_center_outlined), selectedIcon: Icon(Icons.business_center), label: Text('Storage')),", "        const NavigationRailDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: Text('Database')),")

with open('lib/screens/owner/main_layout.dart', 'w') as f:
    f.write(content)
