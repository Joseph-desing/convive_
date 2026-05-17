with open(r'c:\Users\HP\Desktop\convive_\lib\screens\complete_profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Show lines 45-75 to see current state
lines = content.split('\n')
print("=== CURRENT FILE (lines 45-80) ===")
for i in range(44, min(80, len(lines))):
    print(f"  {i+1}: {repr(lines[i])}")
