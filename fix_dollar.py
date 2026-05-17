with open(r'c:\Users\HP\Desktop\convive_\lib\screens\login_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix escaped dollar signs
old = r"context.go('/complete-profile?userId=\$userId&email=\${Uri.encodeComponent(userEmail)}');"
new = "context.go('/complete-profile?userId=$userId&email=${Uri.encodeComponent(userEmail)}');"

if old in content:
    content = content.replace(old, new)
    with open(r'c:\Users\HP\Desktop\convive_\lib\screens\login_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed dollar signs")
else:
    print("Target not found - checking content...")
    for i, line in enumerate(content.split('\n')):
        if 'complete-profile' in line:
            print(f"  L{i+1}: {repr(line)}")
