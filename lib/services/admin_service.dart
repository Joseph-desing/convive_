import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback.dart' show UserFeedback;

class AdminService {
  final SupabaseClient _supabase;

  AdminService(this._supabase);

  // ==================== USERS MANAGEMENT ====================

  /// Obtiene todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .limit(limit)
          .range(offset, offset + limit - 1);
      
      final users = List<Map<String, dynamic>>.from(response);
      print('✅ getAllUsers: ${users.length} usuarios cargados');
      return users;
    } catch (e) {
      print('❌ getAllUsers error: $e');
      return [];
    }
  }

  /// Obtiene usuarios filtrados por rol
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response =
          await _supabase.from('users').select('*').eq('role', role);
      
      final users = List<Map<String, dynamic>>.from(response);
      print('✅ getUsersByRole($role): ${users.length} usuarios');
      return users;
    } catch (e) {
      print('❌ getUsersByRole error: $e');
      return [];
    }
  }

  /// Actualiza el rol de un usuario
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  /// Suspende/desactiva un usuario
  Future<void> suspendUser(String userId, bool suspend) async {
    try {
      await _supabase
          .from('users')
          .update({'is_suspended': suspend}).eq('id', userId);
    } catch (e) {
      throw Exception('Error suspending user: $e');
    }
  }

  /// Obtiene estadísticas de usuarios
  Future<Map<String, dynamic>> getUsersStats() async {
    try {
      final allUsers = await _supabase.from('users').select('id');
      final students =
          await _supabase.from('users').select('id').eq('role', 'student');
      final nonStudents = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'non_student');
      final admins =
          await _supabase.from('users').select('id').eq('role', 'admin');

      final totalCount = (allUsers as List).length;
      final studentCount = (students as List).length;
      final nonStudentCount = (nonStudents as List).length;
      final adminCount = (admins as List).length;

      print('📊 Users Stats - Total: $totalCount, Students: $studentCount, Non-Students: $nonStudentCount, Admins: $adminCount');

      return {
        'total': totalCount,
        'students': studentCount,
        'non_students': nonStudentCount,
        'admins': adminCount,
      };
    } catch (e) {
      print('❌ getUsersStats error: $e');
      return {'total': 0, 'students': 0, 'non_students': 0, 'admins': 0};
    }
  }

  // ==================== PROPERTIES MANAGEMENT ====================

  /// Obtiene todas las propiedades
  Future<List<Map<String, dynamic>>> getAllProperties({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*')
          .limit(limit)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching properties: $e');
      return [];
    }
  }

  /// Obtiene propiedades por estado (is_active: true o false)
  Future<List<Map<String, dynamic>>> getPropertiesByStatus(String status) async {
    try {
      final isActive = status.toLowerCase() == 'active' ? true : false;
      final response = await _supabase
          .from('properties')
          .select('*')
          .eq('is_active', isActive);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching properties by status: $e');
      return [];
    }
  }

  /// Actualiza estado de una propiedad (is_active: true o false)
  Future<void> updatePropertyStatus(String propertyId, String status) async {
    try {
      final isActive = status.toLowerCase() == 'active' ? true : false;
      await _supabase
          .from('properties')
          .update({'is_active': isActive}).eq('id', propertyId);
    } catch (e) {
      throw Exception('Error updating property status: $e');
    }
  }

  /// Elimina una propiedad
  Future<void> deleteProperty(String propertyId) async {
    try {
      await _supabase
          .from('property_images')
          .delete()
          .eq('property_id', propertyId);
      await _supabase.from('properties').delete().eq('id', propertyId);
    } catch (e) {
      throw Exception('Error deleting property: $e');
    }
  }

  /// Obtiene estadísticas de propiedades
  Future<Map<String, dynamic>> getPropertiesStats() async {
    try {
      final allProperties = await _supabase.from('properties').select('id');
      final activeProperties =
          await _supabase.from('properties').select('id').eq('is_active', true);
      final inactiveProperties = await _supabase
          .from('properties')
          .select('id')
          .eq('is_active', false);

      final totalCount = (allProperties as List).length;
      final activeCount = (activeProperties as List).length;
      final inactiveCount = (inactiveProperties as List).length;

      print('Properties Stats - Total: $totalCount, Active: $activeCount, Inactive: $inactiveCount');

      return {
        'total': totalCount,
        'active': activeCount,
        'inactive': inactiveCount,
      };
    } catch (e) {
      print('Error fetching properties stats: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // ==================== FEEDBACK MANAGEMENT ====================

  /// Obtiene todos los feedbacks
  Future<List<UserFeedback>> getAllFeedback({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select()
          .limit(limit)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      return (response as List)
          .map((f) => UserFeedback.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene feedback filtrado por estado
  Future<List<UserFeedback>> getFeedbackByStatus(String status) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);
      return (response as List)
          .map((f) => UserFeedback.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene feedback filtrado por tipo
  Future<List<UserFeedback>> getFeedbackByType(String type) async {
    try {
      final response = await _supabase
          .from('feedback')
          .select()
          .eq('type', type)
          .order('created_at', ascending: false);
      return (response as List)
          .map((f) => UserFeedback.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualiza estado del feedback
  Future<void> updateFeedbackStatus(String feedbackId, String newStatus) async {
    try {
      await _supabase.from('feedback').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', feedbackId);
    } catch (e) {
      throw Exception('Error updating feedback status: $e');
    }
  }

  /// Responde a un feedback
  Future<void> respondToFeedback(
    String feedbackId,
    String response,
    String adminId,
  ) async {
    try {
      await _supabase.from('feedback').update({
        'admin_response': response,
        'admin_response_at': DateTime.now().toIso8601String(),
        'resolved_by': adminId,
        'status': 'resolved',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', feedbackId);
    } catch (e) {
      throw Exception('Error responding to feedback: $e');
    }
  }

  /// Cierra un feedback
  Future<void> closeFeedback(String feedbackId) async {
    try {
      await _supabase.from('feedback').update({
        'status': 'closed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', feedbackId);
    } catch (e) {
      throw Exception('Error closing feedback: $e');
    }
  }

  /// Obtiene estadísticas de feedback
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final allFeedback = await _supabase.from('feedback').select('id');
      final openFeedback =
          await _supabase.from('feedback').select('id').eq('status', 'open');
      final resolvedFeedback = await _supabase
          .from('feedback')
          .select('id')
          .eq('status', 'resolved');
      final complaints =
          await _supabase.from('feedback').select('id').eq('type', 'complaint');
      final suggestions = await _supabase
          .from('feedback')
          .select('id')
          .eq('type', 'suggestion');

      return {
        'total': (allFeedback as List).length,
        'open': (openFeedback as List).length,
        'resolved': (resolvedFeedback as List).length,
        'complaints': (complaints as List).length,
        'suggestions': (suggestions as List).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'open': 0,
        'resolved': 0,
        'complaints': 0,
        'suggestions': 0
      };
    }
  }

  // ==================== ROOMMATE SEARCHES MANAGEMENT ====================

  /// Obtiene todas las búsquedas de roommates
  Future<List<Map<String, dynamic>>> getAllRoommateSearches({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('roommate_searches')
          .select('*')
          .limit(limit)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      
      final searches = List<Map<String, dynamic>>.from(response);
      print('✅ getAllRoommateSearches: ${searches.length} búsquedas cargadas');
      return searches;
    } catch (e) {
      print('❌ getAllRoommateSearches error: $e');
      return [];
    }
  }

  /// Obtiene búsquedas de roommates por estado
  Future<List<Map<String, dynamic>>> getRoommateSearchesByStatus(String status) async {
    try {
      // Por ahora, simplemente retorna todas las búsquedas
      // Ya que la tabla no tiene un campo is_active
      final response = await _supabase
          .from('roommate_searches')
          .select('*')
          .order('created_at', ascending: false);
      
      final searches = List<Map<String, dynamic>>.from(response);
      print('✅ getRoommateSearchesByStatus($status): ${searches.length} búsquedas');
      return searches;
    } catch (e) {
      print('❌ getRoommateSearchesByStatus error: $e');
      return [];
    }
  }

  /// Actualiza estado de una búsqueda de roommate
  Future<void> updateRoommateSearchStatus(String searchId, String status) async {
    try {
      // Por ahora, no actualiza nada ya que no existe el campo is_active
      // En el futuro, esto podría actualizar otro campo
      print('⏸️ updateRoommateSearchStatus: Método disponible en futuras versiones');
    } catch (e) {
      throw Exception('Error updating roommate search status: $e');
    }
  }

  /// Elimina una búsqueda de roommate
  Future<void> deleteRoommateSearch(String searchId) async {
    try {
      await _supabase
          .from('roommate_search_images')
          .delete()
          .eq('search_id', searchId);
      await _supabase
          .from('roommate_searches')
          .delete()
          .eq('id', searchId);
    } catch (e) {
      throw Exception('Error deleting roommate search: $e');
    }
  }

  /// Obtiene estadísticas de búsquedas de roommates
  Future<Map<String, dynamic>> getRoommateSearchesStats() async {
    try {
      final allSearches = await _supabase.from('roommate_searches').select('id');

      final totalCount = (allSearches as List).length;

      print('🏠 Roommate Searches Stats - Total: $totalCount');

      return {
        'total': totalCount,
        'active': totalCount,
        'inactive': 0,
      };
    } catch (e) {
      print('❌ getRoommateSearchesStats error: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  /// Obtiene todas las estadísticas para el dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersStats = await getUsersStats();
      final propertiesStats = await getPropertiesStats();
      final roommateSearchesStats = await getRoommateSearchesStats();
      final feedbackStats = await getFeedbackStats();

      return {
        'users': usersStats,
        'properties': propertiesStats,
        'roommateSearches': roommateSearchesStats,
        'feedback': feedbackStats,
      };
    } catch (e) {
      return {
        'users': {'total': 0, 'students': 0, 'non_students': 0},
        'properties': {'total': 0, 'active': 0, 'inactive': 0},
        'roommateSearches': {'total': 0, 'active': 0, 'inactive': 0},
        'feedback': {
          'total': 0,
          'open': 0,
          'resolved': 0,
          'complaints': 0,
          'suggestions': 0
        },
      };
    }
  }
}
