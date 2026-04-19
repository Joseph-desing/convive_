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
    double? latitude,
    double? longitude,
    String? genderPreference,
    required List<String> habitsPreferences,
    required List<String> imageUrls,
    bool includeAlicuota = false,
  }) async {
    _isLoading = true;
    _error = null;
    // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
    Future.microtask(() => notifyListeners());

    try {
      print('📝 Creando roommate search con ${imageUrls.length} imágenes');
      
      final search = RoommateSearch(
        userId: userId,
        title: title,
        description: description,
        budget: budget,
        latitude: latitude,
        longitude: longitude,
        address: address,
        genderPreference: genderPreference,
        habitsPreferences: habitsPreferences,
        imageUrls: [], // Array vacío en la BD
        includeAlicuota: includeAlicuota,
      );

      // Usar el servicio de BD igual que PropertyProvider
      final createdSearch =
          await SupabaseProvider.databaseService.createRoommateSearch(search);
      
      print('✅ Búsqueda creada con ID: ${createdSearch.id}');
      
      // Guardar imágenes en tabla separada (como property_images)
      for (final imageUrl in imageUrls) {
        print('💾 Guardando imagen en roommate_search_images: $imageUrl');
        await SupabaseProvider.databaseService
            .addRoommateSearchImage(createdSearch.id ?? '', imageUrl);
      }
      
      // Actualizar objeto local con las imágenes cargadas
      createdSearch.imageUrls.addAll(imageUrls);
      _searches.add(createdSearch);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error creando búsqueda de roommate: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener búsquedas de roommate
  Future<void> fetchRoommateSearches({String? excludeUserId}) async {
    try {
      _isLoading = true;
      _error = null;
      // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
      Future.microtask(() => notifyListeners());

      // Buscar desde Supabase
      var query = SupabaseProvider.client
          .from('roommate_searches')
          .select()
          .eq('status', 'active');

      if (excludeUserId != null && excludeUserId.isNotEmpty) {
        query = query.neq('user_id', excludeUserId);
      }

      final response = await query;

      _searches.clear();
      _searches.addAll((response as List)
          .map((data) => RoommateSearch.fromJson(data))
          .toList());

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
    double? latitude,
    double? longitude,
    String? genderPreference,
    required List<String> habitsPreferences,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
      Future.microtask(() => notifyListeners());

      final updates = {
        'title': title,
        'description': description,
        'budget': budget,
        'address': address,
        'gender_preference': genderPreference,
        'habits_preferences': habitsPreferences,
      };
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      await SupabaseProvider.databaseService.updateRoommateSearch(searchId, updates);

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
      // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
      Future.microtask(() => notifyListeners());

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
