import sys

with open('lib/screens/owner/main_layout.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "import 'item_database_screen.dart';",
    "import 'item_database_screen.dart';\nimport 'storage_screen.dart';"
)

content = content.replace(
    "const ItemDatabaseScreen(), // 10. Item Database\n      ];",
    "const ItemDatabaseScreen(), // 10. Item Database\n        const StorageScreen(), // 11. Storage\n      ];"
)

content = content.replace(
    "const NavigationRailDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: Text('Database')),\n      ];",
    "const NavigationRailDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: Text('Database')),\n        const NavigationRailDestination(icon: Icon(Icons.business_center_outlined), selectedIcon: Icon(Icons.business_center), label: Text('Storage')),\n      ];"
)

with open('lib/screens/owner/main_layout.dart', 'w') as f:
    f.write(content)
