import sys
import re

with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

# find the block I injected earlier:
old_block = """      String lcConc = _highConcentrationCtrl.text.trim().isNotEmpty ? _highConcentrationCtrl.text.trim() : _standardConcentrationCtrl.text.trim();
      String lcPartNumber = 'EDP-LC-${_micronSizeCtrl.text.trim()}-${lcConc}';
      String lcDescription = 'Lapping Compound, Size: ${_micronSizeCtrl.text.trim()} Micron, Conc: $lcConc, Colour: ${_micronColorCtrl.text.trim()}, Base: ${_baseType ?? ''}, Weight: ${_syringeQuantityCtrl.text.trim()}CC';
"""

new_block = """      String lcConc = (_highConcentrationCtrl.text.trim().toLowerCase() == 'yes' || _highConcentrationCtrl.text.trim().toLowerCase() == 'high') ? 'HIGH' : 'STD';
      String lcPartNumber = 'LC-${_micronSizeCtrl.text.trim()}-$lcConc';
      String lcDescription = 'Lapping Compound, Size: ${_micronSizeCtrl.text.trim()} Micron, Conc: $lcConc, Colour: ${_micronColorCtrl.text.trim()}, Base: ${_baseType ?? ''}, Weight: ${_syringeQuantityCtrl.text.trim()}CC';
"""

if old_block in content:
    content = content.replace(old_block, new_block)
    
with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)
