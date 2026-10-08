import sys

with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

# Add the import for the dialog
if 'storage_selection_dialog.dart' not in content:
    content = content.replace("import '../../models/api_response.dart';", "import '../../models/api_response.dart';\nimport 'storage_selection_dialog.dart';\nimport '../../models/item_database_model.dart';")

# We need a method to handle storage selection
handler_code = """
  Future<void> _handleStorageSelection() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const StorageSelectionDialog(),
    );

    if (result != null) {
      final companyName = result['company'] as String;
      final item = result['item'] as ItemDatabaseModel;

      setState(() {
        _customerNameCtrl.text = companyName;
        // User said: "Part number will be mentioned at the top... Diamond proud git size will be in the description, so we'll take that separately... description will be copied from there"
        // Let's populate the text fields
        _partNumberCtrl.text = item.itemName;
        _wheelSizeCtrl.text = item.description ?? '';
        
        // Extract Grit Size if it's in the description or just leave it for the user to edit? 
        // Or if item.itemName has grit size. For now we just put itemName in part number.
        // If there's any logic to extract grit size, we could do it, but we can also just fill description with item.description.
      });
    }
  }

  Widget _buildStorageButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: _handleStorageSelection,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Use from Storage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
"""

if "_handleStorageSelection" not in content:
    content = content.replace("Widget _buildNewFlow() {", handler_code + "\n  Widget _buildNewFlow() {")

# Add button to _buildNewFlow
if "_buildStorageButton()," not in content.split("Widget _buildNewFlow() {")[1].split("]")[0]:
    content = content.replace(
        "_buildCreatedDateSelector(),",
        "_buildStorageButton(),\n          _buildCreatedDateSelector(),"
    )

# Add button to _buildLappingCompoundFlow
if "Widget _buildLappingCompoundFlow() {" in content:
    if "_buildStorageButton()," not in content.split("Widget _buildLappingCompoundFlow() {")[1].split("]")[0]:
        content = content.replace(
            "Widget _buildLappingCompoundFlow() {\n    return SingleChildScrollView(\n      padding: const EdgeInsets.all(16),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.stretch,\n        children: [",
            "Widget _buildLappingCompoundFlow() {\n    return SingleChildScrollView(\n      padding: const EdgeInsets.all(16),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.stretch,\n        children: [\n          _buildStorageButton(),"
        )

# Add button to _getRecoatingSteps
if "List<Step> _getRecoatingSteps() {" in content:
    step_content = content.split("List<Step> _getRecoatingSteps() {")[1]
    # Find the first _buildCreatedDateSelector(), in _getRecoatingSteps
    # It might be there in the Customer Details step
    content = content.replace(
        "List<Step> _getRecoatingSteps() {\n    return [\n      Step(\n        title: const Text('Customer Details'),\n        isActive: _currentStep >= 0,\n        content: Column(\n          children: [\n            _buildCreatedDateSelector(),",
        "List<Step> _getRecoatingSteps() {\n    return [\n      Step(\n        title: const Text('Customer Details'),\n        isActive: _currentStep >= 0,\n        content: Column(\n          children: [\n            _buildStorageButton(),\n            _buildCreatedDateSelector(),"
    )

with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)

