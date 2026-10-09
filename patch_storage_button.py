import sys
import os

files = [
    'lib/screens/owner/stock_at_edp_screen.dart',
    'lib/screens/owner/create_job_screen.dart'
]

for file in files:
    with open(file, 'r') as f:
        content = f.read()
    content = content.replace("Text('Use from Storage')", "Text('Use from Database')")
    with open(file, 'w') as f:
        f.write(content)
