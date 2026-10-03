void sortItems(List<ItemDatabaseModel> items, String query) {
  if (query.isEmpty) return;
  final q = query.toLowerCase();
  
  int getScore(ItemDatabaseModel item) {
    final name = item.itemName.toLowerCase();
    final desc = (item.description ?? '').toLowerCase();
    
    if (name == q) return 100;
    if (name.startsWith(q)) return 90;
    if (name.contains(RegExp('\\b$q\\b'))) return 80;
    if (name.contains(RegExp('\\b$q'))) return 70;
    if (name.contains(q)) return 60;
    
    if (desc == q) return 50;
    if (desc.startsWith(q)) return 40;
    if (desc.contains(RegExp('\\b$q\\b'))) return 30;
    if (desc.contains(RegExp('\\b$q'))) return 20;
    if (desc.contains(q)) return 10;
    
    return 0;
  }
  
  items.sort((a, b) => getScore(b).compareTo(getScore(a)));
}
