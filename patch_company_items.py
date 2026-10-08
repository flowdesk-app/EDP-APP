import sys
import re

with open('lib/screens/owner/company_items_screen.dart', 'r') as f:
    content = f.read()

# Add _allItems
content = content.replace("List<ItemDatabaseModel> _items = [];", "List<ItemDatabaseModel> _allItems = [];\n  List<ItemDatabaseModel> _items = [];")

new_fetch = """  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService().getDatabaseItems('');
      final unassignedItems = items.where((i) => getCompaniesForPrefix(i.itemName).contains(widget.company.name)).toList();
      
      if (mounted) {
        setState(() {
          _allItems = unassignedItems;
          _items = List.from(_allItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _items = List.from(_allItems));
      return;
    }
    
    final q = query.toLowerCase();
    setState(() {
      _items = _allItems.where((item) =>
        item.itemName.toLowerCase().contains(q) ||
        ((item.sku ?? "").toLowerCase().contains(q)) ||
        (item.itemId.isNotEmpty && item.itemId.toLowerCase().contains(q)) ||
        ((item.description ?? "").toLowerCase().contains(q))
      ).toList();
    });
  }"""

content = re.sub(r'  Future<void> _fetchItems.*?void _onSearchChanged\(String query\) \{\n    _fetchItems\(query\);\n  \}', new_fetch, content, flags=re.DOTALL)

# Replace onSubmitted with onChanged
content = content.replace("onSubmitted: _onSearchChanged,", "onChanged: _onSearchChanged,")

with open('lib/screens/owner/company_items_screen.dart', 'w') as f:
    f.write(content)
