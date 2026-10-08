import sys

with open('lib/screens/owner/stock_at_edp_screen.dart', 'r') as f:
    content = f.read()

if "import 'storage_selection_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'storage_selection_dialog.dart';\nimport '../../models/item_database_model.dart';")

with open('lib/screens/owner/stock_at_edp_screen.dart', 'w') as f:
    f.write(content)
