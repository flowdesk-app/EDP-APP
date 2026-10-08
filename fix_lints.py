import os
import re

def fix_opacity(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Simple replace for .withOpacity(0.x) to .withValues(alpha: 0.x)
    # Be careful not to replace things we don't know
    content = re.sub(r'\.withOpacity\((.*?)\)', r'.withAlpha((\1 * 255).toInt())', content) 
    
    with open(filepath, 'w') as f:
        f.write(content)

fix_opacity('lib/screens/owner/company_items_screen.dart')
fix_opacity('lib/screens/owner/item_database_screen.dart')

# For main_layout.dart, let's look at the context gap.
# Wait, let's just use withOpacity -> withOpacity ... 
# Actually withOpacity -> withAlpha(a) is not what they suggested, they said .withValues()
# But wait, .withValues(alpha: ...) doesn't exist in older flutter. Let's see what flutter version is used.
