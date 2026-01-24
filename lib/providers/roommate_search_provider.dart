import 'package:flutter/material.dart';
import '../models/roommate_search.dart';
import '../config/supabase_provider.dart';

class RoommateSearchProvider extends ChangeNotifier {
  final List<RoommateSearch> _searches = [];
  bool _isLoading = false;
  String? _error;

  List<RoommateSearch> get searches => _searches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Crear nueva búsqueda de roommate
  Future<bool> createRoommateSearch({
    required String userId,
    required String title,
    required String description,
    required double budget,
    required String address,
    String? genderPreference,
    required List<String> habitsPreferences,
    required List<String> imageUrls,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final search = RoommateSearch(
        userId: userId,
        title: title,
        description: description,
        budget: budget,
        address: address,
        genderPreference: genderPreference,
        habitsPreferences: habitsPreferences,
        imageUrls: imageUrls,
      );

      // Aquí insertarías en Supabase
      // final response = await SupabaseProvider.client
      //     .from('roommate_searches')
      //     .insert(search.toJson());

      _searches.add(search);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener búsquedas de roommate
  Future<void> fetchRoommateSearches() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Aquí buscarías desde Supabase
      // final response = await SupabaseProvider.client
      //     .from('roommate_searches')
      //     .select()
      //     .eq('status', 'active');

      // _searches = (response as List)
      //     .map((data) => RoommateSearch.fromJson(data))
      //     .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener búsquedas por zona
  Future<List<RoommateSearch>> searchByZone(String zone) async {
    try {
      // Aquí buscarías desde Supabase
      // final response = await SupabaseProvider.client
      //     .from('roommate_searches')
      //     .select()
      //     .ilike('address', '%$zone%')
      //     .eq('status', 'active');

      // return (response as List)
      //     .map((data) => RoommateSearch.fromJson(data))
      //     .toList();

      return [];
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Actualizar búsqueda
  Future<bool> updateRoommateSearch({
    required String searchId,
    required String title,
    required String description,
    required double budget,
    required String address,
    String? genderPreference,
    required List<String> habitsPreferences,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Aquí actualizarías en Supabase
      // await SupabaseProvider.client
      //     .from('roommate_searches')
      //     .update({
      //       'title': title,
      //       'description': description,
      //       'budget': budget,
      //       'address': address,
      //       'gender_preference': genderPreference,
      //       'habits_preferences': habitsPreferences,
      //     })
      //     .eq('id', searchId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar búsqueda
  Future<bool> deleteRoommateSearch(String searchId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Aquí eliminarías en Supabase
      // await SupabaseProvider.client
      //     .from('roommate_searches')
      //     .delete()
      //     .eq('id', searchId);

      _searches.removeWhere((s) => s.id == searchId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cambiar estado a completado
  Future<bool> markAsCompleted(String searchId) async {
    try {
      // Aquí actualizarías en Supabase
      // await SupabaseProvider.client
      //     .from('roommate_searches')
      //     .update({'status': 'completed'})
      //     .eq('id', searchId);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
