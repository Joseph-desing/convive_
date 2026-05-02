import 'package:flutter/material.dart';
import '../models/roommate_search.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../models/match.dart';
import 'chat_screen.dart';
import '../models/profile.dart';
import 'user_profile_screen.dart';

class RoommateSearchDetailsScreen extends StatefulWidget {
  final RoommateSearch search;
  final String? senderUserId; // El usuario que hizo like (opcional, desde notificación)
  
  const RoommateSearchDetailsScreen({
    Key? key, 
    required this.search,
    this.senderUserId,
  }) : super(key: key);

  @override
  State<RoommateSearchDetailsScreen> createState() => _RoommateSearchDetailsScreenState();
}

class _RoommateSearchDetailsScreenState extends State<RoommateSearchDetailsScreen> {
  Profile? _authorProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthor();
  }

  Future<void> _loadAuthor() async {
    try {
      final profile = await SupabaseProvider.databaseService.getProfile(widget.search.userId);
      if (mounted) setState(() { _authorProfile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _returnMatch() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para devolver el match')));
      return;
    }

    try {
      // Obtener perfil del usuario actual para la notificación
      final currentProfile = await SupabaseProvider.databaseService.getProfile(currentUserId);
      
      final match = Match(
        userA: currentUserId,
        userB: widget.search.userId,
        compatibilityScore: 75.0,
        contextType: 'search',
        contextId: widget.search.id,
      );
      
      await SupabaseProvider.databaseService.createMatch(match);
      
      // Enviar notificación al usuario que hizo el like original (asegurar entrega)
      print('📬 Enviando notificación a ${widget.search.userId}...');
      await SupabaseProvider.databaseService.createNotification(
        recipientUserId: widget.search.userId,
        type: 'match',
        senderUserId: currentUserId,
        senderName: currentProfile?.fullName ?? 'Alguien',
        senderProfileImageUrl: currentProfile?.profileImageUrl,
        publicationId: widget.search.id,
        publicationTitle: widget.search.title,
        publicationType: 'roommate',
      );
      print('💚 Match confirmado y notificación enviada al autor de la búsqueda');
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Match confirmado! Ya puedes enviar mensajes')));
      
      // Esperar un poco y volver atrás para que se recarguen los matches
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openChatWithAuthor() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para enviar mensajes')));
      return;
    }

    try {
      final existing = await SupabaseProvider.databaseService.getExistingMatch(currentUserId, widget.search.userId, 'search', widget.search.id);
      if (existing == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitas confirmar el match primero')));
        return;
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: existing.id)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir chat: $e')));
    }
  }

  Future<bool> _hasIncomingLike() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      // Si viene desde una notificación, usamos el senderUserId
      final swiperId = widget.senderUserId ?? widget.search.userId;
      
      print('🔍 Buscando like incoming: swiper=$swiperId, target=$currentUserId');
      
      final swipes = await SupabaseProvider.client
          .from('swipes')
          .select()
          .eq('swiper_id', swiperId)
          .eq('target_user_id', currentUserId)
          .eq('direction', 'like')
          .maybeSingle();
      
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
    if (currentUserId == null) return false;

    try {
      print('🔍 Buscando match existente: user1=$currentUserId, user2=${widget.search.userId}, type=search, id=${widget.search.id}');
      
      final match = await SupabaseProvider.databaseService.getExistingMatch(
        currentUserId, 
        widget.search.userId, 
        'search', 
        widget.search.id
      );
      
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
    final s = widget.search;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Compañero'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta del autor - PRIMERO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.orange.withOpacity(0.2),
                              backgroundImage: _authorProfile?.profileImageUrl != null ? NetworkImage(_authorProfile!.profileImageUrl!) : null,
                              child: _authorProfile?.profileImageUrl == null
                                  ? Text(
                                      (_authorProfile?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _authorProfile?.fullName ?? 'Usuario',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _authorProfile?.bio ?? 'Sin biografía',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<bool>>(
                          future: Future.wait([_hasExistingMatch(), _hasIncomingLike()]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400],
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const CircularProgressIndicator(color: Colors.white),
                                ),
                              );
                            }
                            
                            final hasMatch = snapshot.data?[0] ?? false;
                            final hasIncomingLike = snapshot.data?[1] ?? false;
                            
                            // Si hay match existente, mostrar "Enviar mensaje"
                            if (hasMatch) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openChatWithAuthor,
                                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  label: const Text('Enviar mensaje'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            // Si hay like entrante pero no match, mostrar "Devolver match"
                            if (hasIncomingLike) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _returnMatch,
                                  icon: const Icon(Icons.favorite_rounded),
                                  label: const Text('Devolver match'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            // No mostrar nada si no hay match ni like
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badges con información clave
                  Row(
                    children: [
                      if (s.genderPreference != null && s.genderPreference!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade700.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.pink.shade700.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_rounded, size: 18, color: Colors.pink.shade700),
                              const SizedBox(width: 6),
                              Text(
                                s.genderPreference!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.pink.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money_rounded, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '\$${s.budget.toStringAsFixed(0)}/mes',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: s.includeAlicuota ? Colors.purple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: s.includeAlicuota ? Colors.purple.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_rounded,
                              size: 16,
                              color: s.includeAlicuota ? Colors.purple : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.includeAlicuota ? 'Incluye' : 'No incluye',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: s.includeAlicuota ? Colors.purple : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Descripción
                  Text(
                    'Descripción',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferencias de hábitos
                  if (s.habitsPreferences.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferencias de Hábitos',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: s.habitsPreferences.map((habit) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.teal.withOpacity(0.3)),
                              ),
                              child: Text(
                                habit,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Ubicación
                  Text(
                    'Ubicación',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.address,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coordenadas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${s.latitude?.toStringAsFixed(5) ?? 'N/A'}, ${s.longitude?.toStringAsFixed(5) ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
