import sys

with open('lib/screens/owner/item_database_screen.dart', 'r') as f:
    content = f.read()

start_idx = content.find('  Widget _buildItemCard(ItemDatabaseModel item) {')
end_idx = content.find('  Widget _buildInfoRow(IconData icon, String text) {')

with open('scratch/replace_card.dart', 'r') as f:
    new_content = f.read()

final_content = content[:start_idx] + new_content + "\n" + content[end_idx:]

with open('lib/screens/owner/item_database_screen.dart', 'w') as f:
    f.write(final_content)
