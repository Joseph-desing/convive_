import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';

/// Provider para propiedades y departamentos
class PropertyProvider extends ChangeNotifier {
  List<Property> _properties = [];
  List<Property> _userProperties = [];
  Property? _selectedProperty;
  bool _isLoading = false;
  String? _error;

  List<Property> get properties => _properties;
  List<Property> get userProperties => _userProperties;
  Property? get selectedProperty => _selectedProperty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar propiedades disponibles
  Future<void> loadProperties({int limit = 20, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _properties =
          await SupabaseProvider.databaseService.getProperties(limit: limit, offset: offset);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cargar propiedades del usuario
  Future<void> loadUserProperties(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userProperties =
          await SupabaseProvider.databaseService.getUserProperties(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Obtener propiedad por ID
  Future<void> getProperty(String propertyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProperty =
          await SupabaseProvider.databaseService.getProperty(propertyId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Crear propiedad
  Future<void> createProperty(Property property) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProperty =
          await SupabaseProvider.databaseService.createProperty(property);
      _userProperties.add(newProperty);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualizar propiedad
  Future<void> updateProperty(String propertyId,
      Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseProvider.databaseService.updateProperty(propertyId, updates);
      // Actualizar en lista local
      final index =
          _userProperties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _userProperties[index] = _userProperties[index].copyWith(
          title: updates['title'] ?? _userProperties[index].title,
          price: updates['price'] ?? _userProperties[index].price,
          isActive: updates['is_active'] ?? _userProperties[index].isActive,
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
