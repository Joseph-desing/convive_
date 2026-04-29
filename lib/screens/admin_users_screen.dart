import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';

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
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredUsers = _filterUsers(adminProvider.allUsers);

          return Column(
            children: [
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
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por email...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.users, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getRoleLabel(role),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(role),
                    ),
                  ),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCompactActionButton(
                        icon: FontAwesomeIcons.wrench,
                        label: 'Editar',
                        color: Colors.blue.shade600,
                        onPressed: () => _showEditUserDialog(context, user),
                      ),
                      const SizedBox(width: 6),
                      _buildCompactActionButton(
                        icon: FontAwesomeIcons.envelope,
                        label: 'Mensaje',
                        color: Colors.purple.shade600,
                        onPressed: () => _showMessageDialog(context, user),
                      ),
                      const SizedBox(width: 6),
                      _buildCompactActionButton(
                        icon: isSuspended
                            ? FontAwesomeIcons.checkCircle
                            : FontAwesomeIcons.ban,
                        label: isSuspended ? 'Activar' : 'Suspender',
                        color: isSuspended ? Colors.green.shade600 : Colors.red.shade600,
                        onPressed: () {
                          adminProvider.suspendUser(user['id'], !isSuspended);
                        },
                      ),
                    ],
                  ),
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
              length: 2,
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
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.shield, size: 16),
                              const SizedBox(width: 8),
                              const Text('Rol', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.circleUser, size: 16),
                              const SizedBox(width: 8),
                              const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade400,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const FaIcon(
                                        FontAwesomeIcons.envelope,
                                        color: Colors.white,
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
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
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
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
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
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
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
                              TextField(
                                controller: bioController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Escribe algo sobre ti...',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: FaIcon(
                                      FontAwesomeIcons.penToSquare,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Toggle Verificado
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isVerified ? Colors.green[50] : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isVerified ? Colors.green[300]! : Colors.grey[300]!,
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
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(FontAwesomeIcons.xmark, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                            onPressed: () async {
                              // Actualizar rol
                              context.read<AdminProvider>().updateUserRole(user['id'], selectedRole);

                              // Actualizar perfil
                              if (profile != null) {
                                await SupabaseProvider.databaseService.updateProfile(
                                  profile['id'],
                                  {
                                    'full_name': fullNameController.text,
                                    'bio': bioController.text,
                                    'gender': selectedGender,
                                    'birth_date': selectedBirthDate?.toIso8601String(),
                                    'verified': isVerified,
                                  },
                                );
                              }

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
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Guardar Cambios',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: FaIcon(
          icon,
          size: 14,
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(FontAwesomeIcons.envelope, 
                    color: Colors.red.shade600, 
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['email'] ?? 'Usuario',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                        backgroundColor: entry.key == 'other'
                            ? Colors.grey[200]
                            : entry.key == 'violencia'
                                ? Colors.red[50]
                                : entry.key == 'fraude'
                                    ? Colors.orange[50]
                                    : Colors.blue[50],
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            selectedReason = entry.key;
                            messageController.text = entry.value;
                          });
                        },
                        selectedColor: entry.key == 'violencia'
                            ? Colors.red.shade600
                            : entry.key == 'fraude'
                                ? Colors.orange.shade600
                                : Colors.blue.shade600,
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
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300, width: 2),
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
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1.5),
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
                              '📧 Email será enviado',
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
          TextButton.icon(
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
            label: const Text('Enviar Notificación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Escribe un mensaje'),
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
                      content: const Text('✅ Notificación enviada al usuario'),
                      backgroundColor: Colors.green.shade600,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
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
        return 'No Estudiante';
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
}
