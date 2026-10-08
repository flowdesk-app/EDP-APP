import sys
import re

with open('lib/screens/owner/storage_screen.dart', 'r') as f:
    content = f.read()

init_state = """
  @override
  void initState() {
    super.initState();
    _loadDynamicCompanies();
  }

  Future<void> _loadDynamicCompanies() async {
    await ApiService().fetchAndMergeDynamicCompanies();
    if (mounted) setState(() {});
  }
"""

if "_loadDynamicCompanies" not in content:
    content = content.replace("import 'company_items_screen.dart';", "import 'company_items_screen.dart';\nimport '../../services/api_service.dart';")
    content = content.replace("String _searchQuery = '';", "String _searchQuery = '';\n" + init_state)

with open('lib/screens/owner/storage_screen.dart', 'w') as f:
    f.write(content)
