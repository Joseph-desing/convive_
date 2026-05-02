import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';
import '../models/user.dart' as convive_user;

class SupabaseDatabaseService {
  final SupabaseClient _supabase;

  SupabaseDatabaseService({required SupabaseClient supabase})
      : _supabase = supabase;

  // ==================== USERS ====================
  Future<convive_user.User> getUser(String userId) async {
    final response = await _supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();
    return convive_user.User.fromJson(response);
  }

  Future<convive_user.User> createUser(convive_user.User user) async {
    // No enviar createdAt ni updatedAt, Supabase los genera automáticamente
    final userData = user.toJson();
    userData.remove('createdAt');
    userData.remove('updatedAt');
    
    final response = await _supabase
        .from('users')
        .insert(userData)
        .select('*')
        .single();
    return convive_user.User.fromJson(response);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _supabase
        .from('users')
        .update(updates)
        .eq('id', userId);
  }

  // ==================== PROFILES ====================
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .single();
      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Profile> createProfile(Profile profile) async {
    final profileData = profile.toJson();
    profileData.remove('createdAt');
    profileData.remove('updatedAt');
    
    final response = await _supabase
        .from('profiles')
        .insert(profileData)
        .select('*')
        .single();
    return Profile.fromJson(response);
  }

  Future<void> updateProfile(String profileId,
      Map<String, dynamic> updates) async {
    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', profileId);
  }

