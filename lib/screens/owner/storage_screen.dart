import 'package:flutter/material.dart';
import '../../models/company_storage.dart';
import 'company_items_screen.dart';
import '../../services/api_service.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDynamicCompanies();
  }

  Future<void> _loadDynamicCompanies() async {
    await ApiService().fetchAndMergeDynamicCompanies();
    if (mounted) setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final filteredCompanies = kCompanyStorages
        .where((company) => company.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Storage',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Browse and manage items assigned to specific companies.',
                        style: TextStyle(color: Color(0xFF757575)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search companies...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 1.5,
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
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => CompanyItemsScreen(company: company),
                        ));
                      },
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business, size: 32, color: Color(0xFF29B6F6)),
                            const SizedBox(height: 16),
                            Text(
                              company.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
        ),
      ),
    );
  }
}
