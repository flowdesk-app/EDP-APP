import sys
import re

with open('lib/services/api_service.dart', 'r') as f:
    content = f.read()

# Add api endpoints
new_methods = """
  Future<void> saveToItemDatabase(String itemName, String? description) async {
    if (itemName.trim().isEmpty) return;
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/item-database'),
      headers: _headers,
      body: jsonEncode({
        'itemName': itemName.trim(),
        'description': description?.trim() ?? '',
      }),
    );
    if (res.statusCode != 200) {
      print('Failed to save item to database: ${res.body}');
    }
  }

  Future<void> fetchAndMergeDynamicCompanies() async {
    await _loadToken();
    try {
      final res = await http.get(Uri.parse('$baseUrl/companies'), headers: _headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final dynamicCompanies = data.map((e) => CompanyStorage.fromJson(e)).toList();
        mergeDynamicCompanies(dynamicCompanies);
      }
    } catch (e) {
      print('Error fetching companies: $e');
    }
  }

  Future<void> createCompanyStorage(String name, String prefix) async {
    if (name.trim().isEmpty) return;
    await _loadToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/companies'),
        headers: _headers,
        body: jsonEncode({
          'name': name.trim(),
          'prefixes': [prefix.trim().toUpperCase()]
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        mergeDynamicCompanies([CompanyStorage.fromJson(data)]);
      }
    } catch (e) {
      print('Error creating company: $e');
    }
  }
"""

if "saveToItemDatabase" not in content:
    # Need to make sure we have CompanyStorage imported
    if "import '../models/company_storage.dart';" not in content:
        content = content.replace("import '../models/job_model.dart';", "import '../models/job_model.dart';\nimport '../models/company_storage.dart';")
    
    # Insert before the last closing brace
    last_brace_index = content.rfind('}')
    content = content[:last_brace_index] + new_methods + content[last_brace_index:]

with open('lib/services/api_service.dart', 'w') as f:
    f.write(content)
