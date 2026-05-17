import re

with open(r'c:\Users\HP\Desktop\convive_\lib\screens\login_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """        // Redirigir según el rol del usuario (cargado desde BD)
        final userRole = authProvider.currentUser?.role.toString().split('.').last ?? 'student';"""

new = """        // Si es usuario nuevo (sin perfil), redirigir a completar perfil
        if (authProvider.isNewUser) {
          final userId = authProvider.currentUser?.id ?? '';
          final userEmail = authProvider.currentUser?.email ?? _emailController.text.trim();
          context.go('/complete-profile?userId=\$userId&email=\${Uri.encodeComponent(userEmail)}');
          return;
        }

        // Redirigir según el rol del usuario (cargado desde BD)
        final userRole = authProvider.currentUser?.role.toString().split('.').last ?? 'student';"""

if old in content:
    content = content.replace(old, new)
    with open(r'c:\Users\HP\Desktop\convive_\lib\screens\login_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("OK - Replacement done")
else:
    # Try with \r\n
    old_crlf = old.replace('\n', '\r\n')
    new_crlf = new.replace('\n', '\r\n')
    if old_crlf in content:
        content = content.replace(old_crlf, new_crlf)
        with open(r'c:\Users\HP\Desktop\convive_\lib\screens\login_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("OK - Replacement done (CRLF)")
    else:
        print("ERROR - Target not found")
        # Debug: show what's around line 473
        lines = content.split('\n')
        for i in range(470, min(485, len(lines))):
            print(f"  L{i+1}: {repr(lines[i])}")
