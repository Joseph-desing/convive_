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
      return Habits.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Habits> createHabits(Habits habits) async {
    final habitsData = habits.toJson();
    habitsData.remove('createdAt');
    habitsData.remove('updatedAt');
    
    final response = await _supabase
        .from('habits')
        .insert(habitsData)
        .select('*')
        .single();
    return Habits.fromJson(response);
  }

  Future<void> updateHabits(String habitsId,
      Map<String, dynamic> updates) async {
    await _supabase
        .from('habits')
        .update(updates)
        .eq('id', habitsId);
  }

  // ==================== PROPERTIES ====================
  Future<List<Property>> getProperties({int limit = 20, int offset = 0}) async {
    final response = await _supabase
        .from('properties')
        .select('*')
        .eq('is_active', true)
        .range(offset, offset + limit - 1);
    return (response as List).map((p) => Property.fromJson(p)).toList();
  }

  Future<Property> getProperty(String propertyId) async {
    final response = await _supabase
        .from('properties')
        .select('*')
        .eq('id', propertyId)
        .single();
    return Property.fromJson(response);
  }

  Future<List<Property>> getUserProperties(String userId) async {
    final response =
        await _supabase.from('properties').select('*').eq('owner_id', userId);
    return (response as List).map((p) => Property.fromJson(p)).toList();
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

  // ==================== MATCHES ====================
  Future<List<Match>> getUserMatches(String userId) async {
    final response = await _supabase
        .from('matches')
        .select('*')
        .or('user_a.eq.$userId,user_b.eq.$userId');
    return (response as List).map((m) => Match.fromJson(m)).toList();
  }

  Future<Match> createMatch(Match match) async {
    final matchData = match.toJson();
    matchData.remove('createdAt');
    matchData.remove('updatedAt');
    
    final response = await _supabase
        .from('matches')
        .insert(matchData)
        .select('*')
        .single();
    return Match.fromJson(response);
  }

  // ==================== SWIPES ====================
  Future<void> createSwipe(Swipe swipe) async {
    final swipeData = swipe.toJson();
    swipeData.remove('createdAt');
    swipeData.remove('updatedAt');
    
    await _supabase.from('swipes').insert(swipeData);
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
}
