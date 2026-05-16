import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/feedback.dart' show UserFeedback, FeedbackStatus, FeedbackType;
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../widgets/admin/admin_ui.dart';
import 'feedback_detail_screen.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  String _selectedStatusFilter = 'in_review';
  static const _statusFilters = {'in_review', 'open', 'resolved'};
  TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, String>> _userProfiles = {}; // user_id -> {name, image_url}

  @override
  void initState() {
    super.initState();
    // Cargar feedback DESPUÉS del build
    Future.microtask(() {
      if (mounted) {
        _loadFeedback();
        
        // Cargar perfiles después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            final adminProvider = context.read<AdminProvider>();
            if (adminProvider.allFeedback.isNotEmpty) {
              _loadUserProfiles(adminProvider.allFeedback);
            }
          }
        });
      }
    });
  }

  void _loadFeedback() {
    if (!mounted) return;
    _selectedStatusFilter = _normalizeStatusFilter(_selectedStatusFilter);
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadFeedbackByStatus(_selectedStatusFilter);
  }

  String _normalizeStatusFilter(String value) {
    return _statusFilters.contains(value) ? value : 'in_review';
  }

  Future<void> _loadUserProfiles(List<UserFeedback> feedbacks) async {
    final userIds = <String>{};
    
    // Extraer IDs únicos (tanto who reports como who is reported)
    for (var fb in feedbacks) {
      debugPrint('📋 Feedback userId: "${fb.userId}"');
      if (fb.userId.isNotEmpty) {
        userIds.add(fb.userId);
      }
      // También agregar el usuario reportado
      if (fb.reportedUserId != null && fb.reportedUserId!.isNotEmpty) {
        debugPrint('📋 Reported userId: "${fb.reportedUserId}"');
        userIds.add(fb.reportedUserId!);
      } else {
        // Para feedback antiguo sin reported_user_id, intentar extraer el nombre y buscarlo
        try {
          final reportedName = _extractReportedUserName(fb.message);
          if (reportedName.isNotEmpty && reportedName != 'Usuario desconocido') {
            debugPrint('🔎 Buscando usuario reportado por nombre en profiles: $reportedName');
            final profilesByName = await SupabaseProvider.client
                .from('profiles')
                .select('user_id')
                .ilike('full_name', '%$reportedName%')
                .limit(1);
            
            if (profilesByName.isNotEmpty && profilesByName[0]['user_id'] != null) {
              final foundUserId = profilesByName[0]['user_id'].toString();
              debugPrint('✅ Usuario encontrado por nombre en profiles: $foundUserId');
              userIds.add(foundUserId);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error buscando usuario por nombre: $e');
        }
      }
    }

    if (userIds.isEmpty) {
      debugPrint('⚠️ No hay IDs de usuarios para cargar perfiles');
      return;
    }

    try {
      debugPrint('🔍 Cargando ${userIds.length} perfiles únicos: $userIds');
      
      // Cargar cada perfil individualmente para garantizar éxito
      for (final userId in userIds) {
        if (_userProfiles.containsKey(userId)) {
          debugPrint('✅ Perfil ya en cache: $userId');
          continue;
        }
        
        try {
          debugPrint('🔎 Buscando perfil en Supabase para: $userId');
          
          // Cargar datos del perfil
          final profileResponse = await SupabaseProvider.client
              .from('profiles')
              .select('user_id, full_name, profile_image_url')
              .eq('user_id', userId)
              .maybeSingle();

          // Cargar email del usuario
          final userResponse = await SupabaseProvider.client
              .from('users')
              .select('email')
              .eq('id', userId)
              .maybeSingle();

          debugPrint('📡 Profile Response: $profileResponse');
          debugPrint('📡 User Response: $userResponse');

          final fullName = (profileResponse?['full_name'] ?? 'Usuario').toString();
          final imageUrl = (profileResponse?['profile_image_url'] ?? '').toString();
          final email = (userResponse?['email'] ?? '').toString();
          
          _userProfiles[userId] = {
            'name': fullName,
            'image_url': imageUrl,
            'email': email,
          };
          debugPrint('✅ Perfil cargado: $fullName - $email ($userId)');
        } catch (e) {
          debugPrint('❌ Error cargando perfil de $userId: $e');
          _userProfiles[userId] = {
            'name': 'Error al cargar',
            'image_url': '',
            'email': '',
          };
        }
      }
      
      if (mounted) setState(() {});
      debugPrint('✅ Todos los perfiles procesados. Cache: ${_userProfiles.length}');
    } catch (e) {
      debugPrint('❌ Error general en _loadUserProfiles: $e');
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
      backgroundColor: AdminUi.background,
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredFeedback = _filterFeedback(adminProvider.allFeedback);

          return Column(
            children: [
              const AdminSectionHeader(
                title: 'Quejas y feedback',
                subtitle: 'Prioriza reportes abiertos y da seguimiento.',
                icon: FontAwesomeIcons.comments,
              ),
              // Filtros de Estado
              _buildStatusFiltersSection(),
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
    final selectedValue = _normalizeStatusFilter(_selectedStatusFilter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                  value: 'in_review',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.magnifyingGlass, size: 14, color: Color(0xFFE65100)),
                      SizedBox(width: 10),
                      Text('En Revisión'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'open',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.clock, size: 14, color: Color(0xFF1976D2)),
                      SizedBox(width: 10),
                      Text('Pendientes'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.checkDouble, size: 14, color: Color(0xFF2E7D32)),
                      SizedBox(width: 10),
                      Text('Resueltos'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatusFilter = value);
                  _loadFeedback();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: _searchController,
        decoration: AdminUi.inputDecoration(hintText: 'Buscar por asunto o mensaje...'),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AdminEmptyState(
      icon: FontAwesomeIcons.comments,
      title: 'No hay feedback',
      subtitle: 'Cambia el filtro o intenta con otro texto.',
    );
  }

  Widget _buildFeedbackCard(
    BuildContext context,
    UserFeedback feedback,
    AdminProvider adminProvider,
  ) {
    return GestureDetector(
      onTap: () {
        final shouldAutoReview = feedback.status == FeedbackStatus.open &&
            !_isManuallyPending(feedback);
        final detailFeedback = shouldAutoReview
            ? feedback.copyWith(status: FeedbackStatus.in_review)
            : feedback;

        if (shouldAutoReview) {
          adminProvider.updateFeedbackStatus(feedback.id, 'in_review');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackDetailScreen(feedback: detailFeedback),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: AdminUi.panelDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              if (feedback.status != FeedbackStatus.open ||
                  _isManuallyPending(feedback)) ...[
                AdminStatusChip(
                  label: _getStatusLabel(feedback.status),
                  color: _getStatusColor(feedback.status),
                ),
                const SizedBox(width: 12),
              ],
              Icon(Icons.arrow_forward_ios, 
                size: 16, 
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
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

  Widget _buildImprovedResponseSection(
    BuildContext context,
    UserFeedback feedback,
    AdminProvider adminProvider,
  ) {
    TextEditingController responseController = TextEditingController();
    
    // Títulos específicos según tipo
    String getResponseTitle(FeedbackType type) {
      switch (type) {
        case FeedbackType.complaint:
          return 'Responder a esta Queja';
        case FeedbackType.suggestion:
          return 'Responder a esta Sugerencia';
        case FeedbackType.bug_report:
          return 'Responder a este Reporte de Bug';
      }
    }
    
    String getResponseHint(FeedbackType type) {
      switch (type) {
        case FeedbackType.complaint:
          return 'Explica las acciones tomadas para resolver esta queja...';
        case FeedbackType.suggestion:
          return 'Agradece la sugerencia y comparte tu respuesta...';
        case FeedbackType.bug_report:
          return 'Describe el estado del bug y próximas acciones...';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply_rounded,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                getResponseTitle(feedback.type),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: responseController,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: getResponseHint(feedback.type),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Enviar Respuesta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (responseController.text.isNotEmpty) {
                      final adminId = context.read<AuthProvider>().currentUser?.id ?? 'admin';
                      adminProvider.respondToFeedback(
                        feedback.id,
                        responseController.text,
                        adminId,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Respuesta enviada exitosamente'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Escribe una respuesta'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    UserFeedback feedback,
    AdminProvider adminProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primera fila: Cambiar estado
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cambiar Estado:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Botón "En Revisión"
                  if (feedback.status != FeedbackStatus.in_review)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('En Revisión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB8C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          adminProvider.updateFeedbackStatus(feedback.id, 'in_review');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Cambio a "En Revisión"'),
                              backgroundColor: Color(0xFFFB8C00),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB8C00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '✓ En Revisión',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Botón "Resuelto"
                  if (feedback.status != FeedbackStatus.resolved)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Resuelto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          adminProvider.updateFeedbackStatus(feedback.id, 'resolved');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Cambio a "Resuelto"'),
                              backgroundColor: Color(0xFF4CAF50),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '✓ Resuelto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isManuallyPending(UserFeedback feedback) {
    final updatedAt = feedback.updatedAt;
    if (feedback.status != FeedbackStatus.open || updatedAt == null) {
      return false;
    }

    return updatedAt.difference(feedback.createdAt).abs() >
        const Duration(seconds: 1);
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
        return 'Pendiente';
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

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'property_complaint':
        return '🏠 Propiedad';
      case 'roommate_search_complaint':
        return '👥 Búsqueda de Compañero';
      default:
        return 'Otro';
    }
  }

  List<UserFeedback> _filterFeedback(List<UserFeedback> feedbacks) {
    var filtered = feedbacks;

    filtered = filtered.where((fb) {
      switch (_selectedStatusFilter) {
        case 'open':
          return fb.status == FeedbackStatus.open;
        case 'in_review':
          return fb.status == FeedbackStatus.in_review;
        case 'resolved':
          return fb.status == FeedbackStatus.resolved;
        default:
          return true;
      }
    }).toList();

    if (_searchController.text.isEmpty) {
      return filtered;
    }

    final query = _searchController.text.toLowerCase();
    return filtered
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
    final userName = userProfile?['name'] ?? 'Cargando...';
    final imageUrl = userProfile?['image_url'] ?? '';
    final email = userProfile?['email'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF3E5F5),
            const Color(0xFFE1BEE7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCE93D8), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: const Color(0xFF7B1FA2),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7B1FA2),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFBA68C8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF9C27B0), width: 2),
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
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: userName == 'Cargando...' 
                            ? Colors.grey[600] 
                            : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isNotEmpty ? email : 'Sin email',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7B1FA2),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userProfile == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '❌ Perfil no encontrado',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REPORTA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para mostrar usuario reportado
  Widget _buildReportedUserSection(UserFeedback feedback) {
    final reportedUserId = feedback.reportedUserId;
    
    // Si reportedUserId está disponible, usar datos de perfil
    if (reportedUserId != null && reportedUserId.isNotEmpty) {
      final userProfile = _userProfiles[reportedUserId];
      final userName = userProfile?['name'] ?? 'Cargando...';
      final imageUrl = userProfile?['image_url'] ?? '';
      final email = userProfile?['email'] ?? '';

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFE0B2),
              const Color(0xFFFFCC80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB74D), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF57C00).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_remove_rounded,
                  color: const Color(0xFFE65100),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usuario Reportado',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFF57C00), width: 2),
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
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.isNotEmpty ? email : 'Sin email',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'REPORTADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // Fallback para datos antiguos: extraer del mensaje y buscar en cache
    final reportedUserName = _extractReportedUserName(feedback.message);
    
    // Buscar el usuario en el cache de forma flexible
    Map<String, String>? userProfile;
    if (reportedUserName.isNotEmpty) {
      final nameLower = reportedUserName.toLowerCase();
      final nameWords = nameLower.split(' ');
      
      // Buscar coincidencia exacta primero
      for (var entry in _userProfiles.entries) {
        final cachedName = entry.value['name']?.toLowerCase() ?? '';
        if (cachedName == nameLower) {
          userProfile = entry.value;
          debugPrint('✅ Usuario encontrado por coincidencia exacta: $reportedUserName');
          break;
        }
      }
      
      // Si no encuentra exacta, busca por palabras clave (ej. "Changoluisa" en "Changoluiza")
      if (userProfile == null) {
        for (var entry in _userProfiles.entries) {
          final cachedName = entry.value['name']?.toLowerCase() ?? '';
          bool matchFound = false;
          
          for (var word in nameWords) {
            if (word.isNotEmpty && cachedName.contains(word)) {
              matchFound = true;
              break;
            }
          }
          
          if (matchFound) {
            userProfile = entry.value;
            debugPrint('✅ Usuario encontrado por palabra clave: ${entry.value['name']}');
            break;
          }
        }
      }
    }
    
    final userName = userProfile?['name'] ?? reportedUserName;
    final imageUrl = userProfile?['image_url'] ?? '';
    final email = userProfile?['email'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFE0B2),
            const Color(0xFFFFCC80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_remove_rounded,
                color: const Color(0xFFE65100),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Usuario Reportado',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF57C00), width: 2),
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
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isNotEmpty ? email : 'Sin email',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REPORTADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
