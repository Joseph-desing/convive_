import 'package:flutter/foundation.dart';
import '../models/user.dart' as convive_user;
import '../config/supabase_provider.dart';

/// Provider para autenticación
class AuthProvider extends ChangeNotifier {
  convive_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  convive_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Inicializar con usuario actual
  void initializeAuth() {
    notifyListeners();
  }

  /// Registrarse
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required convive_user.UserRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await SupabaseProvider.authService.signUp(
        email: email,
        password: password,
      );

      // Crear usuario en BD
      final user = convive_user.User(
        id: authResponse.user!.id,
        email: email,
        role: role,
      );
      await SupabaseProvider.databaseService.createUser(user);

      _currentUser = user;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Iniciar sesión
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await SupabaseProvider.authService.signIn(
        email: email,
        password: password,
      );
      
      // Map Supabase GoTrue User to our User model
      if (authResponse.user != null) {
        _currentUser = convive_user.User(
          id: authResponse.user!.id,
          email: authResponse.user!.email ?? '',
          role: convive_user.UserRole.student,
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseProvider.authService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Reestablecer contraseña
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseProvider.authService.resetPassword(email);
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
