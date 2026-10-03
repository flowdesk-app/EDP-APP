import '../models/company_storage.dart';

String? getCompanyForPrefix(String itemName) {
  final parts = itemName.split(RegExp(r'[- ]'));
  if (parts.isEmpty) return null;
  final prefix = parts[0].toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  
  for (var company in kCompanyStorages) {
    if (company.prefixes.contains(prefix)) {
      return company.name;
    }
  }
  
  // Fallback for special cases
  for (var company in kCompanyStorages) {
    for (var p in company.prefixes) {
      if (itemName.toUpperCase().startsWith(p.toUpperCase())) {
        return company.name;
      }
    }
  }
  return null;
}
