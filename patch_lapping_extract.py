import sys
import re

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
        final desc = item.description ?? '';
        
        if (_flowType == FlowType.lappingCompound) {
          // Extract Micron Size
          final sizeMatch = RegExp(r'Size:\s*([0-9/\-]+)', caseSensitive: false).firstMatch(desc);
          if (sizeMatch != null) {
            _micronSizeCtrl.text = sizeMatch.group(1)!;
          }
          
          // Extract Concentration
          final concMatch = RegExp(r'Conc[.:]\s*([a-zA-Z]+)', caseSensitive: false).firstMatch(desc);
          if (concMatch != null) {
            final conc = concMatch.group(1)!.toLowerCase();
            if (conc == 'high') {
              _highConcentrationCtrl.text = 'Yes';
              _standardConcentrationCtrl.text = 'No';
            } else if (conc == 'std' || conc == 'standard') {
              _standardConcentrationCtrl.text = 'Yes';
              _highConcentrationCtrl.text = 'No';
            }
          }
          
          // Extract Color
          final colorMatch = RegExp(r'Colour:\s*([a-zA-Z]+)', caseSensitive: false).firstMatch(desc);
          if (colorMatch != null) {
            _micronColorCtrl.text = colorMatch.group(1)!;
          }
          
          // Extract Quantity/Weight
          final weightMatch = RegExp(r'Weight:\s*([0-9]+[a-zA-Z]*)', caseSensitive: false).firstMatch(desc);
          if (weightMatch != null) {
            _syringeQuantityCtrl.text = weightMatch.group(1)!;
          } else if (item.usageUnit != null) {
            _syringeQuantityCtrl.text = item.usageUnit!;
          }
        } else {
          _partNumberCtrl.text = item.itemName;
          _wheelSizeCtrl.text = desc;
          
          final gritRegExp = RegExp(r'Grit\s*[:-]?\s*([0-9/]+)', caseSensitive: false);
          final match = gritRegExp.firstMatch(desc);
          if (match != null && match.groupCount >= 1) {
            _gritSizeCtrl.text = match.group(1)!;
          } else {
            _gritSizeCtrl.text = '';
          }
        }
      });
    }
  }"""

# Use string replace for the method block
import re

content = re.sub(
    r'  Future<void> _handleStorageSelection\(\) async \{.*?    \}\n  \}',
    replacement,
    content,
    flags=re.DOTALL
)

with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)

