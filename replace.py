import os
import re

directory = 'lib/screens/'
import_str = "import '../utils/emergency_helper.dart';\n"

method_regex = re.compile(
    r'([ \t]*)Future<void> _triggerSOS\(BuildContext context\) async \{[\s\S]*?if \(confirmed == true\) \{[\s\S]*?\}[\s\S]*?\}[\s\S]*?\}'
)

for filename in os.listdir(directory):
    if filename.endswith('.dart'):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r') as f:
            content = f.read()
        
        if '_triggerSOS' in content:
            # 1. Add import if not present
            if import_str not in content:
                content = content.replace("import '../services/api_service.dart';", "import '../services/api_service.dart';\n" + import_str)
            
            # 2. Replace method using regex or simply by finding the bounds if regex is hard
            
            # A safer way to replace since the method is exactly identical:
            # Instead of a complex regex, we can find the start of the method and the end of the method counting braces.
            idx = content.find('Future<void> _triggerSOS(BuildContext context) async {')
            if idx != -1:
                start_idx = idx
                brace_count = 0
                i = start_idx
                found_first_brace = False
                while i < len(content):
                    if content[i] == '{':
                        brace_count += 1
                        found_first_brace = True
                    elif content[i] == '}':
                        brace_count -= 1
                    
                    i += 1
                    if found_first_brace and brace_count == 0:
                        break
                
                # Replace the entire block
                replacement = 'Future<void> _triggerSOS(BuildContext context) async {\n    await EmergencyHelper.triggerSOS(context, widget.seniorId);\n  }'
                content = content[:start_idx] + replacement + content[i:]
                
            with open(filepath, 'w') as f:
                f.write(content)
                print(f"Updated {filepath}")

