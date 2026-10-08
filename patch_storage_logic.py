import sys
import re

with open('lib/screens/owner/storage_selection_dialog.dart', 'r') as f:
    content = f.read()

# Add import
if "import '../../utils/company_utils.dart';" not in content:
    content = content.replace("import '../../services/api_service.dart';", "import '../../services/api_service.dart';\nimport '../../utils/company_utils.dart';")

# Replace _fetchItems
new_fetch = """  Future<void> _fetchItems(CompanyStorage company) async {
    setState(() {
      _selectedCompany = company;
      _isLoading = true;
      _searchCtrl.clear();
    });

    try {
      final items = await ApiService().getDatabaseItems();
      setState(() {
        _items = items.where((i) => getCompaniesForPrefix(i.itemName).contains(company.name)).toList();
        _filteredItems = List.from(_items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
      }
    }
  }"""

content = re.sub(r'  Future<void> _fetchItems\(CompanyStorage company\) async \{.*?    \} catch \(e\) \{\n      setState\(\(\) => _isLoading = false\);\n      if \(mounted\) \{\n        ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\(\'Failed to load items: \$e\'\)\)\);\n      \}\n    \}\n  \}', new_fetch, content, flags=re.DOTALL)

with open('lib/screens/owner/storage_selection_dialog.dart', 'w') as f:
    f.write(content)
