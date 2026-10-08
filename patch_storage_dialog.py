import sys
import re

with open('lib/screens/owner/storage_selection_dialog.dart', 'r') as f:
    content = f.read()

# Add _companySearchQuery
if "String _companySearchQuery" not in content:
    content = content.replace("final TextEditingController _searchCtrl = TextEditingController();", "final TextEditingController _searchCtrl = TextEditingController();\n  String _companySearchQuery = '';")

# Replace _buildCompanyGrid
new_build_company_grid = """  Widget _buildCompanyGrid() {
    final filteredCompanies = kCompanyStorages
        .where((company) => company.name.toLowerCase().contains(_companySearchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search companies...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _companySearchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredCompanies.length,
            itemBuilder: (context, index) {
              final company = filteredCompanies[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: InkWell(
                  onTap: () => _fetchItems(company),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business, size: 32, color: Color(0xFF29B6F6)),
                        const SizedBox(height: 12),
                        Text(
                          company.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }"""

content = re.sub(r'  Widget _buildCompanyGrid\(\) \{.*?\}\n\n\n  Widget _buildItemsView\(\)', new_build_company_grid + '\n\n  Widget _buildItemsView()', content, flags=re.DOTALL)

with open('lib/screens/owner/storage_selection_dialog.dart', 'w') as f:
    f.write(content)
