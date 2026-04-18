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

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  String _selectedFilter = 'all';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar propiedades DESPUÉS del build
    Future.microtask(() {
      if (mounted) {
        _loadProperties();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Departamentos'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredProperties =
              _filterProperties(adminProvider.allProperties);

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
                          return _buildPropertyCard(
                              context, property, adminProvider);
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
            _buildFilterChip('active', 'Activos'),
            const SizedBox(width: 8),
            _buildFilterChip('inactive', 'Inactivos'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pendientes'),
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
        _loadProperties();
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
          hintText: 'Buscar por título...',
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
                        'Por: $ownerName',
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
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Descripción
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Detalles
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.dollarSign,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '\$$price',
                        style: TextStyle(
                          fontSize: 12,
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
                          size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '$bedrooms hab.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.sink,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '$bathrooms baños',
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
              'Publicado: ${createdAt?.split('T').first ?? 'N/A'}',
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
                if (status != 'active')
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.checkCircle, size: 12),
                    label: const Text('Activar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () {
                      adminProvider.updatePropertyStatus(
                          property['id'], 'active');
                    },
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.eyeSlash, size: 12),
                  label: const Text('Desactivar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    adminProvider.updatePropertyStatus(
                        property['id'], 'inactive');
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 12),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
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
