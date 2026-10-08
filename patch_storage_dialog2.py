import sys
import re

with open('lib/screens/owner/storage_selection_dialog.dart', 'r') as f:
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
    content = content.replace("final TextEditingController _searchCtrl = TextEditingController();", "final TextEditingController _searchCtrl = TextEditingController();\n" + init_state)

with open('lib/screens/owner/storage_selection_dialog.dart', 'w') as f:
    f.write(content)
