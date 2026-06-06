import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../models/property.dart';
import '../models/roommate_search.dart';
import '../models/user.dart' as convive_user;
import '../providers/auth_provider.dart';
import '../config/supabase_provider.dart';
import 'create_property_screen.dart';
import 'create_roommate_search_screen.dart';

String _publicationStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return 'Aprobada';
    case 'inactive':
      return 'Rechazada';
    case 'pending':
    default:
      return 'Pendiente';
  }
}

Color _publicationStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Colors.green;
    case 'inactive':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}

IconData _publicationStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Icons.check_circle_outline_rounded;
    case 'inactive':
      return Icons.cancel_outlined;
    case 'pending':
    default:
      return Icons.schedule_rounded;
  }
}

Widget _buildPublicationStatusBadge(String status) {
  final color = _publicationStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withOpacity(0.28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_publicationStatusIcon(status), size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          _publicationStatusLabel(status),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class MyPublicationsScreen extends StatefulWidget {
  const MyPublicationsScreen({Key? key}) : super(key: key);

  @override
  State<MyPublicationsScreen> createState() => _MyPublicationsScreenState();
}

class _MyPublicationsScreenState extends State<MyPublicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Property> _properties = [];
  List<RoommateSearch> _searches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPublications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPublications() async {
    final authProvider = context.read<AuthProvider>();
    // Si no hay usuario, no intentar cargar; mostrar estado vacío en lugar
    // de dejar el spinner bloqueado.
    if (authProvider.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = authProvider.currentUser!.id;
      final properties =
          await SupabaseProvider.databaseService.getUserProperties(userId);
      final searches = await SupabaseProvider.databaseService
          .getUserRoommateSearches(userId);

      setState(() {
        _properties = properties;
        _searches = searches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando publicaciones: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Verifica si el usuario actual es estudiante y ya tiene al menos 1 propiedad.
  bool get _isStudentAtPropertyLimit {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return false;
    return user.role == convive_user.UserRole.student && _properties.isNotEmpty;
  }

  /// Consulta fresca a Supabase para validar el límite antes de navegar.
  Future<bool> _checkStudentPropertyLimitFresh() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return false;
    if (user.role != convive_user.UserRole.student)
      return false; // no es student → sin límite

    try {
      final freshProps =
          await SupabaseProvider.databaseService.getUserProperties(user.id);
      return freshProps.isNotEmpty; // true = at limit
    } catch (_) {
      // Si falla la consulta, usar los datos locales
      return _properties.isNotEmpty;
    }
  }

  void _showStudentLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 48),
        title: const Text(
          'No puedes publicar más departamentos',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Lo sentimos, como estudiante solo puedes publicar un departamento.\n\n'
          'Para publicar más, comunícate con administración y solicita el cambio de rol a propietario.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Entendido',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(String propertyId) async {
    try {
      await SupabaseProvider.databaseService.deleteProperty(propertyId);
      setState(() {
        _properties.removeWhere((p) => p.id == propertyId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propiedad eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _togglePropertyRented(Property property) async {
    final nextValue = !property.isRented;

    try {
      await SupabaseProvider.databaseService.updatePropertyRentedStatus(
        property.id,
        nextValue,
      );

      if (!mounted) return;
      setState(() {
        final index = _properties.indexWhere((p) => p.id == property.id);
        if (index != -1) {
          _properties[index] = _properties[index].copyWith(
            isRented: nextValue,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Departamento marcado como alquilado'
                : 'Departamento marcado como no alquilado',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editProperty(Property property) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePropertyScreen(property: property),
      ),
    );

    if (updated == true) {
      await _loadPublications();
    }
  }

  Future<void> _deleteSearch(String searchId) async {
    try {
      await SupabaseProvider.databaseService.deleteRoommateSearch(searchId);
      setState(() {
        _searches.removeWhere((s) => s.id == searchId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Búsqueda eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _editSearch(RoommateSearch search) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRoommateSearchScreen(search: search),
      ),
    );

    if (updated == true) {
      await _loadPublications();
    }
  }

  void _showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar $title?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Publicaciones',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, size: 28),
                onPressed: () => _showPublishMenu(context),
                tooltip: 'Publicar nuevo',
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              tabs: const [
                Tab(text: 'Propiedades'),
                Tab(text: 'Búsquedas'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPropertiesTab(),
                  _buildSearchesTab(),
                ],
              ),
      ),
    );
  }

  /// Banner de alerta para estudiantes que alcanzaron el límite de 1 propiedad.
  Widget _buildStudentLimitBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Como estudiante solo puedes publicar un departamento. '
              'Si quieres publicar más departamentos, comunícate con '
              'administración para cambiar tu rol a propietario.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange[900],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab() {
    if (_properties.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    size: 80,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aún no has publicado propiedades',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparte tu propiedad para alquilar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateProperty(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Publicar Propiedad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Banner de alerta si es estudiante con propiedad existente
        if (_isStudentAtPropertyLimit) _buildStudentLimitBanner(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 360 ? 8 : 16,
              12,
              MediaQuery.sizeOf(context).width < 360 ? 8 : 16,
              24,
            ),
            itemCount: _properties.length,
            itemBuilder: (context, index) {
              final property = _properties[index];
              return _PropertyCard(
                property: property,
                onDelete: () => _showDeleteConfirmation(
                  context,
                  title: 'esta propiedad',
                  onConfirm: () => _deleteProperty(property.id),
                ),
                onEdit: () => _editProperty(property),
                onToggleRented: () => _togglePropertyRented(property),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchesTab() {
    if (_searches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 80,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no has publicado búsquedas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca el compañero/a de cuarto perfecto',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showPublishMenu(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buscar Roommate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 360 ? 8 : 16,
        12,
        MediaQuery.sizeOf(context).width < 360 ? 8 : 16,
        24,
      ),
      itemCount: _searches.length,
      itemBuilder: (context, index) {
        final search = _searches[index];
        return _SearchCard(
          search: search,
          onDelete: () => _showDeleteConfirmation(
            context,
            title: 'esta búsqueda',
            onConfirm: () => _deleteSearch(search.id ?? ''),
          ),
          onEdit: () => _editSearch(search),
        );
      },
    );
  }

  /// Navegar a crear propiedad con validación de límite para estudiantes.
  Future<void> _navigateToCreateProperty() async {
    // Consulta fresca al backend para verificar el límite
    final atLimit = await _checkStudentPropertyLimitFresh();
    if (!mounted) return;
    if (atLimit) {
      _showStudentLimitDialog();
      return;
    }

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePropertyScreen(),
      ),
    );
    if (created == true && mounted) {
      await _loadPublications();
    }
  }

  void _showPublishMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Qué quieres publicar?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              context,
              icon: Icons.home_work,
              title: 'Publicar Propiedad',
              description: 'Tengo un cuarto para alquilar',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
              onTap: () async {
                Navigator.pop(context);
                await _navigateToCreateProperty();
              },
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              context,
              icon: Icons.group_add,
              title: 'Buscar Roommate',
              description: 'Necesito un compañero/a',
              gradient: AppColors.primaryGradient,
              onTap: () async {
                Navigator.pop(context);
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRoommateSearchScreen(),
                  ),
                );
                if (created == true && mounted) {
                  await _loadPublications();
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card para mostrar una propiedad
class _PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleRented;

  const _PropertyCard({
    required this.property,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleRented,
  });

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: EdgeInsets.symmetric(
          vertical: compact ? 8 : 10,
          horizontal: compact ? 0 : 4,
        ),
        elevation: _isHovered ? 12 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF1E1E1E),
                      const Color(0xFF1A1A1A),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withOpacity(0.98),
                    ],
            ),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
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
                            widget.property.title,
                            style: TextStyle(
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.property.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildPublicationStatusBadge(
                            widget.property.status,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: AppColors.primary,
                              size: compact ? 18 : 20,
                            ),
                            onPressed: widget.onEdit,
                            tooltip: 'Editar',
                            iconSize: compact ? 18 : 20,
                            padding: const EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: compact ? 36 : 40,
                              minHeight: compact ? 36 : 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                              size: compact ? 18 : 20,
                            ),
                            onPressed: widget.onDelete,
                            tooltip: 'Eliminar',
                            iconSize: compact ? 18 : 20,
                            padding: const EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: compact ? 36 : 40,
                              minHeight: compact ? 36 : 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${widget.property.price}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Text(
                              '/mes',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.15),
                              Colors.blue.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${widget.property.availableFrom.day}/${widget.property.availableFrom.month}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onToggleRented,
                    icon: Icon(
                      widget.property.isRented
                          ? Icons.home_work_outlined
                          : Icons.event_available_rounded,
                      size: 18,
                    ),
                    label: Text(
                      widget.property.isRented
                          ? 'Marcar como no alquilado'
                          : 'Marcar como alquilado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.property.isRented
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      side: BorderSide(
                        color: widget.property.isRented
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                      ),
                      backgroundColor: widget.property.isRented
                          ? Colors.green.withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card para mostrar una búsqueda de compañero
class _SearchCard extends StatefulWidget {
  final RoommateSearch search;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SearchCard({
    required this.search,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard> {
  bool _isHovered = false;

  String _genderLabel(String? value) {
    switch (value) {
      case 'male':
        return 'Hombre';
      case 'female':
        return 'Mujer';
      case 'any':
        return 'Sin preferencia';
      default:
        return 'Sin preferencia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: EdgeInsets.symmetric(
          vertical: compact ? 8 : 10,
          horizontal: compact ? 0 : 4,
        ),
        elevation: _isHovered ? 12 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF1E1E1E),
                      const Color(0xFF1A1A1A),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withOpacity(0.98),
                    ],
            ),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
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
                            'Busco compañero/a',
                            style: TextStyle(
                              fontSize: compact ? 15 : 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.secondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.search.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildPublicationStatusBadge(widget.search.status),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: AppColors.secondary,
                              size: compact ? 18 : 20,
                            ),
                            onPressed: widget.onEdit,
                            tooltip: 'Editar',
                            iconSize: compact ? 18 : 20,
                            padding: const EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: compact ? 36 : 40,
                              minHeight: compact ? 36 : 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                              size: compact ? 18 : 20,
                            ),
                            onPressed: widget.onDelete,
                            tooltip: 'Eliminar',
                            iconSize: compact ? 18 : 20,
                            padding: const EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              minWidth: compact ? 36 : 40,
                              minHeight: compact ? 36 : 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withOpacity(0.15),
                              AppColors.secondary.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Max: ${widget.search.budget.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 12 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.search.genderPreference != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.15),
                                Colors.green.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _genderLabel(widget.search.genderPreference),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
