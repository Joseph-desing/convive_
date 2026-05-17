with open(r'c:\Users\HP\Desktop\convive_\lib\screens\complete_profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the exact block to replace
old_block = """  void _prefillIfEditing() {
    final profile = widget.existingProfile;
    final habits = widget.existingHabits;
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _bioController.text = profile.bio ?? '';
      _birthDate = profile.birthDate;
      _gender = profile.gender;
      _currentImageUrl = profile.profileImageUrl;
    }
    if (habits != null) {"""

new_block = """  void _prefillIfEditing() {
    final profile = widget.existingProfile;
    final habits = widget.existingHabits;
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _bioController.text = profile.bio ?? '';
      _birthDate = profile.birthDate;
      _gender = profile.gender;
      _currentImageUrl = profile.profileImageUrl;
    } else {
      // Usuario nuevo: cargar nombre desde public.users
      _loadFullNameFromUser();
    }
    if (habits != null) {"""

new_method = """
  /// Pre-rellena el nombre desde public.users (para usuarios nuevos)
  Future<void> _loadFullNameFromUser() async {
    try {
      final user = await SupabaseProvider.databaseService.getUser(widget.userId);
      if (user != null && (user.fullName?.isNotEmpty ?? false)) {
        if (mounted) setState(() => _fullNameController.text = user.fullName!);
      }
    } catch (e) {
      final authUser = SupabaseProvider.authService.getCurrentUser();
      final fullName = authUser?.userMetadata?['full_name'] as String? ?? '';
      if (fullName.isNotEmpty && mounted) {
        setState(() => _fullNameController.text = fullName);
      }
    }
  }

  Future<void> _loadUserRole() async {"""

# Try LF first
found = False
if old_block in content:
    content = content.replace(old_block, new_block, 1)
    # Now add _loadFullNameFromUser before _loadUserRole
    content = content.replace(
        "\n  Future<void> _loadUserRole() async {",
        new_method,
        1
    )
    found = True
    print("Done (LF)")
else:
    # Try CRLF
    old_crlf = old_block.replace('\n', '\r\n')
    new_crlf = new_block.replace('\n', '\r\n')
    if old_crlf in content:
        content = content.replace(old_crlf, new_crlf, 1)
        new_method_crlf = new_method.replace('\n', '\r\n')
        content = content.replace(
            "\r\n  Future<void> _loadUserRole() async {",
            new_method_crlf,
            1
        )
        found = True
        print("Done (CRLF)")

if found:
    with open(r'c:\Users\HP\Desktop\convive_\lib\screens\complete_profile_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("File saved.")
else:
    print("ERROR - Target block not found")
    # Debug: show around _prefillIfEditing
    for i, line in enumerate(content.split('\n')):
        if '_prefillIfEditing' in line:
            start = max(0, i-1)
            end = min(len(content.split('\n')), i+15)
            for j, l in enumerate(content.split('\n')[start:end], start+1):
                print(f"  {j}: {repr(l)}")
            break
