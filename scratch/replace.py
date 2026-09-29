import sys

with open('lib/screens/owner/main_layout.dart', 'r') as f:
    content = f.read()

start_idx = content.find('  Widget _buildDesktopLayout() {')
end_idx = content.find('  Widget _buildMobileLayout() {')

with open('scratch/replace_rail.dart', 'r') as f:
    new_content = f.read()

final_content = content[:start_idx] + new_content + "\n" + content[end_idx:]

with open('lib/screens/owner/main_layout.dart', 'w') as f:
    f.write(final_content)
