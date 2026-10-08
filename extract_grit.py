import sys

with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

replacement = """  Future<void> _handleStorageSelection() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const StorageSelectionDialog(),
    );

    if (result != null) {
      final companyName = result['company'] as String;
      final item = result['item'] as ItemDatabaseModel;

      setState(() {
        _customerNameCtrl.text = companyName;
        _partNumberCtrl.text = item.itemName;
        
        final desc = item.description ?? '';
        _wheelSizeCtrl.text = desc;
        
        // Extract Grit Size
        // Look for "Grit" followed by numbers/slashes
        final gritRegExp = RegExp(r'Grit\s*[:-]?\s*([0-9/]+)', caseSensitive: false);
        final match = gritRegExp.firstMatch(desc);
        if (match != null && match.groupCount >= 1) {
          _gritSizeCtrl.text = match.group(1)!;
        } else {
          // If not found by regex, maybe just leave it blank or let the user fill it.
          // Sometimes it might just be numbers, but we only extract if 'Grit' is mentioned.
          _gritSizeCtrl.text = '';
        }
      });
    }
  }"""

# Find the existing _handleStorageSelection and replace it
import re

content = re.sub(
    r'Future<void> _handleStorageSelection\(\) async \{.*?(?=\Widget _buildStorageButton)',
    replacement + '\n\n  ',
    content,
    flags=re.DOTALL
)

with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)

