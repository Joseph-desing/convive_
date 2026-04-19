import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../utils/colors.dart';

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'Todos'),
            const SizedBox(width: 8),
            _buildFilterChip('student', 'Estudiante'),
            const SizedBox(width: 8),
            _buildFilterChip('non_student', 'No Estudiante'),
            const SizedBox(width: 8),
            _buildFilterChip('admin', 'Administrador'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        _loadUsers();
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registrado: ${createdAt?.split('T').first ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      icon: FontAwesomeIcons.wrench,
                      label: 'Editar',
                      color: Colors.blue.shade600,
                      onPressed: () => _showEditUserDialog(context, user),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
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

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${user['email']}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Estudiante')),
                DropdownMenuItem(
                    value: 'non_student', child: Text('No Estudiante')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (value) => selectedRole = value ?? 'student',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().updateUserRole(user['id'], selectedRole);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
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
