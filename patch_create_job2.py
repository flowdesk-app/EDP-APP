import sys
import re

with open('lib/screens/owner/create_job_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("_descriptionCtrl.text.trim()", "_wheelSizeCtrl.text.trim()")

with open('lib/screens/owner/create_job_screen.dart', 'w') as f:
    f.write(content)
