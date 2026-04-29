import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos DESPUÉS del build usando microtask
    Future.microtask(() {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  void _loadDashboardData() {
    if (!mounted) return;
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.shieldHalved, size: 20, color: Colors.white),
            SizedBox(width: 12),
            Text('Panel de Administración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rotate, size: 18),
            onPressed: _loadDashboardData,
            tooltip: 'Recargar datos',
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 18),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildWelcomeCard(context),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsSection(context, adminProvider),
                const SizedBox(height: 24),

                // Management Sections
                _buildManagementSections(context),
                const SizedBox(height: 24),

                // Error Message
                if (adminProvider.errorMessage != null)
                  _buildErrorCard(adminProvider.errorMessage!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.userTie,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bienvenido Administrador',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildStatsSection(BuildContext context, AdminProvider adminProvider) {
    final stats = adminProvider.dashboardStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas Generales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.65,
          children: [
            // Usuarios totales
            _buildStatCard(
              title: 'Usuarios',
              value: '${stats['users']?['total'] ?? 0}',
              subtitle: 'Registrados',
              icon: FontAwesomeIcons.users,
              color: Colors.blue,
            ),
            // Departamentos
            _buildStatCard(
              title: 'Departamentos',
              value: '${stats['properties']?['total'] ?? 0}',
              subtitle: 'Publicaciones',
              icon: FontAwesomeIcons.building,
              color: Colors.orange,
            ),
            // Roomies
            _buildStatCard(
              title: 'Roomies',
              value: '${stats['roommateSearches']?['total'] ?? 0}',
              subtitle: 'Búsquedas activas',
              icon: FontAwesomeIcons.handshake,
              color: Colors.purple,
            ),
            // Quejas/Sugerencias
            _buildStatCard(
              title: 'Feedback',
              value: '${stats['feedback']?['total'] ?? 0}',
              subtitle: 'Total',
              icon: FontAwesomeIcons.comments,
              color: Colors.red,
            ),
            // Pendientes
            _buildStatCard(
              title: 'Pendientes',
              value: '${(stats['feedback']?['open'] ?? 0) + (stats['properties']?['inactive'] ?? 0) + (stats['roommateSearches']?['inactive'] ?? 0)}',
              subtitle: 'Por revisar',
              icon: FontAwesomeIcons.exclamation,
              color: Colors.amber,
            ),
            // Quejas Solucionadas
            _buildStatCard(
              title: 'Quejas',
              value: '${stats['feedback']?['resolved'] ?? 0}',
              subtitle: 'Solucionadas',
              icon: FontAwesomeIcons.checkCircle,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildManagementButton(
          context,
          title: 'Gestión de Usuarios',
          description: 'Administra roles y suspensiones de usuarios',
          icon: FontAwesomeIcons.users,
          color: Colors.blue,
          onPressed: () => context.push('/admin/users'),
        ),
        const SizedBox(height: 12),
        _buildManagementButton(
          context,
          title: 'Gestión de Departamentos y Roomies',
          description: 'Revisa y administra publicaciones de propiedades',
          icon: FontAwesomeIcons.building,
          color: Colors.orange,
          onPressed: () => context.push('/admin/properties'),
        ),
        const SizedBox(height: 12),
        _buildManagementButton(
          context,
          title: 'Gestión de Quejas/Sugerencias',
          description: 'Responde a comentarios y reportes de usuarios',
          icon: FontAwesomeIcons.comments,
          color: Colors.red,
          onPressed: () => context.push('/admin/feedback'),
        ),
      ],
    );
  }

  Widget _buildManagementButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FaIcon(icon, size: 28, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              context.go('/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
