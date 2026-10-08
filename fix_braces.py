import os
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Replace single line if statements: if (cond) statement; -> if (cond) { statement; }
    # Using regex, this can be tricky. Let's do it specifically for user_model.dart and api_service.dart
    
    if 'user_model.dart' in filepath:
        content = re.sub(r'if \((.*?)\)\s+([\w\.]+)\s*=\s*(.*?);', r'if (\1) {\n      \2 = \3;\n    }', content)
    
    if 'api_service.dart' in filepath:
        # e.g. if (res.statusCode == 200) return jsonDecode(res.body);
        content = re.sub(r'if \((.*?)\)\s+return\s+(.*?);', r'if (\1) {\n      return \2;\n    }', content)
        content = re.sub(r'if \((.*?)\)\s+throw\s+(.*?);', r'if (\1) {\n      throw \2;\n    }', content)
    
    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/models/user_model.dart')
fix_file('lib/services/api_service.dart')
