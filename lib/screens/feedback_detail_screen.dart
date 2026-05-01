import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/feedback.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_provider.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final UserFeedback feedback;

  const FeedbackDetailScreen({
    Key? key,
    required this.feedback,
  }) : super(key: key);

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  late TextEditingController _responseController;
  Map<String, dynamic>? _reporterData;
  Map<String, dynamic>? _reportedUserData;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Obtener todos los usuarios con sus perfiles
      final allUsers = await SupabaseProvider.client
          .from('users')
          .select('id, email, profiles(full_name, profile_image_url)');
      
      print('📋 Usuarios recuperados: ${allUsers.runtimeType}');
      if (allUsers is List) {
        print('📊 Total de usuarios: ${allUsers.length}');
      }
      
      Map<String, dynamic>? reporterData;
      
      // Buscar el usuario que reporta
      if (allUsers is List && allUsers.isNotEmpty) {
        print('🔍 Buscando usuario reportador con ID: ${widget.feedback.userId}');
        for (var user in allUsers) {
          print('  - Usuario ID: ${user['id']}');
          if (user['id'] == widget.feedback.userId) {
            print('  ✅ Usuario encontrado!');
            reporterData = {
              'full_name': user['email'] ?? 'Usuario',
              'email': user['email'] ?? 'Sin email',
              'profile_image_url': '',
              'profiles': user['profiles'] ?? {},
            };
            
            // Extraer nombre completo y foto del perfil si existe
            final profiles = user['profiles'];
            if (profiles is Map && profiles.isNotEmpty) {
              reporterData['full_name'] = profiles['full_name'] ?? user['email'] ?? 'Usuario';
              if (profiles['profile_image_url'] is String && (profiles['profile_image_url'] as String).isNotEmpty) {
                reporterData['profile_image_url'] = profiles['profile_image_url'];
              }
            }
            break;
          }
        }
      }
      
      print('📌 Datos del reportador: $reporterData');
      
      // Extraer información del usuario reportado del mensaje
      String reportedUserName = '';
      if (widget.feedback.message.contains('Usuario reportado:')) {
        final match = RegExp(r'Usuario reportado: (.+?)(?:\n|$)').firstMatch(widget.feedback.message);
        reportedUserName = match?.group(1)?.trim() ?? '';
      }

      // Buscar usuario reportado por nombre en la base de datos
      Map<String, dynamic>? reportedUserData;
      if (reportedUserName.isNotEmpty && allUsers is List) {
        for (var user in allUsers) {
          final profiles = user['profiles'];
          if (profiles is Map && profiles.isNotEmpty) {
            final fullName = profiles['full_name'] ?? '';
            if (fullName.toLowerCase().contains(reportedUserName.toLowerCase()) ||
                reportedUserName.toLowerCase().contains(fullName.toLowerCase())) {
              reportedUserData = {
                'full_name': fullName,
                'email': user['email'] ?? 'No disponible',
                'profile_image_url': profiles['profile_image_url'] ?? '',
                'profiles': profiles,
              };
              print('✅ Usuario reportado encontrado: $fullName');
              break;
            }
          }
        }
        
        // Si no se encuentra, crear un objeto con los datos disponibles
        if (reportedUserData == null) {
          reportedUserData = {
            'full_name': reportedUserName,
            'email': 'No disponible',
            'profile_image_url': '',
            'profiles': {'full_name': reportedUserName, 'profile_image_url': ''},
          };
          print('⚠️ Usuario reportado no encontrado en BD, usando nombre: $reportedUserName');
        }
      }

      setState(() {
        _reporterData = reporterData;
        _reportedUserData = reportedUserData;
        _loadingUsers = false;
      });
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() {
        _loadingUsers = false;
      });
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  Color _getStatusColor(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.open:
        return Colors.green;
      case FeedbackStatus.in_review:
        return Colors.orange;
      case FeedbackStatus.resolved:
        return Colors.green;
      case FeedbackStatus.closed:
        return Colors.grey;
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

  IconData _getTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.complaint:
        return FontAwesomeIcons.triangleExclamation;
      case FeedbackType.suggestion:
        return FontAwesomeIcons.lightbulb;
      case FeedbackType.bug_report:
        return FontAwesomeIcons.bug;
    }
  }

  Color _getTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.complaint:
        return Colors.red;
      case FeedbackType.suggestion:
        return Colors.orange;
      case FeedbackType.bug_report:
        return Colors.purple;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalles de la Queja'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado principal con efecto visual
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getTypeColor(widget.feedback.type).withOpacity(0.1),
                        _getTypeColor(widget.feedback.type).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getTypeColor(widget.feedback.type).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTypeColor(widget.feedback.type)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FaIcon(
                              _getTypeIcon(widget.feedback.type),
                              color: _getTypeColor(widget.feedback.type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTypeLabel(widget.feedback.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getTypeColor(widget.feedback.type),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.feedback.subject,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.feedback.status)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(widget.feedback.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.feedback.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(widget.feedback.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Descripción con secciones separadas
                Text(
                  'Descripción de la Queja',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Propiedad/Búsqueda
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home_work, color: Colors.blue[600], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Propiedad/Búsqueda',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.feedback.message.split('Usuario reportado:')[0].trim(),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Usuario reportado
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.red[600], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Usuario Reportado',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.feedback.message.contains('Usuario reportado:')
                            ? widget.feedback.message
                                .split('Usuario reportado:')[1]
                                .split('\n')[0]
                                .trim()
                            : 'No especificado',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Descripción detallada
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, color: Colors.amber[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Descripción Detallada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.feedback.message.contains('Descripción de la queja:')
                            ? widget.feedback.message
                                .split('Descripción de la queja:')[1]
                                .trim()
                            : widget.feedback.message,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sección de Usuarios Involucrados
                Text(
                  'Usuarios Involucrados',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Información del usuario que reporta
                if (_loadingUsers)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_reporterData != null)
                  _buildUserCard(
                    title: 'Reporta',
                    userData: _reporterData!,
                    color: Colors.purple,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No se encontraron datos del usuario',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Información del usuario reportado
                if (_reportedUserData != null)
                  _buildUserCard(
                    title: 'Reportado',
                    userData: _reportedUserData!,
                    color: Colors.red,
                  )
                else if (!_loadingUsers)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No se encontró información del usuario reportado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Respuesta del administrador
                if (widget.feedback.adminResponse != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Respuesta del Administrador',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Respuesta Enviada',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.feedback.adminResponse!,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Respondido: ${_formatDate(widget.feedback.adminResponseAt ?? DateTime.now())}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Responder a esta Queja',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _responseController,
                        maxLines: 4,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu respuesta...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Enviar Respuesta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (_responseController.text.isNotEmpty) {
                            final adminId =
                                context.read<AuthProvider>().currentUser?.id ??
                                    'admin';
                            adminProvider.respondToFeedback(
                              widget.feedback.id,
                              _responseController.text,
                              adminId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Respuesta enviada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Botones de cambio de estado
                const Text(
                  'Cambiar Estado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.feedback.status != FeedbackStatus.in_review)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('En Revisión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          adminProvider.updateFeedbackStatus(
                            widget.feedback.id,
                            'in_review',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Cambio a En Revisión'),
                            ),
                          );
                        },
                      ),
                    if (widget.feedback.status != FeedbackStatus.resolved)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Resuelto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          adminProvider.updateFeedbackStatus(
                            widget.feedback.id,
                            'resolved',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Cambio a Resuelto'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard({
    required String title,
    required Map<String, dynamic> userData,
    required Color color,
  }) {
    final email = userData['email'] ?? 'Sin email';
    
    // Intentar obtener el nombre y foto del perfil anidado primero
    String displayName = 'Usuario';
    String profileImage = userData['profile_image_url'] ?? '';
    
    final profiles = userData['profiles'];
    if (profiles is Map && profiles.isNotEmpty) {
      displayName = profiles['full_name'] ?? userData['full_name'] ?? displayName;
      // Si no hay foto en el nivel superior, intentar obtenerla del perfil
      if (profileImage.isEmpty && profiles['profile_image_url'] is String) {
        profileImage = profiles['profile_image_url'] ?? '';
      }
    } else if (userData['full_name'] is String && (userData['full_name'] as String).isNotEmpty) {
      displayName = userData['full_name'];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con icono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contenedor con avatar y datos
          Row(
            children: [
              // Avatar circular
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                  image: profileImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profileImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profileImage.isEmpty
                    ? Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 36,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Datos del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
