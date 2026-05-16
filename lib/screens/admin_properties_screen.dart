import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/admin_provider.dart';
import '../utils/colors.dart';
import '../widgets/admin/admin_ui.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({Key? key}) : super(key: key);

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'pending';
  String _selectedRoommateFilter = 'pending';
  TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  static const _publicationFilters = {'pending', 'active', 'inactive'};

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
    _selectedFilter = _normalizePublicationFilter(_selectedFilter);
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadPropertiesByStatus(_selectedFilter);
  }

  void _loadRoommateSearches() {
    if (!mounted) return;
    _selectedRoommateFilter =
        _normalizePublicationFilter(_selectedRoommateFilter);
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadRoommateSearchesByStatus(_selectedRoommateFilter);
  }

  String _normalizePublicationFilter(String value) {
    return _publicationFilters.contains(value) ? value : 'pending';
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
      backgroundColor: AdminUi.background,
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              const AdminSectionHeader(
                title: 'Publicaciones',
                subtitle: 'Revisa departamentos y busquedas de roomies.',
                icon: FontAwesomeIcons.building,
              ),
              // TabBar para Departamentos y Roomies
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                decoration: AdminUi.panelDecoration(),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 4,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey[400],
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
              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: DEPARTAMENTOS
                    _buildPropertiesTab(adminProvider),
                    // TAB 2: ROOMIES
                    _buildRoommiesTab(adminProvider),
                  ],
                ),
              ),
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
    final selectedValue = _normalizePublicationFilter(_selectedRoommateFilter);
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: AdminUi.panelDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButton<String>(
          value: selectedValue,
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
              value: 'pending',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Pendientes'),
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
    // Nombre del usuario desde el join con profiles
    final profileData = search['profiles'] as Map<String, dynamic>?;
    final userName = profileData?['full_name'] as String? ?? userId?.toString() ?? 'Desconocido';
    final userAvatar = profileData?['profile_image_url'] as String?;
    final status = search['status'] ??
        ((search['is_active'] ?? false) ? 'active' : 'pending');
    final createdAt = search['created_at'];
    final budget = search['budget'] ?? 0;       // columna correcta: 'budget'
    final address = search['address'] ?? 'Sin dirección';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AdminUi.panelDecoration(),
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
                        userName,
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
                      FaIcon(FontAwesomeIcons.locationDot,
                          size: 12, color: Colors.purple),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

            // Badge PDF
            _buildPdfBadge(search['verification_pdf_url']),
            const SizedBox(height: 8),
            // Acciones
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                if (search['verification_pdf_url'] != null &&
                    (search['verification_pdf_url'] as String).isNotEmpty)
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.filePdf, size: 11),
                    label: const Text('Revisar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: () => _showPdfReviewDialog(
                      context: context,
                      id: search['id'],
                      type: 'roommate',
                      title: search['title'] ?? '',
                      pdfUrl: search['verification_pdf_url'],
                      adminProvider: adminProvider,
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 12),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  onPressed: () => _showDeleteRoommieDialog(context, search['id'], adminProvider),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.red[50],
                  border: Border.all(
                    color: Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.trash,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Eliminar Busqueda de Roommate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.exclamation,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Accion Irreversible',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estas seguro de que deseas eliminar esta busqueda? Esta accion no se puede deshacer.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        adminProvider.deleteRoommateSearch(searchId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Busqueda de roommate eliminada correctamente',
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  List<Map<String, dynamic>> _filterRoommateSearches(
      List<Map<String, dynamic>> searches) {
    return searches.where((search) {
      final title = (search['title'] ?? '').toString().toLowerCase();
      final searchTerm = _searchController.text.toLowerCase();
      return title.contains(searchTerm);
    }).toList();
  }

  Widget _buildFiltersSection() {
    final selectedValue = _normalizePublicationFilter(_selectedFilter);
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: AdminUi.panelDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButton<String>(
          value: selectedValue,
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
              value: 'pending',
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Pendientes'),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por título...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AdminUi.border),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: Colors.white,
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
    final status = property['status'] ??
        ((property['is_active'] ?? false) ? 'active' : 'pending');
    final createdAt = property['created_at'];
    final profile = property['profiles'] is Map
        ? property['profiles']
        : (property['profiles'] is List &&
                (property['profiles'] as List).isNotEmpty
            ? property['profiles'][0]
            : null);
    final ownerName = (profile?['full_name'] as String?)?.trim().isNotEmpty ==
            true
        ? (profile?['full_name'] as String).trim()
        : 'Propietario Desconocido';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: AdminUi.panelDecoration(),
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

            // Badge PDF
            _buildPdfBadge(property['verification_pdf_url']),
            const SizedBox(height: 8),
            // Acciones
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                // Revisar PDF (siempre visible si hay PDF)
                if (property['verification_pdf_url'] != null &&
                    (property['verification_pdf_url'] as String).isNotEmpty)
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.filePdf, size: 11),
                    label: const Text('Revisar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: () => _showPdfReviewDialog(
                      context: context,
                      id: property['id'],
                      type: 'property',
                      title: property['title'] ?? '',
                      pdfUrl: property['verification_pdf_url'],
                      adminProvider: adminProvider,
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 12),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  onPressed: () => _showDeleteDialog(context, property['id'], adminProvider),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de advertencia grande
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.red[50],
                  border: Border.all(
                    color: Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.trash,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              
              // Título principal
              const Text(
                'Eliminar Departamento',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Descripción con advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.exclamation,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Acción Irreversible',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¿Estás seguro de que deseas eliminar este departamento? Esta acción no se puede deshacer.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        adminProvider.deleteProperty(propertyId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '✅ Departamento eliminado correctamente',
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  // ==================== PDF REVIEW ====================

  Widget _buildPdfBadge(dynamic pdfUrl) {
    final hasPdf = pdfUrl != null && (pdfUrl as String).isNotEmpty;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasPdf ? Colors.indigo.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasPdf ? Colors.indigo.shade300 : Colors.red.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                hasPdf ? FontAwesomeIcons.filePdf : FontAwesomeIcons.triangleExclamation,
                size: 11,
                color: hasPdf ? Colors.indigo.shade600 : Colors.red.shade600,
              ),
              const SizedBox(width: 5),
              Text(
                hasPdf ? 'PDF de verificacion adjunto' : 'Sin PDF de verificacion',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasPdf ? Colors.indigo.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPdfReviewDialog({
    required BuildContext context,
    required String id,
    required String type,
    required String title,
    required String pdfUrl,
    required AdminProvider adminProvider,
  }) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Revision',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: AdminUi.panelDecoration(
                            borderColor: AppColors.primary.withOpacity(0.22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.fileShield,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Documento de verificacion',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AdminUi.ink,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Revisa el respaldo antes de aprobar.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AdminUi.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.arrowUpRightFromSquare,
                                    size: 13,
                                  ),
                                  label: const Text('Abrir PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.tryParse(pdfUrl);
                                    if (uri != null &&
                                        await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nota para el usuario',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AdminUi.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: AdminUi.inputDecoration(
                            hintText:
                                'Ej: Documento aprobado o falta planilla de servicios...',
                            icon: Icons.edit_note_rounded,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.xmark,
                                  size: 13,
                                ),
                                label: const Text('Rechazar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade600,
                                  side: BorderSide(
                                    color: Colors.red.shade300,
                                    width: 1.4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(ctx);
                                  final note = noteController.text.trim();
                                  if (ctx.mounted) navigator.pop();
                                  try {
                                    await adminProvider.rejectPublication(
                                      id: id,
                                      type: type,
                                      adminNote: note,
                                    );
                                    if (type == 'property') {
                                      _loadProperties();
                                    } else {
                                      _loadRoommateSearches();
                                    }
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Publicacion rechazada',
                                          ),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No se pudo rechazar: $e',
                                          ),
                                          backgroundColor: Colors.red.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const FaIcon(
                                  FontAwesomeIcons.check,
                                  size: 13,
                                ),
                                label: const Text('Aprobar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(ctx);
                                  final note = noteController.text.trim();
                                  if (ctx.mounted) navigator.pop();
                                  try {
                                    await adminProvider.approvePublication(
                                      id: id,
                                      type: type,
                                      adminNote: note,
                                    );
                                    if (type == 'property') {
                                      _loadProperties();
                                    } else {
                                      _loadRoommateSearches();
                                    }
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Publicacion aprobada',
                                          ),
                                          backgroundColor:
                                              Colors.green.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'No se pudo aprobar: $e',
                                          ),
                                          backgroundColor: Colors.red.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.xmark,
                              size: 13,
                            ),
                            label: const Text('Cancelar'),
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              foregroundColor: AdminUi.ink,
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
        );
      },
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
