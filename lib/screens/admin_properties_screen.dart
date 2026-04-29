import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/admin_provider.dart';
import '../utils/colors.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({Key? key}) : super(key: key);

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _selectedRoommateFilter = 'all';
  TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar propiedades DESPUÉS del build
    Future.microtask(() {
      if (mounted) {
        _loadProperties();
        _loadRoommateSearches();
      }
    });
  }

  void _loadProperties() {
    if (!mounted) return;
    final adminProvider = context.read<AdminProvider>();
    if (_selectedFilter == 'all') {
      adminProvider.loadAllProperties();
    } else {
      adminProvider.loadPropertiesByStatus(_selectedFilter);
    }
  }

  void _loadRoommateSearches() {
    if (!mounted) return;
    final adminProvider = context.read<AdminProvider>();
    if (_selectedRoommateFilter == 'all') {
      adminProvider.loadAllRoommateSearches();
    } else {
      adminProvider.loadRoommateSearchesByStatus(_selectedRoommateFilter);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.buildingUser, size: 20, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gestión de Departamentos y Roomies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 4,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      FaIcon(FontAwesomeIcons.building, size: 16),
                      SizedBox(width: 8),
                      Text('Departamentos'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      FaIcon(FontAwesomeIcons.users, size: 16),
                      SizedBox(width: 8),
                      Text('Roomies'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: DEPARTAMENTOS
              _buildPropertiesTab(adminProvider),
              // TAB 2: ROOMIES
              _buildRoommiesTab(adminProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPropertiesTab(AdminProvider adminProvider) {
    final filteredProperties = _filterProperties(adminProvider.allProperties);

    return Column(
      children: [
        // Filtros
        _buildFiltersSection(),
        // Búsqueda
        _buildSearchBar(),
        // Lista de departamentos
        Expanded(
          child: filteredProperties.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredProperties.length,
                  itemBuilder: (context, index) {
                    final property = filteredProperties[index];
                    return _buildPropertyCard(context, property, adminProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoommiesTab(AdminProvider adminProvider) {
    final filteredSearches = _filterRoommateSearches(adminProvider.allRoommateSearches);

    return Column(
      children: [
        // Filtros para roomies
        _buildRoommieFiltersSection(),
        // Lista de roomies
        Expanded(
          child: filteredSearches.isEmpty
              ? _buildEmptyRoommiesState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredSearches.length,
                  itemBuilder: (context, index) {
                    final search = filteredSearches[index];
                    return _buildRoommieCard(context, search, adminProvider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyRoommiesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.users, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay búsquedas de roomies',
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

  Widget _buildRoommieFiltersSection() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          value: _selectedRoommateFilter,
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
              value: 'active',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleCheck, size: 14, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Activos'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleXmark, size: 14, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Inactivos'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedRoommateFilter = value);
              _loadRoommateSearches();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRoommieCard(
    BuildContext context,
    Map<String, dynamic> search,
    AdminProvider adminProvider,
  ) {
    final title = search['title'] ?? 'Sin título';
    final userId = search['user_id'];
    final isActive = search['is_active'] ?? false;
    final createdAt = search['created_at'];
    final budget = search['budget_min'] ?? 0;
    final roommateCount = search['roommate_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Usuario: $userId',
                        style: TextStyle(
                          fontSize: 11,
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
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Detalles
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.dollarSign,
                          size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '\$$budget',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.users,
                          size: 12, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        '$roommateCount personas',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fecha
            Text(
              'Creado: ${createdAt?.split('T').first ?? 'N/A'}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),

            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isActive)
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.checkCircle, size: 12),
                    label: const Text('Activar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      adminProvider.updateRoommateSearchStatus(search['id'], 'active');
                    },
                  ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.eyeSlash, size: 12),
                    label: const Text('Desactivar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      adminProvider.updateRoommateSearchStatus(search['id'], 'inactive');
                    },
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 12),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => _showDeleteRoommieDialog(
                      context, search['id'], adminProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoommieDialog(
    BuildContext context,
    String searchId,
    AdminProvider adminProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Búsqueda de Roommate'),
        content: const Text('¿Estás seguro de que deseas eliminar esta búsqueda? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              adminProvider.deleteRoommateSearch(searchId);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterRoommateSearches(
      List<Map<String, dynamic>> searches) {
    return searches.where((search) {
      final title = (search['title'] ?? '').toString().toLowerCase();
      final searchTerm = _searchController.text.toLowerCase();
      return title.contains(searchTerm);
    }).toList();
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  FaIcon(FontAwesomeIcons.building, size: 14, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Todos'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleCheck, size: 14, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Activos'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleXmark, size: 14, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Inactivos'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'pending',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('Pendientes'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedFilter = value);
              _loadProperties();
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
          hintText: 'Buscar por título...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: Colors.grey[50],
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
          FaIcon(FontAwesomeIcons.building, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay departamentos',
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

  Widget _buildPropertyCard(
    BuildContext context,
    Map<String, dynamic> property,
    AdminProvider adminProvider,
  ) {
    final title = property['title'] ?? 'Sin título';
    final description = property['description'] ?? 'Sin descripción';
    final price = property['price'] ?? 0;
    final bedrooms = property['bedrooms'] ?? 0;
    final bathrooms = property['bathrooms'] ?? 0;
    final status = property['status'] ?? 'active';
    final createdAt = property['created_at'];
    final profile = property['profiles'] is Map
        ? property['profiles']
        : (property['profiles'] is List &&
                (property['profiles'] as List).isNotEmpty
            ? property['profiles'][0]
            : null);
    final ownerName = profile?['full_name'] ?? 'Propietario Desconocido';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por: $ownerName',
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
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Descripción
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Detalles con mejor visualización
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.dollarSign,
                            size: 13, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          '\$$price',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.bed,
                            size: 13, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          '$bedrooms hab.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.sink,
                            size: 13, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          '$bathrooms baños',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Fecha
            Text(
              'Publicado: ${createdAt?.split('T').first ?? 'N/A'}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),

            // Acciones con mejor espaciado
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'active')
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.checkCircle, size: 11),
                    label: const Text('Activar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      adminProvider.updatePropertyStatus(
                          property['id'], 'active');
                    },
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.eyeSlash, size: 11),
                  label: const Text('Desactivar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    adminProvider.updatePropertyStatus(
                        property['id'], 'inactive');
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 11),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showDeleteDialog(
                      context, property['id'], adminProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String propertyId,
    AdminProvider adminProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Departamento'),
        content: const Text('¿Estás seguro de que deseas eliminar este departamento? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              adminProvider.deleteProperty(propertyId);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'inactive':
        return 'Inactivo';
      case 'pending':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  List<Map<String, dynamic>> _filterProperties(
      List<Map<String, dynamic>> properties) {
    if (_searchController.text.isEmpty) {
      return properties;
    }
    final query = _searchController.text.toLowerCase();
    return properties
        .where((prop) =>
            (prop['title']?.toLowerCase().contains(query) ?? false) ||
            (prop['description']?.toLowerCase().contains(query) ?? false))
        .toList();
  }
}
