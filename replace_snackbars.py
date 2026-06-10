import os
import re

lib_dir = r"d:\Lunara\lunara\lib"

# Matches: ScaffoldMessenger.of(context).showSnackBar(...)
# Note: This is a simplistic approach and might need refinement
snack_regex = re.compile(
    r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s+)?SnackBar\(\s*content:\s*(?:const\s+)?Text\((.*?)\).*?\)(?:,)?\s*\);',
    re.DOTALL
)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'ScaffoldMessenger.of(context).showSnackBar' not in content:
        return

    # Check if we need to add import
    needs_import = False
    
    def repl(match):
        nonlocal needs_import
        needs_import = True
        text_arg = match.group(1)
        # Determine if error
        is_error = 'false'
        if 'Colors.red' in match.group(0) or 'Colors.orange' in match.group(0):
            is_error = 'true'
            
        return f"""CustomToast.show(
          context: context,
          message: {text_arg},
          isError: {is_error},
        );"""

    new_content = snack_regex.sub(repl, content)

    if new_content != content:
        # Add import
        # Count depth to lib
        rel_path = os.path.relpath(filepath, lib_dir)
        depth = rel_path.count(os.sep)
        import_str = "import '" + ("../" * depth) + "widgets/custom_toast.dart';"
        
        if import_str not in new_content:
            # Insert after the last import
            lines = new_content.split('\n')
            last_import = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import = i
            
            if last_import != -1:
                lines.insert(last_import + 1, import_str)
            else:
                lines.insert(0, import_str)
                
            new_content = '\n'.join(lines)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
