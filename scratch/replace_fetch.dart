  Future<void> _fetchItems([String search = '']) async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService().getDatabaseItems(search);
      
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        final escapedQ = RegExp.escape(q);
        
        int getScore(ItemDatabaseModel item) {
          final name = item.itemName.toLowerCase();
          final desc = (item.description ?? '').toLowerCase();
          
          if (name == q) return 100;
          if (name.startsWith(q)) return 90;
          if (name.contains(RegExp('\\b$escapedQ\\b'))) return 80;
          if (name.contains(RegExp('\\b$escapedQ'))) return 70;
          if (name.contains(q)) return 60;
          
          if (desc == q) return 50;
          if (desc.startsWith(q)) return 40;
          if (desc.contains(RegExp('\\b$escapedQ\\b'))) return 30;
          if (desc.contains(RegExp('\\b$escapedQ'))) return 20;
          if (desc.contains(q)) return 10;
          
          return 0;
        }
        
        items.sort((a, b) => getScore(b).compareTo(getScore(a)));
      }

      if (mounted) {
        setState(() {
          _items = items;
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
