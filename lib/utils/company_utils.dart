import '../models/company_storage.dart';

List<String> getCompaniesForPrefix(String itemName) {
  final upperName = itemName.toUpperCase();
  
  
  
  // Special handling for ADMAC
  if (upperName.contains('ADMAC') || upperName.contains('ADMACH')) {
    return ['ADMAC'];
  }

  // Special handling for Lapping Compound (LC)
  if (upperName == 'LC' || upperName.startsWith('LC-') || upperName.startsWith('LC ') || upperName.endsWith('-LC') || upperName.endsWith(' LC') || upperName.contains('-LC-') || upperName.contains(' LC ') || upperName.contains(' LC-') || upperName.contains('-LC ')) {
    return ['Lapping Compound'];
  }

  
  // Special handling for BIL SRICITY
  if (upperName.startsWith('BIL') && (upperName.contains('SRIC') || upperName.contains('SRI CITY') || upperName.contains('SRI-CITY') || upperName.contains('BILSRI'))) {
    return ['Brakes india limited SRICITY'];
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

bool smartMatch(String? target, String query) {
  if (query.trim().isEmpty) return true;
  if (target == null || target.trim().isEmpty) return false;

  final normTarget = target.toLowerCase().replaceAll(RegExp(r'[\r\n\t]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final normQuery = query.toLowerCase().replaceAll(RegExp(r'[\r\n\t]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // 1. Exact normalized substring match
  if (normTarget.contains(normQuery)) return true;

  // 2. Query with ellipses/dots removed (e.g. if user copied from UI preview)
  final cleanQuery = normQuery.replaceAll(RegExp(r'\.{2,}'), '').trim();
  if (cleanQuery.isNotEmpty && normTarget.contains(cleanQuery)) return true;

  // 3. Alphanumeric match (ignores all hyphens, slashes, punctuation, spacing differences)
  final alphaTarget = normTarget.replaceAll(RegExp(r'[^a-z0-9]'), '');
  final alphaQuery = cleanQuery.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (alphaQuery.length > 2 && alphaTarget.contains(alphaQuery)) return true;

  // 4. Token / word-based match: all words/numbers typed in the search query must exist in target
  final tokens = cleanQuery
      .replaceAll(RegExp(r'[,\.;:\(\)\[\]\{\}"\n\r\-–—/]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.isEmpty) return true;

  return tokens.every((t) {
    final alphaT = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normTarget.contains(t) || (alphaT.length > 1 && alphaTarget.contains(alphaT));
  });
}

