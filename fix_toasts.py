import os
import re

lib_dir = r"d:\Lunara\lunara\lib"

# Regex to find the broken CustomToast.show calls
toast_regex = re.compile(
    r"CustomToast\.show\(\s*context:\s*context,\s*message:\s*(.*?),\s*isError:\s*(true|false),\s*\);",
    re.DOTALL
)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'CustomToast.show(' not in content:
        return
        
    def repl(match):
        msg = match.group(1).strip()
        is_error = match.group(2) == 'true'
        
        # Fix multiline literal strings that were broken by regex capture
        if msg.startswith("'") and msg.endswith("'"):
            inner = msg[1:-1].replace('\n', ' ')
            msg = f"'{inner}'"
        elif msg.startswith('"') and msg.endswith('"'):
            inner = msg[1:-1].replace('\n', ' ')
            msg = f'"{inner}"'
            
        if is_error:
            return f"CustomToast.show(context, message: {msg}, icon: Icons.error_outline, backgroundColor: Colors.red[400]);"
        else:
            return f"CustomToast.show(context, message: {msg}, icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));"

    new_content = toast_regex.sub(repl, content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
