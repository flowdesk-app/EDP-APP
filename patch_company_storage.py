import sys
import re

with open('lib/models/company_storage.dart', 'r') as f:
    content = f.read()

# Make CompanyStorage non-const and add fromJson
new_class = """class CompanyStorage {
  final String name;
  final List<String> prefixes;

  CompanyStorage({required this.name, required this.prefixes});

  factory CompanyStorage.fromJson(Map<String, dynamic> json) {
    return CompanyStorage(
      name: json['name'] ?? '',
      prefixes: List<String>.from(json['prefixes'] ?? []),
    );
  }
}"""
content = re.sub(r'class CompanyStorage \{.*?\n\}', new_class, content, flags=re.DOTALL)

# Make kCompanyStorages non-const
content = content.replace("const List<CompanyStorage> kCompanyStorages", "List<CompanyStorage> kCompanyStorages")

# Remove const from instances
content = content.replace("  CompanyStorage(", "  CompanyStorage(") # just in case, but let's do a regex

# Let's just remove all "const CompanyStorage("
content = content.replace("const CompanyStorage(", "CompanyStorage(")

# Add merge function
merge_func = """
void mergeDynamicCompanies(List<CompanyStorage> dynamicCompanies) {
  for (var dyn in dynamicCompanies) {
    if (!kCompanyStorages.any((c) => c.name == dyn.name)) {
      kCompanyStorages.add(dyn);
    }
  }
}
"""
content += merge_func

with open('lib/models/company_storage.dart', 'w') as f:
    f.write(content)
