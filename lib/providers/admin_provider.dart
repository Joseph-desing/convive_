import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback.dart' show UserFeedback, FeedbackStatus;
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  late AdminService _adminService;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estado
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> allProperties = [];
  List<UserFeedback> allFeedback = [];
  Map<String, dynamic> dashboardStats = {};

  bool isLoading = false;
  String? errorMessage;

  // Filtros
  String selectedUserFilter = 'all'; // all, student, non_student, admin
  String selectedPropertyFilter = 'all'; // all, active, inactive
  String selectedFeedbackFilter = 'all'; // all, open, resolved, closed

  AdminProvider() {
    _adminService = AdminService(_supabase);
  }

  // ==================== USERS MANAGEMENT ====================

  Future<void> loadAllUsers({int limit = 50, int offset = 0}) async {
    try {
      _setLoading(true);
      allUsers = await _adminService.getAllUsers(limit: limit, offset: offset);
      _clearError();
    } catch (e) {
      _setError('Error loading users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUsersByRole(String role) async {
    try {
      _setLoading(true);
      allUsers = await _adminService.getUsersByRole(role);
      selectedUserFilter = role;
      _clearError();
    } catch (e) {
      _setError('Error loading users by role: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      _setLoading(true);
      await _adminService.updateUserRole(userId, newRole);
      
      // Actualizar en la lista local
      final userIndex = allUsers.indexWhere((u) => u['id'] == userId);
      if (userIndex != -1) {
        allUsers[userIndex]['role'] = newRole;
        notifyListeners();
      }
      
      _clearError();
    } catch (e) {
      _setError('Error updating user role: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> suspendUser(String userId, bool suspend) async {
    try {
      _setLoading(true);
      await _adminService.suspendUser(userId, suspend);
      
      // Actualizar en la lista local
      final userIndex = allUsers.indexWhere((u) => u['id'] == userId);
      if (userIndex != -1) {
        allUsers[userIndex]['is_suspended'] = suspend;
        notifyListeners();
      }
      
      _clearError();
    } catch (e) {
      _setError('Error suspending user: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUsersStats() async {
    try {
      _setLoading(true);
      final stats = await _adminService.getUsersStats();
      dashboardStats['users'] = stats;
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Error loading users stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== PROPERTIES MANAGEMENT ====================

  Future<void> loadAllProperties({int limit = 50, int offset = 0}) async {
    try {
      _setLoading(true);
      allProperties =
          await _adminService.getAllProperties(limit: limit, offset: offset);
      _clearError();
    } catch (e) {
      _setError('Error loading properties: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPropertiesByStatus(String status) async {
    try {
      _setLoading(true);
      allProperties = await _adminService.getPropertiesByStatus(status);
      selectedPropertyFilter = status;
      _clearError();
    } catch (e) {
      _setError('Error loading properties by status: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePropertyStatus(String propertyId, String newStatus) async {
    try {
      _setLoading(true);
      await _adminService.updatePropertyStatus(propertyId, newStatus);
      
      // Actualizar en la lista local
      final propIndex =
          allProperties.indexWhere((p) => p['id'] == propertyId);
      if (propIndex != -1) {
        allProperties[propIndex]['status'] = newStatus;
        notifyListeners();
      }
      
      _clearError();
    } catch (e) {
      _setError('Error updating property status: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      _setLoading(true);
      await _adminService.deleteProperty(propertyId);
      
      // Remover de la lista local
      allProperties.removeWhere((p) => p['id'] == propertyId);
      notifyListeners();
      
      _clearError();
    } catch (e) {
      _setError('Error deleting property: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPropertiesStats() async {
    try {
      _setLoading(true);
      final stats = await _adminService.getPropertiesStats();
      dashboardStats['properties'] = stats;
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Error loading properties stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== FEEDBACK MANAGEMENT ====================

  Future<void> loadAllFeedback({int limit = 50, int offset = 0}) async {
    try {
      _setLoading(true);
      allFeedback =
          await _adminService.getAllFeedback(limit: limit, offset: offset);
      _clearError();
    } catch (e) {
      _setError('Error loading feedback: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeedbackByStatus(String status) async {
    try {
      _setLoading(true);
      allFeedback = await _adminService.getFeedbackByStatus(status);
      selectedFeedbackFilter = status;
      _clearError();
    } catch (e) {
      _setError('Error loading feedback by status: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeedbackByType(String type) async {
    try {
      _setLoading(true);
      allFeedback = await _adminService.getFeedbackByType(type);
      _clearError();
    } catch (e) {
      _setError('Error loading feedback by type: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateFeedbackStatus(String feedbackId, String newStatus) async {
    try {
      _setLoading(true);
      await _adminService.updateFeedbackStatus(feedbackId, newStatus);
      
      // Actualizar en la lista local
      final fbIndex = allFeedback.indexWhere((f) => f.id == feedbackId);
      if (fbIndex != -1) {
        allFeedback[fbIndex] = allFeedback[fbIndex].copyWith(
          status: newStatus == 'open'
              ? FeedbackStatus.open
              : newStatus == 'in_review'
                  ? FeedbackStatus.in_review
                  : newStatus == 'resolved'
                      ? FeedbackStatus.resolved
                      : FeedbackStatus.closed,
        );
        notifyListeners();
      }
      
      _clearError();
    } catch (e) {
      _setError('Error updating feedback status: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> respondToFeedback(
    String feedbackId,
    String response,
    String adminId,
  ) async {
    try {
      _setLoading(true);
      await _adminService.respondToFeedback(feedbackId, response, adminId);
      
      // Actualizar en la lista local
      final fbIndex = allFeedback.indexWhere((f) => f.id == feedbackId);
      if (fbIndex != -1) {
        allFeedback[fbIndex] = allFeedback[fbIndex].copyWith(
          adminResponse: response,
          status: FeedbackStatus.resolved,
          adminResponseAt: DateTime.now(),
          resolvedBy: adminId,
        );
        notifyListeners();
      }
      
      _clearError();
    } catch (e) {
      _setError('Error responding to feedback: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> closeFeedback(String feedbackId) async {
    try {
      _setLoading(true);
      await _adminService.closeFeedback(feedbackId);
      
      // Actualizar en la lista local
      final fbIndex = allFeedback.indexWhere((f) => f.id == feedbackId);
      if (fbIndex != -1) {
        allFeedback[fbIndex] =
            allFeedback[fbIndex].copyWith(status: FeedbackStatus.closed);
        notifyListeners();
      }
      
      _clearError();
    } catch (e) {
      _setError('Error closing feedback: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeedbackStats() async {
    try {
      _setLoading(true);
      final stats = await _adminService.getFeedbackStats();
      dashboardStats['feedback'] = stats;
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Error loading feedback stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== DASHBOARD STATS ====================

  Future<void> loadDashboardStats() async {
    try {
      _setLoading(true);
      dashboardStats = await _adminService.getDashboardStats();
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Error loading dashboard stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== HELPER METHODS ====================

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    errorMessage = null;
  }

  void resetFilters() {
    selectedUserFilter = 'all';
    selectedPropertyFilter = 'all';
    selectedFeedbackFilter = 'all';
    notifyListeners();
  }
}
