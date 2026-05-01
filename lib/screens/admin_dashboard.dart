import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import 'admin_users_screen.dart';
import 'admin_properties_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTabIndex = 0;

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
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // Tab 0: Home/Dashboard
          Consumer<AdminProvider>(
            builder: (context, adminProvider, _) {
              if (adminProvider.isLoading && _currentTabIndex == 0) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    _buildStatsSection(context, adminProvider),
                    const SizedBox(height: 24),

                    // Error Message
                    if (adminProvider.errorMessage != null)
                      _buildErrorCard(adminProvider.errorMessage!),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
          // Tab 1: Usuarios
          const AdminUsersScreen(),
          // Tab 2: Propiedades y Roomies
          const AdminPropertiesScreen(),
          // Tab 3: Quejas/Sugerencias
          const AdminFeedbackScreen(),
          // Tab 4: Perfil
          const AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[400],
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.users),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.building),
            label: 'Depart.',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.comments),
            label: 'Quejas',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user),
            label: 'Perfil',
          ),
        ],
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
          childAspectRatio: 1.0,
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
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
}
