import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../utils/colors.dart';
import '../widgets/admin/admin_ui.dart';
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
      backgroundColor: AdminUi.background,
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.shieldHalved, size: 20, color: Colors.white),
            SizedBox(width: 12),
            Text('Panel de Administración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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

              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 14),
                    if (adminProvider.errorMessage != null) ...[
                      _buildErrorCard(adminProvider.errorMessage!),
                      const SizedBox(height: 10),
                    ],
                    Expanded(child: _buildStatsSection(context, adminProvider)),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AdminUi.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          iconSize: 18,
          currentIndex: _currentTabIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AdminUi.muted,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house, size: 18),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.users, size: 18),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.building, size: 18),
              label: 'Posts',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.comments, size: 18),
              label: 'Quejas',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.user, size: 18),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: FaIcon(FontAwesomeIcons.chartLine, color: AppColors.primary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de control',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AdminUi.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Monitorea usuarios, publicaciones y reportes desde un solo lugar.',
                  style: TextStyle(fontSize: 12, color: AdminUi.muted, height: 1.25),
                ),
              ],
            ),
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
            fontWeight: FontWeight.w900,
            color: AdminUi.ink,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
              title: 'Departamentos ',
              value: '${stats['properties']?['total'] ?? 0}',
              subtitle: 'Publicados',
              icon: FontAwesomeIcons.building,
              color: Colors.orange,
            ),
            // Roomies
            _buildStatCard(
              title: 'Roomies',
              value: '${stats['roommateSearches']?['total'] ?? 0}',
              subtitle: 'Activos',
              icon: FontAwesomeIcons.handshake,
              color: Colors.purple,
            ),
            // Quejas/Sugerencias
                  _buildStatCard(
                    title: 'Quejas',
                    value: '${stats['feedback']?['total'] ?? 0}',
                    subtitle: 'Pendientes',
              icon: FontAwesomeIcons.comments,
              color: Colors.red,
            ),
            ],
          ),
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
    return Container(
      decoration: AdminUi.panelDecoration(),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: FaIcon(icon, size: 17, color: color)),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AdminUi.muted,
            ),
          ),
        ],
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
