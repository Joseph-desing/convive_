import 'package:flutter/material.dart';
import '../config/supabase_provider.dart';
import '../models/profile.dart';
import '../models/habits.dart';
import '../models/match.dart';
import '../models/property.dart';
import '../models/roommate_search.dart';
import 'chat_screen.dart';
import '../utils/colors.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? senderUserId; // El usuario que hizo like (opcional, desde notificación)
  final String? publicationType; // 'roommate' | 'departamento' | 'profile'
  final String? publicationId;   // ID de la propiedad o búsqueda de roommate

  const UserProfileScreen({
    Key? key,
    required this.userId,
    this.senderUserId,
    this.publicationType,
    this.publicationId,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Profile? _profile;
  Habits? _habits;
  Property? _mainProperty; // Propiedad para mostrar ubicación
  RoommateSearch? _roommateSearch; // Búsqueda de roommate para ubicación
  bool _loading = true;
  String? _error;
  late Future<List<bool>> _buttonStateFuture;

  @override
  void initState() {
    super.initState();
    _load();
    // Cachear el futuro para evitar múltiples ejecuciones
    _buttonStateFuture = Future.wait([_hasExistingMatch(), _hasIncomingLike()]);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await SupabaseProvider.databaseService.getProfile(widget.userId);
      final habits = await SupabaseProvider.databaseService.getHabits(widget.userId);
      
      setState(() {
        _profile = profile;
        _habits = habits;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
    return age;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ');
    return parts.length > 1
        ? (parts[0][0] + parts[1][0]).toUpperCase()
        : name[0].toUpperCase();
  }

  /// Determina el contextType correcto según el tipo de publicación que recibió el like
  String _resolveContextType() {
    final pubType = widget.publicationType;
    if (pubType == 'departamento' || pubType == 'property') return 'property';
    if (pubType == 'roommate') return 'search';
    return 'profile'; // Fallback para likes de perfil directo
  }

  /// Determina el contextId correcto: ID de la publicación o del usuario como fallback
  String _resolveContextId() {
    final pubId = widget.publicationId;
    if (pubId != null && pubId.isNotEmpty) return pubId;
    return widget.userId; // Fallback
  }

  Future<void> _returnMatch() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para devolver el match')));
      return;
    }

    try {
      print('🚀 Iniciando creación de match...');

      // ✅ Determinar contexto correcto según el tipo de publicación que recibió el like
      final contextType = _resolveContextType();
      final contextId = _resolveContextId();
      print('📌 Contexto del match: type=$contextType, id=$contextId');

      // Obtener perfiles para la notificación
      final currentProfile = await SupabaseProvider.databaseService.getProfile(currentUserId);

      // ✅ Crear el match bilateral con contexto correcto
      final compatibility = _calculateCompatibilityScore();
      final match = Match(
        userA: currentUserId,
        userB: widget.userId,
        compatibilityScore: compatibility,
        contextType: contextType,  // ✅ 'property' | 'search' | 'profile'
        contextId: contextId,      // ✅ ID real de la publicación
      );

      print('📋 Match object creado: userA=$currentUserId, userB=${widget.userId}, type=$contextType');

      final createdMatch = await SupabaseProvider.databaseService.createMatch(match);
      print('✅ Match creado con ID: ${createdMatch.id}');

      // ✅ Limpiar notificaciones antiguas de match entre estos dos usuarios
      // para evitar que queden duplicadas del código anterior o de intentos fallidos
      await SupabaseProvider.databaseService.deleteMatchNotificationsFrom(
        recipientUserId: widget.userId,
        senderUserId: currentUserId,
      );
      print('🗑️ Notificaciones antiguas limpiadas');

      // ✅ Notificación con publicationType correcto según contexto
      final notifPubType = contextType == 'property' ? 'departamento' : (contextType == 'search' ? 'roommate' : 'profile');
      print('📬 Enviando notificación a ${widget.userId} (pubType=$notifPubType)...');
      await SupabaseProvider.databaseService.createNotification(
        recipientUserId: widget.userId,
        type: 'match_confirmed',   // ✅ Tipo distinto para evitar anti-duplicado
        senderUserId: currentUserId,
        senderName: currentProfile?.fullName ?? 'Alguien',
        senderProfileImageUrl: currentProfile?.profileImageUrl,
        publicationId: contextId,
        publicationTitle: currentProfile?.fullName ?? 'Alguien',
        publicationType: notifPubType, // ✅ 'departamento' | 'roommate' | 'profile'
      );
      print('💚 Match confirmado y notificación enviada al usuario');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Match confirmado! Ya puedes enviar mensajes')));
      }

      // Esperar un poco y volver atrás para que se recarguen los matches
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ ERROR EN _returnMatch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error confirmando match: $e')));
      }
    }
  }

  double _calculateCompatibilityScore() {
    // Aquí puedes implementar la lógica de compatibilidad
    return 75.0; // Valor por defecto
  }

  Future<void> _openChat() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para enviar mensajes')));
      return;
    }

    try {
      // ✅ Buscar match con el contexto correcto
      final contextType = _resolveContextType();
      final contextId = _resolveContextId();
      final existing = await SupabaseProvider.databaseService.getExistingMatch(
        currentUserId, widget.userId, contextType, contextId,
      );
      if (existing == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitas confirmar el match primero')));
        return;
      }
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: existing.id)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir chat: $e')));
    }
  }

  Future<bool> _hasIncomingLike() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      print('❌ No hay usuario autenticado');
      return false;
    }

    try {
      // Si viene desde una notificación, usamos el senderUserId
      final swiperId = widget.senderUserId ?? widget.userId;
      
      print('🔍 Buscando like incoming: swiper=$swiperId, target=$currentUserId');
      
      // Query con timeout
      final swipes = await SupabaseProvider.client
          .from('swipes')
          .select()
          .eq('swiper_id', swiperId)
          .eq('target_user_id', currentUserId)
          .eq('direction', 'like')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      
      final hasLike = swipes != null;
      print('${hasLike ? '✅' : '❌'} Like incoming encontrado: $hasLike');
      return hasLike;
    } catch (e) {
      print('❌ Error en _hasIncomingLike: $e');
      return false;
    }
  }

  Future<bool> _hasExistingMatch() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      print('❌ No hay usuario autenticado para verificar match');
      return false;
    }

    try {
      // ✅ Buscar match con el contexto correcto
      final contextType = _resolveContextType();
      final contextId = _resolveContextId();
      print('🔍 Buscando match existente: user1=$currentUserId, user2=${widget.userId}, type=$contextType, id=$contextId');
      final match = await SupabaseProvider.databaseService
          .getExistingMatch(currentUserId, widget.userId, contextType, contextId)
          .timeout(const Duration(seconds: 5));

      final hasMatch = match != null;
      print('${hasMatch ? '✅' : '❌'} Match existente encontrado: $hasMatch');
      return hasMatch;
    } catch (e) {
      print('❌ Error en _hasExistingMatch: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil público'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Error al cargar perfil', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : _profile == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Perfil no encontrado', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ENCABEZADO CON FOTO Y NOMBRE
                          _buildHeader(),
                          const SizedBox(height: 24),
                          
                          // INFORMACIÓN PRINCIPAL
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre y edad
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _profile!.fullName ?? 'Usuario',
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                              ),
                                              if (_profile!.verified)
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 8),
                                                  child: Icon(Icons.verified, color: Colors.blue, size: 24),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_calculateAge(_profile!.birthDate)} años',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // BIO
                                if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Acerca de mí',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _profile!.bio!,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[800],
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // HÁBITOS
                                if (_habits != null) ...[
                                  Text(
                                    'Hábitos y Preferencias',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildHabitCard('Limpieza', _habits!.cleanlinessLevel, Icons.cleaning_services_outlined, Colors.blue),
                                  const SizedBox(height: 10),
                                  _buildHabitCard('Tolerancia al ruido', _habits!.noiseTolerance, Icons.volume_up_outlined, Colors.orange),
                                  const SizedBox(height: 10),
                                  _buildHabitCard('Fiestas por semana', _habits!.partyFrequency, Icons.celebration_outlined, Colors.purple),
                                  const SizedBox(height: 10),
                                  _buildHabitCard('Tolerancia a mascotas', _habits!.petTolerance, Icons.pets_outlined, Colors.pink),
                                  const SizedBox(height: 10),
                                  _buildHabitCard('Tolerancia a invitados', _habits!.guestsTolerance, Icons.people_outlined, Colors.green),
                                  const SizedBox(height: 10),
                                  _buildBoolHabit('Tiene mascotas', _habits!.pets),
                                  const SizedBox(height: 20),
                                ],
                              ],
                            ),
                          ),
                          
                          // BOTONES DE ACCIÓN
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: FutureBuilder<List<bool>>(
                              future: _buttonStateFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const CircularProgressIndicator(color: Colors.white),
                                    ),
                                  );
                                }
                                
                                if (snapshot.hasError) {
                                  print('❌ Error en FutureBuilder: ${snapshot.error}');
                                  return const SizedBox.shrink();
                                }
                                
                                final hasMatch = snapshot.data?[0] ?? false;
                                final hasIncomingLike = snapshot.data?[1] ?? false;
                                
                                print('📊 Estado botones - Match: $hasMatch, Like: $hasIncomingLike');
                                
                                // Si hay like incoming, PRIORIZAR "Devolver match"
                                if (hasIncomingLike) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _returnMatch,
                                      icon: const Icon(Icons.favorite_rounded),
                                      label: const Text(
                                        'Devolver match',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                    ),
                                  );
                                }
                                
                                // Si ya existe match (sin like pendiente), mostrar "Enviar mensaje"
                                if (hasMatch) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _openChat,
                                      icon: const Icon(Icons.mail_outline),
                                      label: const Text(
                                        'Enviar mensaje',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 2,
                                      ),
                                    ),
                                  );
                                }
                                
                                // No mostrar nada si no hay match ni like
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar grande
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.white,
                  backgroundImage: _profile!.profileImageUrl != null
                      ? NetworkImage(_profile!.profileImageUrl!)
                      : null,
                  child: _profile!.profileImageUrl == null
                      ? Text(
                          _getInitials(_profile!.fullName),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(String label, int value, IconData icon, Color color) {
    final percentage = (value / 10 * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 10,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value/10',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolHabit(String label, bool value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Text(
            value ? 'Sí' : 'No',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: value ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
