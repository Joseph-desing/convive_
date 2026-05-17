with open(r'c:\Users\HP\Desktop\convive_\lib\main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

changes = 0

# 1. Add import for CompleteProfileScreen
import_target = "import 'screens/login_screen.dart';"
import_replacement = "import 'screens/login_screen.dart';\nimport 'screens/complete_profile_screen.dart';"
if 'complete_profile_screen.dart' not in content:
    content = content.replace(import_target, import_replacement)
    changes += 1
    print("1. Import added")
else:
    print("1. Import already exists")

# 2. Add /complete-profile route (after /welcome route)
route_target = "        GoRoute(\n          path: '/welcome',\n          builder: (context, state) => const WelcomeScreen(),\n        ),"
route_replacement = """        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) {
            final userId = state.uri.queryParameters['userId'] ?? '';
            final email = state.uri.queryParameters['email'] ?? '';
            return CompleteProfileScreen(userId: userId, email: email);
          },
        ),"""

if '/complete-profile' not in content:
    if route_target in content:
        content = content.replace(route_target, route_replacement)
        changes += 1
        print("2. Route added (LF)")
    else:
        route_target_crlf = route_target.replace('\n', '\r\n')
        route_replacement_crlf = route_replacement.replace('\n', '\r\n')
        if route_target_crlf in content:
            content = content.replace(route_target_crlf, route_replacement_crlf)
            changes += 1
            print("2. Route added (CRLF)")
        else:
            print("2. ERROR - Route target not found")
else:
    print("2. Route already exists")

# 3. Add /complete-profile to the list of allowed routes without session
redirect_target = "            location == '/email-confirmed') {"
redirect_replacement = "            location == '/email-confirmed' ||\n            location.startsWith('/complete-profile')) {"

if '/complete-profile' not in content.split('redirect')[0] if 'redirect' in content else '':
    if redirect_target in content:
        content = content.replace(redirect_target, redirect_replacement)
        changes += 1
        print("3. Redirect rule added (LF)")
    else:
        redirect_target_crlf = redirect_target.replace('\n', '\r\n')
        redirect_replacement_crlf = redirect_replacement.replace('\n', '\r\n')
        if redirect_target_crlf in content:
            content = content.replace(redirect_target_crlf, redirect_replacement_crlf)
            changes += 1
            print("3. Redirect rule added (CRLF)")
        else:
            print("3. ERROR - Redirect target not found")

if changes > 0:
    with open(r'c:\Users\HP\Desktop\convive_\lib\main.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"\nDone! {changes} changes applied.")
else:
    print("\nNo changes needed.")
