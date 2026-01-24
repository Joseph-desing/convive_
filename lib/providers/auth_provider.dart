import 'package:flutter/foundation.dart';
import '../models/user.dart' as convive_user;
import '../config/supabase_provider.dart';

/// Provider para autenticación
class AuthProvider extends ChangeNotifier {
  convive_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isEmailVerified = false;

  convive_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => _isEmailVerified;

  /// Forzar refresco del estado de verificación desde Supabase
  Future<void> refreshEmailVerification() async {
    try {
      // Si no hay sesión, no se puede refrescar; evita lanzar excepción 400
      final session = SupabaseProvider.client.auth.currentSession;
      if (session == null) {
        return;
      }

      final response = await SupabaseProvider.client.auth.getUser();
      _isEmailVerified = response.user?.emailConfirmedAt != null;
    } catch (e) {
      // Si falla, mantenemos el estado previo
      if (kDebugMode) {
        print('Error refrescando verificación: $e');
      }
    }
    notifyListeners();
  }

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

      // Esperar a que el trigger cree el usuario en BD
      await Future.delayed(const Duration(milliseconds: 1000));

      // Cargar usuario de la BD (ya creado por el trigger)
      if (authResponse.user != null) {
        try {
          final dbUser = await SupabaseProvider.databaseService.getUser(authResponse.user!.id);
          _currentUser = dbUser;
        } catch (e) {
          // Si el trigger no lo creó, intentar crearlo manualmente
          try {
            final user = convive_user.User(
              id: authResponse.user!.id,
              email: email,
              role: role,
            );
            await SupabaseProvider.databaseService.createUser(user);
            _currentUser = user;
          } catch (createError) {
            // Si falla, usar datos en memoria
            _currentUser = convive_user.User(
              id: authResponse.user!.id,
              email: email,
              role: role,
            );
          }
        }
      }
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
      
      // Verificar si el email está confirmado
      _isEmailVerified = SupabaseProvider.authService.isEmailVerified();
      
      // Cargar usuario de la BD
      if (authResponse.user != null) {
        try {
          final dbUser = await SupabaseProvider.databaseService.getUser(authResponse.user!.id);
          _currentUser = dbUser;
        } catch (e) {
          // Si no existe en BD, intentar crearlo (por si el trigger falló)
          try {
            final user = convive_user.User(
              id: authResponse.user!.id,
              email: authResponse.user!.email ?? '',
              role: convive_user.UserRole.student,
            );
            await SupabaseProvider.databaseService.createUser(user);
            _currentUser = user;
          } catch (createError) {
            // Si falla la creación, usar datos en memoria
            _currentUser = convive_user.User(
              id: authResponse.user!.id,
              email: authResponse.user!.email ?? '',
              role: convive_user.UserRole.student,
            );
          }
        }
      } else {
        _error = 'No se pudo obtener el usuario';
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
