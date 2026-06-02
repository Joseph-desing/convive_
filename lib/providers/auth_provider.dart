import 'package:flutter/foundation.dart';
import '../models/user.dart' as convive_user;
import '../config/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider para autenticación
class AuthProvider extends ChangeNotifier {
  convive_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isEmailVerified = false;
  bool _isNewUser = false;

  convive_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isEmailVerified => _isEmailVerified;
  bool get isNewUser => _isNewUser;
  bool get isSuspendedAccount => _error == _suspendedAccountMessage;

  static const String _suspendedAccountMessage =
      'Tu cuenta ha sido suspendida. Contacta con administración.';

  Future<bool> _blockIfSuspended(convive_user.User user) async {
    if (!user.isSuspended) return false;

    await SupabaseProvider.authService.signOut();
    _currentUser = null;
    _isEmailVerified = false;
    _error = _suspendedAccountMessage;
    return true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

//Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    _isNewUser = false;
    notifyListeners();

    try {
      debugPrint('🔵 [Google] Iniciando OAuth...');
      await SupabaseProvider.client.auth.signInWithOAuth(
        OAuthProvider.google,
        // Web → redirige directamente a la app en Firebase Hosting
        // Android → usa deep link custom scheme para volver a la app
        // IMPORTANTE: usar externalApplication (Chrome normal) en Android.
        // Chrome Custom Tab (inAppWebView) está sandboxeado y NO puede disparar
        // intent-filters con custom scheme (com.convive.app://...).
        // Chrome externo sí puede redirigir a custom schemes.
        // SCHEME = applicationId (com.convive.app), NO el namespace (com.example.convive_)
        redirectTo: kIsWeb
            ? 'https://convive-app-6debf.web.app/home'
            : 'com.convive.app://login-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication, // ← Chrome externo en Android
      );
      debugPrint('🔵 [Google] signInWithOAuth lanzado');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [Google] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Llamar después de que Google redirige de vuelta a la app.
  /// Crea el usuario en public.users si no existe y detecta si es nuevo.
  Future<void> handleGoogleCallback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = SupabaseProvider.client.auth.currentSession;
      if (session == null) {
        print('⚠️ handleGoogleCallback: no hay sesión activa');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final authUser = session.user;
      _isEmailVerified = authUser.emailConfirmedAt != null;
      _isNewUser = false;

      // Intentar cargar usuario de public.users
      try {
        final dbUser = await SupabaseProvider.databaseService.getUser(authUser.id);
        if (await _blockIfSuspended(dbUser)) {
          _isLoading = false;
          notifyListeners();
          return;
        }
        _currentUser = dbUser;
        print('✅ Google: usuario encontrado en public.users: ${dbUser.fullName}');
      } catch (e) {
        // No existe → crear con datos de Google
        print('⚠️ Google: usuario no existe en public.users, creando...');
        _isNewUser = true;
        final metadata = authUser.userMetadata ?? {};
        final fullName = (metadata['full_name'] as String?) ??
            (metadata['name'] as String?) ??
            authUser.email?.split('@').first ?? '';
        final user = convive_user.User(
          id: authUser.id,
          email: authUser.email ?? '',
          fullName: fullName,
          role: convive_user.UserRole.student,
        );
        try {
          await SupabaseProvider.databaseService.createUser(user);
          _currentUser = user;
          print('✅ Google: usuario creado en public.users: $fullName');
        } catch (createErr) {
          print('❌ Google: error creando usuario: $createErr');
          _currentUser = user;
        }
      }

      // Verificar si tiene perfil en public.profiles
      if (!_isNewUser) {
        try {
          final profile = await SupabaseProvider.databaseService.getProfile(authUser.id);
          if (profile == null) {
            _isNewUser = true;
            print('⚠️ Google: sin perfil en public.profiles → es nuevo');
          } else {
            print('✅ Google: perfil encontrado en public.profiles');
          }
        } catch (e) {
          _isNewUser = true;
          print('⚠️ Google: error buscando perfil: $e');
        }
      }
    } catch (e) {
      _error = e.toString();
      print('❌ handleGoogleCallback error: $e');
    }

    _isLoading = false;
    notifyListeners();
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
      
      if (session != null) {
        // Hay sesión activa, cargar usuario de la BD
        try {
          _currentUser = await SupabaseProvider.databaseService
              .getUser(session.user.id);
          if (await _blockIfSuspended(_currentUser!)) {
            notifyListeners();
            return;
          }
          _isEmailVerified = session.user.emailConfirmedAt != null;
        } catch (e) {
          // Si no está en BD, crear en memoria
          if (session.user.emailConfirmedAt == null) {
            _currentUser = null;
            _isEmailVerified = false;
            notifyListeners();
            return;
          }

          final metadata = session.user.userMetadata ?? {};
          final roleName = metadata['role'] as String?;
          final role = convive_user.UserRole.values.firstWhere(
            (value) => value.name == roleName,
            orElse: () => convive_user.UserRole.student,
          );
          final user = convive_user.User(
            id: session.user.id,
            email: session.user.email ?? '',
            fullName: metadata['full_name'] as String?,
            role: role,
          );

          _currentUser = await SupabaseProvider.databaseService.createUser(user);
          if (await _blockIfSuspended(_currentUser!)) {
            notifyListeners();
            return;
          }
          _isEmailVerified = true;
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
        // Web → abre la página de confirmación en Firebase Hosting
        // Android → deep link 'auth-callback' (distinto de login-callback para no confundir con Google OAuth)
        emailRedirectTo: kIsWeb
            ? 'https://convive-app-6debf.web.app/#/email-confirmed'
            : 'com.example.convive_://auth-callback',
        data: {
          'full_name': fullName,
          'role': role.name,
        },
      );

      if (authResponse.user != null) {
        _currentUser = null;
        _isEmailVerified = authResponse.user!.emailConfirmedAt != null;
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

      if (!_isEmailVerified) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cargar usuario de la BD
      _isNewUser = false;
      if (authResponse.user != null) {
        try {
          final dbUser = await SupabaseProvider.databaseService
              .getUser(authResponse.user!.id);
          if (await _blockIfSuspended(dbUser)) {
            _isLoading = false;
            notifyListeners();
            return;
          }
          _currentUser = dbUser;
          print('✅ Usuario encontrado en public.users: ${dbUser.fullName}');
        } catch (e) {
          // Si no existe en BD, intentar crearlo
          print('⚠️ Usuario no encontrado en public.users, creando...');
          _isNewUser = true;
          try {
            final metadata = authResponse.user!.userMetadata ?? {};
            final fullName = metadata['full_name'] as String? ?? '';
            final roleStr = metadata['role'] as String? ?? 'student';
            final role = roleStr == 'non_student'
                ? convive_user.UserRole.non_student
                : convive_user.UserRole.student;
            print('📝 Metadata: full_name=$fullName, role=$roleStr');
            final user = convive_user.User(
              id: authResponse.user!.id,
              email: authResponse.user!.email ?? '',
              fullName: fullName,
              role: role,
            );
            await SupabaseProvider.databaseService.createUser(user);
            _currentUser = user;
            print('✅ Usuario creado en public.users: $fullName');
          } catch (createError) {
            print('❌ Error creando usuario: $createError');
            // Si falla la creación, usar datos en memoria
            _currentUser = convive_user.User(
              id: authResponse.user!.id,
              email: authResponse.user!.email ?? '',
              fullName: authResponse.user!.userMetadata?['full_name'] as String?,
              role: convive_user.UserRole.student,
            );
          }
        }

        // Verificar si tiene perfil completo en public.profiles
        if (!_isNewUser) {
          try {
            final profile = await SupabaseProvider.databaseService
                .getProfile(authResponse.user!.id);
            if (profile == null) {
              _isNewUser = true;
              print('⚠️ Usuario sin perfil en public.profiles → es nuevo');
            } else {
              print('✅ Perfil encontrado en public.profiles');
            }
          } catch (e) {
            _isNewUser = true;
            print('⚠️ Error buscando perfil: $e → tratando como nuevo');
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
      debugPrint('🔄 [Reset] Enviando email de recuperación a: $email');

      // Siempre usar la URL web para el redirectTo de reset password.
      // Razón: el email de Supabase incluye un link https://supabase.co/auth/v1/verify
      // que redirige al redirectTo. Gmail y otros clientes de correo en Android abren
      // ese link en su navegador integrado, que NO puede abrir deep links custom scheme.
      // La URL web ya funciona correctamente en navegador (web y Android).
      // Para que el APK abra directamente la app se necesitaría App Links (assetlinks.json).
      const redirectTo = 'https://convive-app-6debf.web.app/#/reset-password';

      debugPrint('🔄 [Reset] redirectTo: $redirectTo');

      await SupabaseProvider.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );

      debugPrint('✅ [Reset] Email de recuperación enviado');
    } catch (e) {
      debugPrint('❌ [Reset] Error enviando email: $e');
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
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid login') ||
          errorStr.contains('invalid_credentials') ||
          errorStr.contains('invalid credentials')) {
        _error = 'La contraseña actual es incorrecta';
      } else if (errorStr.contains('password') &&
          (errorStr.contains('weak') || errorStr.contains('short'))) {
        _error = 'La nueva contraseña debe tener al menos 6 caracteres';
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        _error = 'Error de conexion. Verifica tu internet';
      } else {
        _error = 'No se pudo actualizar la contraseña. Intenta nuevamente';
      }
      throw Exception(_error);
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
