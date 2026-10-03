import '../models/company_storage.dart';

List<String> getCompaniesForPrefix(String itemName) {
  final parts = itemName.split(RegExp(r'[- ]'));
  if (parts.isEmpty) return [];
  final prefix = parts[0].toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  
  List<String> matchedCompanies = [];
  
  for (var company in kCompanyStorages) {
    if (company.prefixes.contains(prefix)) {
      matchedCompanies.add(company.name);
    }
  }
  
  if (matchedCompanies.isNotEmpty) {
    return matchedCompanies;
  }
  
  // Fallback for special cases (e.g., JK-FEN)
  for (var company in kCompanyStorages) {
    for (var p in company.prefixes) {
      if (itemName.toUpperCase().startsWith(p.toUpperCase())) {
        if (!matchedCompanies.contains(company.name)) {
           matchedCompanies.add(company.name);
        }
      }
    }
  }
  
  return matchedCompanies;
}
