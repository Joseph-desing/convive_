import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/feedback.dart' show UserFeedback, FeedbackStatus, FeedbackType;
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  String _selectedStatusFilter = 'all';
  String _selectedTypeFilter = 'all';
  TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, String>> _userProfiles = {}; // user_id -> {name, image_url}

  @override
  void initState() {
    super.initState();
    // Cargar feedback DESPUÉS del build
    Future.microtask(() {
      if (mounted) {
        _loadFeedback();
      }
    });
  }

  void _loadFeedback() {
    if (!mounted) return;
    final adminProvider = context.read<AdminProvider>();
    if (_selectedStatusFilter == 'all' && _selectedTypeFilter == 'all') {
      adminProvider.loadAllFeedback();
    } else if (_selectedStatusFilter != 'all') {
      adminProvider.loadFeedbackByStatus(_selectedStatusFilter);
    } else if (_selectedTypeFilter != 'all') {
      adminProvider.loadFeedbackByType(_selectedTypeFilter);
    }
  }

  Future<void> _loadUserProfiles(List<UserFeedback> feedbacks) async {
    final userIds = <String>{};
    
    // Extraer IDs únicos
    for (var fb in feedbacks) {
      userIds.add(fb.userId);
    }

    if (userIds.isEmpty) return;

    try {
      // Cargar perfiles - usando in() en lugar de inFilter()
      final profilesResponse = await SupabaseProvider.client
          .from('profiles')
          .select('user_id, full_name, profile_image_url')
          .in_('user_id', userIds.toList());

      if (profilesResponse is List) {
        for (var profile in profilesResponse) {
          if (profile is Map) {
            final userId = profile['user_id']?.toString() ?? '';
            final fullName = profile['full_name']?.toString() ?? 'Usuario';
            final imageUrl = profile['profile_image_url']?.toString() ?? '';
            
            if (userId.isNotEmpty) {
              _userProfiles[userId] = {
                'name': fullName,
                'image_url': imageUrl,
              };
            }
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error cargando perfiles: $e');
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
        title: const Text('Gestión de Quejas y Sugerencias'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredFeedback = _filterFeedback(adminProvider.allFeedback);
          
          // Cargar perfiles de usuarios si no están cargados
          if (_userProfiles.isEmpty && filteredFeedback.isNotEmpty) {
            _loadUserProfiles(filteredFeedback);
          }

          return Column(
            children: [
              // Filtros de Estado
              _buildStatusFiltersSection(),
              // Filtros de Tipo
              _buildTypeFiltersSection(),
              // Búsqueda
              _buildSearchBar(),
              // Lista de feedback
              Expanded(
                child: filteredFeedback.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredFeedback.length,
                        itemBuilder: (context, index) {
                          final feedback = filteredFeedback[index];
                          return _buildFeedbackCard(
                              context, feedback, adminProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusFiltersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('all', 'Todos'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('open', 'Abiertos'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('in_review', 'En Revisión'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('resolved', 'Resueltos'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('closed', 'Cerrados'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFiltersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeFilterChip('all', 'Todos'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('complaint', 'Quejas'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('suggestion', 'Sugerencias'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('bug_report', 'Reportes de Bugs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    
    Color getStatusColor(String status) {
      switch (status) {
        case 'open':
          return const Color(0xFFE8F5E9); // Verde claro
        case 'in_review':
          return const Color(0xFFFFF3E0); // Naranja claro
        case 'resolved':
          return const Color(0xFFE8F5E9); // Verde claro
        case 'closed':
          return const Color(0xFFECEFF1); // Gris claro
        default:
          return Colors.grey[200]!;
      }
    }
    
    Color getStatusLabelColor(String status) {
      switch (status) {
        case 'open':
          return const Color(0xFF2E7D32); // Verde oscuro
        case 'in_review':
          return const Color(0xFFE65100); // Naranja oscuro
        case 'resolved':
          return const Color(0xFF2E7D32); // Verde oscuro
        case 'closed':
          return const Color(0xFF546E7A); // Gris oscuro
        default:
          return Colors.grey[700]!;
      }
    }
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatusFilter = value);
        _loadFeedback();
      },
      backgroundColor: isSelected ? getStatusColor(value) : Colors.grey[200],
      selectedColor: getStatusColor(value),
      labelStyle: TextStyle(
        color: isSelected ? getStatusLabelColor(value) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: isSelected 
          ? BorderSide(color: getStatusLabelColor(value), width: 1.5)
          : BorderSide(color: Colors.grey[300]!),
    );
  }

  Widget _buildTypeFilterChip(String value, String label) {
    final isSelected = _selectedTypeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTypeFilter = value);
        _loadFeedback();
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
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por asunto o mensaje...',
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
          FaIcon(FontAwesomeIcons.comments,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay feedback',
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

  Widget _buildFeedbackCard(
    BuildContext context,
    UserFeedback feedback,
    AdminProvider adminProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            _buildTypeIcon(feedback.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(feedback.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
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
                color: _getStatusColor(feedback.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusLabel(feedback.status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(feedback.status),
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de quién reporta (Usuario)
                _buildUserReportSection('Usuario que Reporta', feedback.userId),
                const SizedBox(height: 16),

                // Información de la queja
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                            color: Colors.blue[700], 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Detalles del Reporte',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Tipo de reporte:', _getTypeLabel(feedback.type), isShort: true),
                      const SizedBox(height: 8),
                      if (feedback.category != null) ...[
                        _buildDetailRow('Categoría:', feedback.category!, isShort: true),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Información del usuario reportado (extraído del mensaje)
                _buildReportedUserSection(feedback.message),
                const SizedBox(height: 16),

                // Detalles del mensaje
                _buildSectionTitle('Descripción de la Queja:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _extractComplaintDescription(feedback.message),
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ),
                const SizedBox(height: 16),

                // Respuesta del administrador
                if (feedback.adminResponse != null) ...[
                  _buildSectionTitle('Respuesta del Administrador:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.adminResponse!,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Respondido: ${_formatDate(feedback.adminResponseAt ?? DateTime.now())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Campo de respuesta
                  _buildSectionTitle('Responder a este feedback:'),
                  const SizedBox(height: 8),
                  _buildResponseForm(context, feedback, adminProvider),
                ],

                const SizedBox(height: 16),

                // Botones de acción
                _buildActionButtons(
                    context, feedback, adminProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(FeedbackType type) {
    IconData icon;
    Color color;

    switch (type) {
      case FeedbackType.complaint:
        icon = FontAwesomeIcons.triangleExclamation;
        color = Colors.red;
        break;
      case FeedbackType.suggestion:
        icon = FontAwesomeIcons.lightbulb;
        color = Colors.orange;
        break;
      case FeedbackType.bug_report:
        icon = FontAwesomeIcons.bug;
        color = Colors.purple;
        break;
    }

    return FaIcon(icon, size: 20, color: color);
  }

  Widget _buildDetailRow(String label, String value, {bool isShort = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            maxLines: isShort ? 1 : null,
            overflow: isShort ? TextOverflow.ellipsis : TextOverflow.clip,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _buildResponseForm(
    BuildContext context,
    UserFeedback feedback,
    AdminProvider adminProvider,
  ) {
    TextEditingController responseController = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: responseController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta aquí...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('Enviar Respuesta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            if (responseController.text.isNotEmpty) {
              final adminId =
                  context.read<AuthProvider>().currentUser?.id ?? 'admin';
              adminProvider.respondToFeedback(
                feedback.id,
                responseController.text,
                adminId,
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    UserFeedback feedback,
    AdminProvider adminProvider,
  ) {
    return Row(
      children: [
        if (feedback.status != FeedbackStatus.in_review)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('En Revisión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB8C00), // Naranja vibrante
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                adminProvider.updateFeedbackStatus(feedback.id, 'in_review');
              },
            ),
          ),
        if (feedback.status != FeedbackStatus.in_review)
          const SizedBox(width: 8),
        if (feedback.status == FeedbackStatus.resolved ||
            feedback.status == FeedbackStatus.in_review)
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Cerrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF616161), // Gris oscuro
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                adminProvider.closeFeedback(feedback.id);
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.open:
        return const Color(0xFF1976D2); // Azul oscuro
      case FeedbackStatus.in_review:
        return const Color(0xFFFB8C00); // Naranja vibrante
      case FeedbackStatus.resolved:
        return const Color(0xFF388E3C); // Verde oscuro
      case FeedbackStatus.closed:
        return const Color(0xFF616161); // Gris oscuro
    }
  }

  String _getStatusLabel(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.open:
        return 'Abierto';
      case FeedbackStatus.in_review:
        return 'En Revisión';
      case FeedbackStatus.resolved:
        return 'Resuelto';
      case FeedbackStatus.closed:
        return 'Cerrado';
    }
  }

  String _getTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.complaint:
        return 'Queja';
      case FeedbackType.suggestion:
        return 'Sugerencia';
      case FeedbackType.bug_report:
        return 'Reporte de Bug';
    }
  }

  List<UserFeedback> _filterFeedback(List<UserFeedback> feedbacks) {
    if (_searchController.text.isEmpty) {
      return feedbacks;
    }
    final query = _searchController.text.toLowerCase();
    return feedbacks
        .where((fb) =>
            fb.subject.toLowerCase().contains(query) ||
            fb.message.toLowerCase().contains(query))
        .toList();
  }

  // Extraer descripción del mensaje
  String _extractComplaintDescription(String message) {
    final lines = message.split('\n');
    final descriptionIndex = lines.indexWhere((line) => line.contains('Descripción de la queja:'));
    
    if (descriptionIndex != -1 && descriptionIndex + 1 < lines.length) {
      return lines.sublist(descriptionIndex + 1).join('\n').trim();
    }
    return message;
  }

  // Extraer nombre del usuario reportado del mensaje
  String _extractReportedUserName(String message) {
    final match = RegExp(r'Usuario reportado: (.+)').firstMatch(message);
    return match?.group(1) ?? 'Usuario desconocido';
  }

  // Extraer propiedad/búsqueda del mensaje
  String _extractPropertyName(String message) {
    final match = RegExp(r'Propiedad\/Búsqueda: (.+)').firstMatch(message);
    return match?.group(1) ?? 'Publicación desconocida';
  }

  // Widget para mostrar usuario que reporta
  Widget _buildUserReportSection(String title, String userId) {
    final userProfile = _userProfiles[userId];
    final userName = userProfile?['name'] ?? 'Usuario Desconocido';
    final imageUrl = userProfile?['image_url'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.purple[300],
              borderRadius: BorderRadius.circular(25),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar usuario reportado
  Widget _buildReportedUserSection(String message) {
    final reportedUserName = _extractReportedUserName(message);
    final propertyName = _extractPropertyName(message);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usuario Reportado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.orange[300],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportedUserName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      propertyName,
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
            ],
          ),
        ],
      ),
    );
  }
}
