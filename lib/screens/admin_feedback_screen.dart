import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/feedback.dart' show UserFeedback, FeedbackStatus, FeedbackType;
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  String _selectedStatusFilter = 'all';
  String _selectedTypeFilter = 'all';
  TextEditingController _searchController = TextEditingController();

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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatusFilter = value);
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
                // Usuario
                _buildDetailRow('Usuario ID:', feedback.userId),
                const SizedBox(height: 12),

                // Tipo
                _buildDetailRow(
                    'Tipo:', _getTypeLabel(feedback.type)),
                const SizedBox(height: 12),

                // Categoría
                if (feedback.category != null)
                  _buildDetailRow('Categoría:', feedback.category!),
                if (feedback.category != null)
                  const SizedBox(height: 12),

                // Mensaje
                _buildSectionTitle('Mensaje:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feedback.message,
                    style: const TextStyle(fontSize: 13),
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

  Widget _buildDetailRow(String label, String value) {
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
                backgroundColor: Colors.orange.withOpacity(0.2),
                foregroundColor: Colors.orange,
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
                backgroundColor: Colors.grey.withOpacity(0.2),
                foregroundColor: Colors.grey[700],
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
        return Colors.blue;
      case FeedbackStatus.in_review:
        return Colors.orange;
      case FeedbackStatus.resolved:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
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
}
