import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase;

  SupabaseAuthService({required SupabaseClient supabase}) : _supabase = supabase;

  /// Registrar nuevo usuario con email y contraseña
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo,
      data: data,
    );
  }

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Obtener usuario actual
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Stream de cambios de autenticación
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  /// Enviar email de recuperación de contraseña
  /// NOTA: El flujo principal usa AuthProvider.resetPassword() que tiene kIsWeb.
  /// Este método es helper alternativo, también usa kIsWeb correctamente.
  Future<void> resetPassword(String email) async {
    // Apuntar directamente a /reset-password para que Supabase agregue
    // ?token_hash=...&type=recovery como query params al path correcto.
    const redirectTo = 'https://convive-app-6debf.web.app/reset-password';
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  /// Actualizar contraseña del usuario actual (debe haber sesión válida)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Verificar si el usuario está autenticado
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Obtener token de acceso actual
  String? getAccessToken() {
    return _supabase.auth.currentSession?.accessToken;
  }

  /// Actualizar metadata del usuario (rol, etc)
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }

  /// Verificar si el email del usuario actual está confirmado
  bool isEmailVerified() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    
    // Verificar si el email está confirmado
    return user.emailConfirmedAt != null;
  }

  /// Obtener estado de verificación del usuario actual
  Map<String, dynamic> getUserVerificationStatus() {
    final user = _supabase.auth.currentUser;
    return {
      'isAuthenticated': user != null,
      'emailVerified': user?.emailConfirmedAt != null,
      'email': user?.email,
      'userId': user?.id,
    };
  }
}
