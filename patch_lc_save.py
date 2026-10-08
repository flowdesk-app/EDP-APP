import sys
import re

with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

new_save_call = """
      await _api.createJob(job);
      
      String lcConc = _highConcentrationCtrl.text.trim().isNotEmpty ? _highConcentrationCtrl.text.trim() : _standardConcentrationCtrl.text.trim();
      String lcPartNumber = 'EDP-LC-${_micronSizeCtrl.text.trim()}-${lcConc}';
      String lcDescription = 'Lapping Compound, Size: ${_micronSizeCtrl.text.trim()} Micron, Conc: $lcConc, Colour: ${_micronColorCtrl.text.trim()}, Base: ${_baseType ?? ''}, Weight: ${_syringeQuantityCtrl.text.trim()}CC';
      
      await _checkAndSaveStorage('Lapping Compound', lcPartNumber, lcDescription);
"""

# We need to replace the single line at line 980 with this block.
# Since we know it's inside the Lapping Compound section, let's locate it by context.
context_str = """      await _api.createJob(job);
      await _checkAndSaveStorage(_customerNameCtrl.text.trim(), _partNumberCtrl.text.trim(), _wheelSizeCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context); // loading dialog"""

if context_str in content:
    content = content.replace(context_str, new_save_call + """      if (mounted) {
        Navigator.pop(context); // loading dialog""")
    
with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)
