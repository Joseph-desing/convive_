import 'package:flutter/foundation.dart';
import '../models/user.dart' as convive_user;
import '../config/supabase_provider.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import 'package:supabase_flutter/supabase_flutter.dart';

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

//Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseProvider.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.convive_://login-callback',
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
  Future<void> initializeAuth() async {
    try {
      final session = SupabaseProvider.client.auth.currentSession;
      
      if (session != null && session.user != null) {
        // Hay sesión activa, cargar usuario de la BD
        try {
          _currentUser = await SupabaseProvider.databaseService
              .getUser(session.user.id);
          _isEmailVerified = session.user.emailConfirmedAt != null;
        } catch (e) {
          // Si no está en BD, crear en memoria
          _currentUser = convive_user.User(
            id: session.user.id,
            email: session.user.email ?? '',
            role: convive_user.UserRole.student,
          );
        }
      } else {
        // No hay sesión, usuario es nulo
        _currentUser = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inicializando auth: $e');
      }
      _currentUser = null;
    }
    
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
          final dbUser = await SupabaseProvider.databaseService
              .getUser(authResponse.user!.id);
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
      // Capturar el error de forma legible
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('already exists')) {
        _error = 'Este email ya está registrado';
      } else if (errorStr.contains('password')) {
        _error = 'La contraseña debe tener al menos 6 caracteres';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        _error = 'Error de conexión. Verifica tu internet';
      } else {
        _error = e.toString();
      }
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
          final dbUser = await SupabaseProvider.databaseService
              .getUser(authResponse.user!.id);
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
      // Capturar el error de forma legible
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid login') ||
          errorStr.contains('invalid_credentials') ||
          errorStr.contains('invalid credentials')) {
        _error = 'Contraseña incorrecta o email no registrado';
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        _error = 'Error de conexión. Verifica tu internet';
      } else if (errorStr.contains('already exists')) {
        _error = 'Este email ya está registrado';
      } else {
        _error = e.toString();
      }
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
      print('🔄 Enviando email de recuperación a: $email');
      
      await SupabaseProvider.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.example.convive://reset-password',
      );

      print('✅ Email de recuperación enviado');
    } catch (e) {
      print('❌ Error enviando email: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambiar contraseña (usuario autenticado)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Re-autenticar con contraseña actual para verificar identidad
      if (_currentUser?.email == null) {
        throw Exception('Email no disponible');
      }

      await SupabaseProvider.authService.signIn(
        email: _currentUser!.email,
        password: currentPassword,
      );

      // Si la re-autenticación funciona, cambiar la contraseña
      await SupabaseProvider.authService.updatePassword(newPassword);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambiar contraseña con token de reset (desde email)
  Future<void> resetPasswordWithToken({
    required String email,
    required String newPassword,
    required String resetToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (resetToken.isEmpty) {
        throw Exception('El token de recuperación está vacío');
      }

      print('🔄 Intentando cambiar contraseña con token...');

      // El token que viene del deep link es un access_token
      // Lo usamos para establecer una sesión temporal y cambiar la contraseña
      try {
        // Intentar cambiar la contraseña directamente
        // Supabase debería validar el token internamente
        await SupabaseProvider.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        
        print('✅ Contraseña actualizada exitosamente');
      } catch (updateError) {
        print('⚠️ Error directo: $updateError');
        
        // Si falla, intentar verificar como OTP tradicional
        try {
          print('🔄 Intentando verificar como OTP...');
          final response = await SupabaseProvider.client.auth.verifyOTP(
            email: email,
            token: resetToken,
            type: OtpType.recovery,
          );

          if (response.session != null) {
            print('✅ OTP verificado');
            
            // Cambiar la contraseña con la sesión verificada
            await SupabaseProvider.client.auth.updateUser(
              UserAttributes(password: newPassword),
            );
            
            print('✅ Contraseña actualizada');
          } else {
            throw Exception('No se pudo verificar el OTP');
          }
        } catch (otpError) {
          print('❌ Error con OTP: $otpError');
          throw otpError;
        }
      }

      // Limpiar la sesión después de cambiar contraseña
      await SupabaseProvider.client.auth.signOut();
      _currentUser = null;

      _error = null;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('otp_expired') || 
          errorStr.contains('expired')) {
        _error = 'El token de recuperación ha expirado. Por favor solicita uno nuevo.';
      } else if (errorStr.contains('invalid')) {
        _error = 'El token de recuperación es inválido.';
      } else if (errorStr.contains('password')) {
        _error = 'La contraseña no cumple los requisitos mínimos (mín. 6 caracteres)';
      } else {
        _error = e.toString();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verificar un código OTP de recuperación
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Verificando código OTP...');

      // Verificar el código con Supabase
      final response = await SupabaseProvider.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );

      if (response.session == null) {
        throw Exception('No se pudo verificar el código. Por favor intenta de nuevo.');
      }

      print('✅ Código OTP verificado correctamente');
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      print('❌ Error verificando OTP: $e');
      
      if (errorStr.contains('otp_expired') || errorStr.contains('expired')) {
        _error = 'El código ha expirado. Por favor solicita uno nuevo.';
      } else if (errorStr.contains('invalid') || errorStr.contains('incorrect')) {
        _error = 'El código es incorrecto. Por favor verifica y intenta de nuevo.';
      } else {
        _error = e.toString();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambiar contraseña usando un código OTP verificado
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Cambiando contraseña...');

      // Primero verificar que el código sea válido (si no lo está, esto lanzará un error)
      final response = await SupabaseProvider.client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );

      if (response.session == null) {
        throw Exception('No se pudo verificar el código de recuperación');
      }

      // Cambiar la contraseña con la sesión verificada
      await SupabaseProvider.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('✅ Contraseña cambiada exitosamente');

      // Cerrar sesión para que el usuario inicie con la nueva contraseña
      await SupabaseProvider.client.auth.signOut();
      _currentUser = null;

      _error = null;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      print('❌ Error cambiando contraseña: $e');

      if (errorStr.contains('otp_expired') || errorStr.contains('expired')) {
        _error = 'El código ha expirado. Por favor solicita uno nuevo.';
      } else if (errorStr.contains('invalid')) {
        _error = 'El código es inválido. Por favor verifica y intenta de nuevo.';
      } else if (errorStr.contains('password')) {
        _error = 'La contraseña debe tener al menos 6 caracteres.';
      } else {
        _error = e.toString();
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
