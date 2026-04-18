import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback.dart' show UserFeedback;

class AdminService {
  final SupabaseClient _supabase;

  AdminService(this._supabase);

  // ==================== USERS MANAGEMENT ====================

  /// Obtiene todos los usuarios con sus perfiles
  Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*, profiles(*)')
          .limit(limit)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene usuarios filtrados por rol
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response =
          await _supabase.from('users').select('*, profiles(*)').eq('role', role);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
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

      return {
        'total': (allUsers as List).length,
        'students': (students as List).length,
        'non_students': (nonStudents as List).length,
      };
    } catch (e) {
      return {'total': 0, 'students': 0, 'non_students': 0};
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
          .select('*, profiles(*), property_images(*)')
          .limit(limit)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene propiedades por estado
  Future<List<Map<String, dynamic>>> getPropertiesByStatus(String status) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('*, profiles(*), property_images(*)')
          .eq('status', status);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Actualiza estado de una propiedad
  Future<void> updatePropertyStatus(String propertyId, String status) async {
    try {
      await _supabase
          .from('properties')
          .update({'status': status}).eq('id', propertyId);
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
          await _supabase.from('properties').select('id').eq('status', 'active');
      final inactiveProperties = await _supabase
          .from('properties')
          .select('id')
          .eq('status', 'inactive');

      return {
        'total': (allProperties as List).length,
        'active': (activeProperties as List).length,
        'inactive': (inactiveProperties as List).length,
      };
    } catch (e) {
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

  /// Obtiene todas las estadísticas para el dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersStats = await getUsersStats();
      final propertiesStats = await getPropertiesStats();
      final feedbackStats = await getFeedbackStats();

      return {
        'users': usersStats,
        'properties': propertiesStats,
        'feedback': feedbackStats,
      };
    } catch (e) {
      return {
        'users': {'total': 0, 'students': 0, 'non_students': 0},
        'properties': {'total': 0, 'active': 0, 'inactive': 0},
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
