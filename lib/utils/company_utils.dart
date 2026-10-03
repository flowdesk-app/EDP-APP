import '../models/company_storage.dart';

List<String> getCompaniesForPrefix(String itemName) {
  final upperName = itemName.toUpperCase();
  
  
  // Special handling for Lapping Compound (LC)
  if (upperName == 'LC' || upperName.startsWith('LC-') || upperName.startsWith('LC ') || upperName.endsWith('-LC') || upperName.endsWith(' LC') || upperName.contains('-LC-') || upperName.contains(' LC ') || upperName.contains(' LC-') || upperName.contains('-LC ')) {
    return ['Lapping Compound'];
  }

  // Special handling for RBL with explicit locations
  if (upperName.startsWith('RBL ') || upperName.startsWith('RBL-')) {
    if (upperName.contains('TRICHY')) {
      return ['Rane Brake Lining Limited Trichy'];
    }
    if (upperName.contains('MEDAK')) {
      return ['Rane Brakelining Limited Medak'];
    }
    if (upperName.contains('AMBATTUR')) {
      return ['Rane Brake Lining Limited Ambattur'];
    }
    if (upperName.contains('PONDICHERRY')) {
      return ['Rane Brakelining Limited Pondicherry'];
    }
  }

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
