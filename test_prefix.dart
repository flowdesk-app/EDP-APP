void main() {
  String itemName = "GIVE&TAKE ENTERPRIES";
  final parts = itemName.split(RegExp(r'[- ]'));
  if (parts.isEmpty) return;
  final prefix = parts[0].toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  print("Prefix: $prefix");
}