  // ==================== HABITS ====================
  Future<Habits?> getHabits(String userId) async {
    try {
      final response = await _supabase
          .from('habits')
          .select('*')
          .eq('user_id', userId)
          .single();

      // Adapt Supabase schema values to model expectations
      final data = Map<String, dynamic>.from(response);
      data['sleep_start'] = _parseHourToInt(data['sleep_start']);
      data['sleep_end'] = _parseHourToInt(data['sleep_end']);
      data['pet_tolerance'] = _boolToTolerance(data['pet_tolerance']);
      // NO convertir work_mode aquí, fromJson lo hace automáticamente
      // communication_style y conflict_management: convertir string a int
      if (data['communication_style'] is String) {
        data['communication_style'] = int.tryParse(data['communication_style']) ?? 5;
      }
      if (data['conflict_management'] is String) {
        data['conflict_management'] = int.tryParse(data['conflict_management']) ?? 5;
      }

      return Habits.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Habits> createHabits(Habits habits) async {
    final habitsData = habits.toJson();
    habitsData.remove('createdAt');
    habitsData.remove('updatedAt');
    habitsData.remove('id'); // Let DB generate ID on upsert

    // Adapt model values to Supabase schema expectations
    habitsData['sleep_start'] = _formatHour(habits.sleepStart);
    habitsData['sleep_end'] = _formatHour(habits.sleepEnd);
    habitsData['pet_tolerance'] = habits.petTolerance >= 5; // boolean in DB
    habitsData['work_mode'] = _mapWorkModeToDb(habits.workMode);

    habitsData['time_at_home'] = habits.timeAtHome.clamp(0, 10);
    habitsData['party_frequency'] = habits.partyFrequency.clamp(0, 7);
    habitsData['alcohol_frequency'] = habits.alcoholFrequency.clamp(0, 7);
    habitsData['cleanliness_level'] = habits.cleanlinessLevel.clamp(1, 10);
    habitsData['noise_tolerance'] = habits.noiseTolerance.clamp(1, 10);
    habitsData['guests_tolerance'] = habits.guestsTolerance.clamp(0, 10);
    habitsData['responsibility_level'] = habits.responsibilityLevel.clamp(1, 10);

    // communication_style y conflict_management son TEXT en DB pero INT en modelo
    // Convertir a string solo si no son null
    habitsData['communication_style'] = habits.communicationStyle?.toString();
    habitsData['conflict_management'] = habits.conflictManagement?.toString();
    
    final response = await _supabase
      .from('habits')
      .upsert(habitsData, onConflict: 'user_id')
      .select('*')
      .single();
    final data = Map<String, dynamic>.from(response);
    data['sleep_start'] = _parseHourToInt(data['sleep_start']);
    data['sleep_end'] = _parseHourToInt(data['sleep_end']);
    data['pet_tolerance'] = _boolToTolerance(data['pet_tolerance']);
    // NO convertir work_mode aquí, dejar que fromJson lo haga
    // communication_style y conflict_management: convertir string a int
    if (data['communication_style'] is String) {
      data['communication_style'] = int.tryParse(data['communication_style']) ?? 5;
    }
    if (data['conflict_management'] is String) {
      data['conflict_management'] = int.tryParse(data['conflict_management']) ?? 5;
    }
    return Habits.fromJson(data);
  }

  Future<void> updateHabits(String habitsId,
      Map<String, dynamic> updates) async {
    await _supabase
        .from('habits')
        .update(updates)
        .eq('id', habitsId);
  }

  // ==================== HELPERS ====================
  int _parseHourToInt(dynamic value) {
    if (value is int) return value;
    if (value is String && value.contains(':')) {
      final parts = value.split(':');
      return int.tryParse(parts.first) ?? 0;
    }
    return 0;
  }

  String _formatHour(int hour) {
    final normalized = hour.clamp(0, 23).toString().padLeft(2, '0');
    return '$normalized:00';
  }

  int _boolToTolerance(dynamic value) {
    if (value is bool) return value ? 10 : 0;
    if (value is num) return value.toInt();
    return 0;
  }

  String _mapWorkModeToDb(WorkMode mode) {
    // Usar los valores que Supabase acepta actualmente
    switch (mode) {
      case WorkMode.remote:
        return 'remote';
      case WorkMode.office:
        return 'office';
      case WorkMode.hybrid:
        return 'hybrid';
    }
  }

  WorkMode _mapWorkModeFromDb(dynamic value) {
    switch (value) {
      case 'remote':
        return WorkMode.remote;
      case 'presencial':
      case 'office':
        return WorkMode.office;
      case 'hibrido':
      case 'hybrid':
      default:
        return WorkMode.hybrid;
    }
  }

  // ==================== PROPERTIES ====================
  Future<List<Property>> getProperties({int limit = 20, int offset = 0, String? excludeUserId}) async {
    try {
      var query = _supabase
          .from('properties')
          .select('*')
          .eq('is_active', true);

      if (excludeUserId != null && excludeUserId.isNotEmpty) {
        query = query.neq('owner_id', excludeUserId);
      }

      // Usar limit directamente sin offset (range tiene limitaciones con pocos registros)
      final response = await query.limit(limit);
      return (response as List).map((p) => Property.fromJson(p)).toList();
    } catch (e) {
      print('❌ Error en getProperties: $e');
      return [];
    }
  }

  Future<Property> getProperty(String propertyId) async {
    final response = await _supabase
        .from('properties')
        .select('*')
        .eq('id', propertyId)
        .single();
    return Property.fromJson(response);
  }

  Future<RoommateSearch> getRoommateSearch(String searchId) async {
    final response = await _supabase
        .from('roommate_searches')
        .select('*')
        .eq('id', searchId)
        .single();
    return RoommateSearch.fromJson(response);
  }

  Future<List<Property>> getUserProperties(String userId) async {
    final response =
        await _supabase.from('properties').select('*').eq('owner_id', userId);
    return (response as List).map((p) => Property.fromJson(p)).toList();
  }

  Future<List<String>> getPropertyImages(String propertyId) async {
    final response = await _supabase
        .from('property_images')
        .select('image_url')
        .eq('property_id', propertyId)
        .order('created_at');
    return (response as List)
        .map((item) => item['image_url'] as String)
        .toList();
  }

  Future<void> addPropertyImage(String propertyId, String imageUrl) async {
    await _supabase.from('property_images').insert({
      'property_id': propertyId,
      'image_url': imageUrl,
    });
  }

  Future<void> deletePropertyImageByUrl(String propertyId, String imageUrl) async {
    await _supabase
        .from('property_images')
        .delete()
        .eq('property_id', propertyId)
        .eq('image_url', imageUrl);
  }

  // ==================== ROOMMATE SEARCH IMAGES ====================
  Future<List<String>> getRoommateSearchImages(String searchId) async {
    try {
      print('🔍 Buscando imágenes para searchId: $searchId');
      final response = await _supabase
          .from('roommate_search_images')
          .select('image_url')
          .eq('search_id', searchId)
          .order('created_at');
      print('✅ Respuesta de roommate_search_images: $response');
      return (response as List)
          .map((item) => item['image_url'] as String)
          .toList();
    } catch (e) {
      print('❌ Error obteniendo imágenes de roommate: $e');
      return [];
    }
  }

  Future<void> addRoommateSearchImage(String searchId, String imageUrl) async {
    await _supabase.from('roommate_search_images').insert({
      'search_id': searchId,
      'image_url': imageUrl,
    });
  }

  Future<void> deleteRoommateSearchImageByUrl(String searchId, String imageUrl) async {
    await _supabase
        .from('roommate_search_images')
        .delete()
        .eq('search_id', searchId)
        .eq('image_url', imageUrl);
  }

  /// Obtener búsquedas de compañero del usuario
  Future<List<RoommateSearch>> getUserRoommateSearches(String userId) async {
    final response = await _supabase
        .from('roommate_searches')
        .select('*')
        .eq('user_id', userId);
    return (response as List).map((r) => RoommateSearch.fromJson(r)).toList();
  }

  Future<Property> createProperty(Property property) async {
    final propertyData = property.toJson();
    propertyData.remove('createdAt');
    propertyData.remove('updatedAt');
    
    final response = await _supabase
        .from('properties')
        .insert(propertyData)
        .select('*')
        .single();
    return Property.fromJson(response);
  }

  Future<void> updateProperty(String propertyId,
      Map<String, dynamic> updates) async {
    await _supabase
        .from('properties')
        .update(updates)
        .eq('id', propertyId);
  }

  /// Actualizar una búsqueda de compañero
  Future<void> updateRoommateSearch(String searchId,
      Map<String, dynamic> updates) async {
    await _supabase
        .from('roommate_searches')
        .update(updates)
        .eq('id', searchId);
  }

  /// Crear una nueva búsqueda de compañero
  Future<RoommateSearch> createRoommateSearch(RoommateSearch search) async {
    final response = await _supabase
        .from('roommate_searches')
        .insert(search.toJson())
        .select()
        .single();
    return RoommateSearch.fromJson(response);
  }

  // ==================== MATCHES ====================
  Future<List<Match>> getUserMatches(String userId) async {
    try {
      print('🔍 Consultando matches para usuario: $userId');
      final response = await _supabase
          .from('matches')
          .select('*')
          .or('user_a_id.eq.$userId,user_b_id.eq.$userId');
      
      print('✅ Matches encontrados: ${(response as List).length}');
      return (response as List).map((m) => Match.fromJson(m)).toList();
    } catch (e) {
      print('❌ Error al obtener matches: $e');
      return [];
    }
  }

  Future<Match?> getMatch(String matchId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*')
          .eq('id', matchId)
          .single();
      return Match.fromJson(response);
    } catch (e) {
      print('❌ Error obteniendo match: $e');
      return null;
    }
  }

  Future<Match> createMatch(Match match) async {
    // Normalizar el orden para evitar duplicados (A,B) y (B,A)
    final ordered = [match.userA, match.userB]..sort();

    final matchData = match.toJson();
    matchData['user_a_id'] = ordered.first;
    matchData['user_b_id'] = ordered.last;
    // Asegurar que contextType nunca sea null
    matchData['context_type'] = match.contextType ?? 'general';
    // Si contextId es null, usar string 'null' para la BD
    if (matchData['context_id'] == null) {
      matchData['context_id'] = null; // Supabase manejará null correctamente
    }
    // No enviar ID para no intentar actualizar la PK en caso de conflicto
    matchData.remove('id');
    matchData.remove('createdAt');
    matchData.remove('updatedAt');

    try {
      print('💾 Guardando match: ${matchData['user_a_id']} <-> ${matchData['user_b_id']}');
      
      // upsert evita el error de unique; devuelve la fila existente o la nueva
      final response = await _supabase
          .from('matches')
          .upsert(
            matchData,
            onConflict: 'user_a_id,user_b_id,context_type,context_id',
          )
          .select('*')
          .single();

      print('✅ Match guardado exitosamente: ${response['id']}');
      return Match.fromJson(response);
    } catch (e) {
      print('❌ Error al guardar match: $e');
      rethrow;
    }
  }

  // ==================== SWIPES ====================
  Future<void> createSwipe(Swipe swipe) async {
    final swipeData = swipe.toJson();
    swipeData.remove('createdAt');
    swipeData.remove('updatedAt');

    // Evitar violar la restricción única (swiper_id, target_user_id).
    // Si ya existe un swipe previo, lo actualizamos con la nueva dirección.
    await _supabase
        .from('swipes')
        .upsert(
          swipeData,
          onConflict: 'swiper_id,target_user_id',
        )
        .select('id')
        .maybeSingle();
  }

  /// Registrar un "super-like" en la base reutilizando la dirección 'like'
  /// para mantener compatibilidad con la restricción CHECK actual.
  Future<void> createSuperLike(String swiperId, String targetUserId) async {
    final swipeData = {
      'swiper_id': swiperId,
      'target_user_id': targetUserId,
      // Guardar como 'like' en la tabla para evitar violar el check constraint
      'direction': 'like',
    };

    await _supabase
        .from('swipes')
        .upsert(
          swipeData,
          onConflict: 'swiper_id,target_user_id',
        )
        .select('id')
        .maybeSingle();
  }

  /// Verifica si `swiperId` ya hizo like hacia `targetUserId`.
  Future<bool> hasSwipedLikeOrSuper(String swiperId, String targetUserId) async {
    try {
      final response = await _supabase
          .from('swipes')
          .select('id')
          .eq('swiper_id', swiperId)
          .eq('target_user_id', targetUserId)
          .eq('direction', 'like')
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error verificando like/super_like: $e');
      return false;
    }
  }

  Future<bool> hasSwipedBefore(String swiperId, String targetUserId) async {
    try {
      await _supabase
          .from('swipes')
          .select('id')
          .eq('swiper_id', swiperId)
          .eq('target_user_id', targetUserId)
          .single();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasSwipedLike(String swiperId, String targetUserId) async {
    try {
      print('🔍 Verificando si $swiperId dio like a $targetUserId');

      // Evitar el error 406 cuando existen varias filas: limitamos a la primera coincidencia
      final response = await _supabase
          .from('swipes')
          .select('id')
          .eq('swiper_id', swiperId)
          .eq('target_user_id', targetUserId)
          .eq('direction', 'like')
          .limit(1)
          .maybeSingle();

      final hasLiked = response != null;
      print(hasLiked ? '✅ Sí dio like!' : '❌ No ha dado like');
      return hasLiked;
    } catch (e) {
      print('❌ Error verificando like: $e');
      return false;
    }
  }

  /// Verificar si hay un swipe mutuo LIKE entre dos usuarios
  Future<bool> checkMutualLike(String userId1, String userId2) async {
    try {
      // Verificar si ambos hicieron swipe LIKE entre sí
        final swipe1 = await _supabase
          .from('swipes')
          .select('id')
          .eq('swiper_id', userId1)
          .eq('target_user_id', userId2)
          .eq('direction', 'like')
          .limit(1)
          .maybeSingle();

        final swipe2 = await _supabase
          .from('swipes')
          .select('id')
          .eq('swiper_id', userId2)
          .eq('target_user_id', userId1)
          .eq('direction', 'like')
          .limit(1)
          .maybeSingle();

      // Si ambos swipes existen, hay match mutuo
      return swipe1 != null && swipe2 != null;
    } catch (e) {
      print('Error verificando swipe mutuo: $e');
      return false;
    }
  }

  /// Verificar si ya existe un match entre dos usuarios (filtrando por contexto)
  Future<Match?> getExistingMatch(String userId1, String userId2, 
      [String? contextType, String? contextId]) async {
    try {
      // Normalizar orden de usuarios
      final ordered = [userId1, userId2]..sort();
      final ua = ordered.first;
      final ub = ordered.last;
      
      // Normalizar contextType (default 'general' si es null)
      final ct = contextType ?? 'general';
      
      // Buscar match con el mismo contexto exacto
      final response = await _supabase
          .from('matches')
          .select('*')
          .eq('user_a_id', ua)
          .eq('user_b_id', ub)
          .eq('context_type', ct)
          .eq('context_id', contextId ?? 'null')
          .maybeSingle();

      if (response == null) return null;
      return Match.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Eliminar un match (cascade eliminará chat y mensajes asociados)
  Future<void> deleteMatch(String matchId) async {
    await _supabase
        .from('matches')
        .delete()
        .eq('id', matchId);
  }

  // ==================== NOTIFICACIONES ====================
  /// Crear una notificación
  Future<void> createNotification({
    required String recipientUserId,
    required String type, // 'match', 'like', 'system'
    String? senderUserId,
    String? senderName,
    String? senderProfileImageUrl,
    String? publicationId,
    String? publicationTitle,
    String? publicationType, // 'roommate' o 'departamento'
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'recipient_user_id': recipientUserId,
        'type': type,
        'sender_user_id': senderUserId,
        'sender_user_name': senderName,
        'sender_profile_image_url': senderProfileImageUrl,
        'publication_id': publicationId,
        'publication_title': publicationTitle,
        'publication_type': publicationType,
        'read': false,
        // Supabase generará created_at con now() automáticamente en el servidor
      });
      print('📨 Notificación creada: $type para $recipientUserId');
    } catch (e) {
      print('❌ Error creando notificación: $e');
    }
  }

  // ==================== ELIMINAR PUBLICACIONES ====================
  /// Eliminar una propiedad
  Future<void> deleteProperty(String propertyId) async {
    try {
      await _supabase
          .from('properties')
          .delete()
          .eq('id', propertyId);
    } catch (e) {
      print('Error eliminando propiedad: $e');
      rethrow;
    }
  }

  /// Eliminar una búsqueda de compañero
  Future<void> deleteRoommateSearch(String searchId) async {
    try {
      await _supabase
          .from('roommate_searches')
          .delete()
          .eq('id', searchId);
    } catch (e) {
      print('Error eliminando búsqueda de compañero: $e');
      rethrow;
    }
  }
}
