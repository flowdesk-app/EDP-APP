import '../../models/company_storage.dart';
import '../../models/item_database_model.dart';

String? getCompanyForPrefix(String itemName) {
  final prefix = itemName.split(RegExp(r'[- ]'))[0].toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  for (var company in kCompanyStorages) {
    if (company.prefixes.contains(prefix)) {
      return company.name;
    }
  }
  // Try special cases like JK-FEN
  for (var company in kCompanyStorages) {
    for (var p in company.prefixes) {
      if (itemName.toUpperCase().startsWith(p.toUpperCase())) {
        return company.name;
      }
    }
  }
  return null;
}
