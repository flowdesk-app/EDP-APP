import sys
import re

with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

# Make sure we import CompanyStorage
if "import '../../models/company_storage.dart';" not in content:
    content = content.replace("import '../../services/api_service.dart';", "import '../../services/api_service.dart';\nimport '../../models/company_storage.dart';")

helper_func = """
  Future<void> _checkAndSaveStorage(String customerName, String partNumber, String description) async {
    if (customerName.isEmpty || partNumber.isEmpty) return;
    
    // Check if company exists in kCompanyStorages
    bool companyExists = kCompanyStorages.any((c) => c.name.toLowerCase() == customerName.toLowerCase());
    
    if (!companyExists) {
      // Create new company
      final prefix = customerName.split(' ').first.toUpperCase();
      await _api.createCompanyStorage(customerName, prefix);
    }
    
    // Save item to database
    await _api.saveToItemDatabase(partNumber, description);
  }
"""

if "_checkAndSaveStorage" not in content:
    content = content.replace("  Future<void> _handleStorageSelection() async {", helper_func + "\n  Future<void> _handleStorageSelection() async {")

# Now inject it into the save logic for New, Recoating, Coating, Blank, and Lapping!
# New Job
content = content.replace("await _api.createJob(job);", "await _api.createJob(job);\n      await _checkAndSaveStorage(_customerNameCtrl.text.trim(), _partNumberCtrl.text.trim(), _descriptionCtrl.text.trim());")

# wait, there are multiple await _api.createJob(job)!
# Let's see how many there are.
with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)
