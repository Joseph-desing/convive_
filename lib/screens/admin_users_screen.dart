import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../utils/colors.dart';
import '../widgets/admin/admin_ui.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedFilter = 'all';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar usuarios DESPUÉS del build
    Future.microtask(() {
      if (mounted) {
        _loadUsers();
      }
    });
  }

  void _loadUsers() {
    if (!mounted) return;
    final adminProvider = context.read<AdminProvider>();
    if (_selectedFilter == 'all') {
      adminProvider.loadAllUsers();
    } else {
      adminProvider.loadUsersByRole(_selectedFilter);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUi.background,
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredUsers = _filterUsers(adminProvider.allUsers);

          return Column(
            children: [
              const AdminSectionHeader(
                title: 'Usuarios',
                subtitle: 'Gestiona roles, suspensiones y comunicaciones.',
                icon: FontAwesomeIcons.users,
              ),
              // Filtros
              _buildFiltersSection(),
              // Búsqueda
              _buildSearchBar(),
              // Lista de usuarios
              Expanded(
                child: filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(context, user, adminProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: AdminUi.panelDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: Colors.white,
          icon: const FaIcon(
            FontAwesomeIcons.chevronDown,
            size: 16,
            color: AppColors.primary,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.users, size: 14, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Todos'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'student',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.graduationCap, size: 14, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Estudiante'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'non_student',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.building, size: 14, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Propietario'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedFilter = value);
              _loadUsers();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        decoration: AdminUi.inputDecoration(hintText: 'Buscar por email o nombre...'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AdminEmptyState(
      icon: FontAwesomeIcons.users,
      title: 'No hay usuarios',
      subtitle: 'Cambia el filtro o intenta otra busqueda.',
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> user,
    AdminProvider adminProvider,
  ) {
    final email = user['email'] ?? 'Sin email';
    final role = user['role'] ?? 'student';
    final isSuspended = user['is_suspended'] ?? false;
    final createdAt = user['created_at'];
    final profile = user['profiles'] is List && (user['profiles'] as List).isNotEmpty
        ? user['profiles'][0]
        : null;
    final userName = profile?['full_name'] ?? email;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AdminUi.panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AdminStatusChip(
                  label: _getRoleLabel(role),
                  color: _getRoleColor(role),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isSuspended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SUSPENDIDO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrado: ${createdAt?.split('T').first ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminActionButton(
                      icon: FontAwesomeIcons.wrench,
                      label: 'Editar',
                      color: Colors.blue.shade600,
                      onPressed: () => _showEditUserDialog(context, user),
                    ),
                    AdminActionButton(
                      icon: FontAwesomeIcons.envelope,
                      label: 'Mensaje',
                      color: Colors.purple.shade600,
                      onPressed: () => _showMessageDialog(context, user),
                    ),
                    AdminActionButton(
                      icon: isSuspended
                          ? FontAwesomeIcons.checkCircle
                          : FontAwesomeIcons.ban,
                      label: isSuspended ? 'Activar' : 'Suspender',
                      color: isSuspended ? Colors.green.shade600 : Colors.red.shade600,
                      onPressed: () {
                        _showSuspendConfirmationDialog(context, user, adminProvider, isSuspended);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return ElevatedButton.icon(
      icon: FaIcon(icon, size: 12, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 36),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return ElevatedButton.icon(
      icon: FaIcon(icon, size: 11, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: const Size(0, 32),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final profile = user['profiles'] is List && (user['profiles'] as List).isNotEmpty
        ? user['profiles'][0]
        : null;

    String selectedRole = user['role'] ?? 'student';
    TextEditingController fullNameController = TextEditingController(text: profile?['full_name'] ?? '');
    TextEditingController bioController = TextEditingController(text: profile?['bio'] ?? '');
    String selectedGender = profile?['gender'] ?? 'other';
    DateTime? selectedBirthDate = profile?['birth_date'] != null ? DateTime.parse(profile?['birth_date']) : null;
    bool isVerified = profile?['verified'] ?? false;
    final showProfileTab = false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) => DefaultTabController(
              length: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.wrench,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar Usuario',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Actualiza la información del usuario',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TABBAR
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey[500],
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 4,
                      labelPadding: const EdgeInsets.symmetric(vertical: 16),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.shield, size: 16),
                              SizedBox(width: 8),
                              Text('Rol', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TABBAR VIEW
                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1: ROL
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AdminUi.panelDecoration(
                                  borderColor: Colors.blue.shade200,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const FaIcon(
                                        FontAwesomeIcons.envelope,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] ?? 'Sin email',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Rol Label
                              Text(
                                'Selecciona un Rol',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Rol Dropdown
                              Container(
                                decoration: AdminUi.panelDecoration(
                                  borderColor: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                child: DropdownButton<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  dropdownColor: Colors.white,
                                  icon: const FaIcon(
                                    FontAwesomeIcons.chevronDown,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'student',
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const FaIcon(
                                              FontAwesomeIcons.graduationCap,
                                              size: 14,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text('Estudiante'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'non_student',
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const FaIcon(
                                              FontAwesomeIcons.building,
                                              size: 14,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text('Propietario'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => selectedRole = value ?? 'student');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TAB 2: PERFIL
                        if (showProfileTab)
                          SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre
                              _buildFieldLabel('Nombre Completo'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                fullNameController,
                                'Ej: Juan Pérez',
                                FontAwesomeIcons.user,
                              ),
                              const SizedBox(height: 16),

                              // Fecha de Nacimiento
                              _buildFieldLabel('Fecha de Nacimiento'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedBirthDate ?? DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => selectedBirthDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: _dialogFieldBoxDecoration(),
                                  child: Row(
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.calendar,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          selectedBirthDate != null
                                              ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
                                              : 'Selecciona una fecha',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: selectedBirthDate != null ? Colors.black : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                      const FaIcon(
                                        FontAwesomeIcons.chevronDown,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Género
                              _buildFieldLabel('Género'),
                              const SizedBox(height: 8),
                              Container(
                                decoration: _dialogFieldBoxDecoration(),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                child: DropdownButton<String>(
                                  value: selectedGender,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  dropdownColor: Colors.white,
                                  icon: const FaIcon(
                                    FontAwesomeIcons.chevronDown,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.mars, size: 12, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Hombre'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.venus, size: 12, color: Colors.pink),
                                          SizedBox(width: 8),
                                          Text('Mujer'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'other',
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.circle, size: 12, color: Colors.purple),
                                          SizedBox(width: 8),
                                          Text('Otro'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => selectedGender = value ?? 'other');
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Biografía
                              _buildFieldLabel('Sobre mí'),
                              const SizedBox(height: 8),
                              Container(
                                decoration: _dialogFieldBoxDecoration(),
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: FaIcon(
                                        FontAwesomeIcons.penToSquare,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: bioController,
                                        maxLines: 4,
                                        decoration: const InputDecoration(
                                          hintText: 'Escribe algo sobre ti...',
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Toggle Verificado
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isVerified ? Colors.green.shade300 : AdminUi.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isVerified ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: FaIcon(
                                            FontAwesomeIcons.checkCircle,
                                            size: 14,
                                            color: isVerified ? Colors.green : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Verificado',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: isVerified,
                                      onChanged: (value) {
                                        setState(() => isVerified = value);
                                      },
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BOTONES
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminUi.ink,
                              backgroundColor: const Color(0xFFF3F4F6),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 14),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              // Actualizar rol
                              context.read<AdminProvider>().updateUserRole(user['id'], selectedRole);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        FaIcon(FontAwesomeIcons.checkCircle, color: Colors.white, size: 18),
                                        SizedBox(width: 10),
                                        Text('✅ Usuario actualizado correctamente'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade500,
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                // Recargar usuarios
                                context.read<AdminProvider>().loadAllUsers();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
        letterSpacing: 0.5,
      ),
    );
  }

  OutlineInputBorder _dialogInputBorder({
    Color color = AdminUi.border,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  BoxDecoration _dialogFieldBoxDecoration({
    Color borderColor = AdminUi.border,
    Color fillColor = Colors.white,
  }) {
    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Center(
          widthFactor: 1,
          child: FaIcon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 42,
        ),
        enabledBorder: _dialogInputBorder(),
        border: _dialogInputBorder(),
        focusedBorder: _dialogInputBorder(
          color: AppColors.primary,
          width: 1.6,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context, Map<String, dynamic> user) {
    final TextEditingController messageController = TextEditingController();
    String selectedReason = 'other';
    
    final reasonTemplates = {
      'violencia': '🚨 Violencia o comportamiento agresivo detectado en tu perfil/mensajes.',
      'fraude': '⚠️ Se detectó comportamiento fraudulento o engañoso en tu cuenta.',
      'inapropiado': '📛 Contenido inapropiado o ofensivo en tu perfil.',
      'spam': '🔔 Comportamiento de spam o abuso reiterado.',
      'verificacion': '🔍 Tu cuenta ha sido suspendida pendiente de verificación.',
      'other': '',
    };
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.84)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(FontAwesomeIcons.envelope,
                    color: Colors.white,
                    size: 20
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notificar Suspensión',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['email'] ?? 'Usuario',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Razones predefinidas
                Text(
                  'Motivo de la suspensión:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setState) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasonTemplates.entries.map((entry) {
                      final isSelected = selectedReason == entry.key;
                      return FilterChip(
                        label: Text(
                          entry.key == 'other' ? 'Personalizado' : entry.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : AdminUi.ink,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.08),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AdminUi.border,
                        ),
                        checkmarkColor: AppColors.primary,
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            selectedReason = entry.key;
                            messageController.text = entry.value;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo de mensaje
                Text(
                  'Detalles adicionales:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Agrega detalles específicos sobre la suspensión...',
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: _dialogInputBorder(),
                    border: _dialogInputBorder(),
                    focusedBorder: _dialogInputBorder(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 14),
                
                // Info importante
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AdminUi.panelDecoration(
                    borderColor: Colors.blue.shade200,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.email_rounded,
                        color: Colors.blue[700],
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email será enviado',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'El usuario recibirá una notificación en su correo con los detalles de la suspensión.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                    label: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminUi.ink,
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
                    label: const Text('Enviar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
              if (messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Escribe un mensaje'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Enviar mensaje a través del AdminProvider
                await context.read<AdminProvider>().sendMessageToUser(
                  userId: user['id'],
                  email: user['email'],
                  message: messageController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notificación enviada al usuario'),
                      backgroundColor: Colors.green.shade600,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  final errorText = e.toString().replaceFirst('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorText),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 6),
                    ),
                  );
                }
              }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'student':
        return Colors.blue;
      case 'non_student':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'student':
        return 'Estudiante';
      case 'non_student':
        return 'Propietario';
      default:
        return 'Desconocido';
    }
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    if (_searchController.text.isEmpty) {
      return users;
    }
    final query = _searchController.text.toLowerCase();
    return users
        .where((user) =>
            (user['email']?.toLowerCase().contains(query) ?? false) ||
            (user['profiles'] is List &&
                (user['profiles'] as List).isNotEmpty &&
                (user['profiles'][0]['full_name']
                        ?.toLowerCase()
                        .contains(query) ??
                    false)))
        .toList();
  }

  void _showSuspendConfirmationDialog(BuildContext context, Map<String, dynamic> user, AdminProvider adminProvider, bool isSuspended) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono grande en la parte superior
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.84)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        isSuspended ? FontAwesomeIcons.checkCircle : FontAwesomeIcons.ban,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isSuspended ? 'Activar usuario' : 'Suspender usuario',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Título principal
              Text(
                isSuspended
                    ? 'Quieres activar esta cuenta?'
                    : 'Quieres suspender esta cuenta?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AdminUi.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Contenedor con el email y descripción
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AdminUi.panelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuario:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user['email'] ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción
              Text(
                isSuspended 
                  ? 'Este usuario podra acceder nuevamente a la plataforma.'
                  : 'Este usuario no podra acceder a su cuenta hasta que sea reactivado.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminUi.muted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                      label: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminUi.ink,
                        backgroundColor: const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        adminProvider.suspendUser(user['id'], !isSuspended);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSuspended
                                ? '✅ Usuario activado correctamente'
                                : '✅ Usuario suspendido correctamente',
                            ),
                            backgroundColor: Colors.green.shade600,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: isSuspended ? Colors.green.shade600 : Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSuspended ? 'Activar' : 'Suspender',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

