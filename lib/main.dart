import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_properties_screen.dart';
import 'screens/admin_feedback_screen.dart';
import 'screens/suspended_account_screen.dart';
import 'config/supabase_provider.dart';
import 'config/ai_service_provider.dart';
import 'providers/index.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/chatbot_provider.dart';
import 'providers/admin_provider.dart';
import 'services/chatbot_service.dart';
import 'services/supabase_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializar servicios
  try {
    await SupabaseProvider.initialize();
    AIServiceProvider.initialize();
    print('✅ Servicios inicializados correctamente');
  } catch (e) {
    print('❌ Error inicializando servicios: $e');
  }

  runApp(const ConViveApp());
}

class ConViveApp extends StatefulWidget {
  const ConViveApp({Key? key}) : super(key: key);

  @override
  State<ConViveApp> createState() => _ConViveAppState();
}

class _ConViveAppState extends State<ConViveApp> {
  late final GoRouter _router;
  late final AppLinks _appLinks;
  late final StreamSubscription<Uri> _deepLinkSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool? _didInitializeAuth = false;
  bool _waitingForGoogleSession = false;

  @override
  void initState() {
    super.initState();
    _router = _setupRouter();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    _appLinks = AppLinks();

    // ── CASO COLD-START: app estaba cerrada y se abrió por deep link ──
    // uriLinkStream NO emite el link inicial; hay que leerlo manualmente.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('🔗 [DeepLink] Cold-start link: $uri');
        _handleDeepLink(uri);
      }
    }).catchError((e) {
      debugPrint('❌ [DeepLink] Error leyendo initialLink: $e');
    });

    // ── CASO HOT/WARM: app ya estaba abierta o en background ──
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 [DeepLink] Hot link recibido: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('❌ [DeepLink] Error en stream: $err');
      },
    );

    // ── LISTENER de AuthState para detectar sesión Google OAuth en Android ──
    // Cuando Chrome redirige al deep link, supabase_flutter intercepta
    // el code PKCE y lo intercambia automáticamente. onAuthStateChange
    // notifica cuando la sesión está lista.
    if (!kIsWeb) {
      _authStateSubscription = SupabaseProvider.client.auth.onAuthStateChange.listen(
        (data) {
          final event = data.event;
          final session = data.session;
          debugPrint('🔔 [AuthState] event=$event session=${session != null ? "[active]" : "[null]"}');

          if (event == AuthChangeEvent.signedIn && session != null && _waitingForGoogleSession) {
            _waitingForGoogleSession = false;
            debugPrint('🔔 [AuthState] Sesión Google detectada via onAuthStateChange → navegando a /home');
            Future.microtask(() async {
              final ctx = _router.routerDelegate.navigatorKey.currentContext;
              if (ctx != null) {
                final authProvider = ctx.read<AuthProvider>();
                await authProvider.handleGoogleCallback();
                final role = authProvider.currentUser?.role.toString().split('.').last ?? 'student';
                _router.go(role == 'admin' ? '/admin' : '/home');
              } else {
                _router.go('/home');
              }
            });
          }
        },
        onError: (err) {
          debugPrint('❌ [AuthState] Error en stream: $err');
        },
      );
    }
  }

  /// Manejo centralizado de deep links. Soporta:
  ///   com.example.convive_://reset-password?code=...
  ///   com.example.convive_://auth-callback?code=...&type=recovery
  ///   com.example.convive_://login-callback          (Google OAuth)
  ///   com.example.convive_://email-confirmed?code=...
  ///   https://convive-app-6debf.web.app/?code=...#/reset-password  (Web fallback)
  void _handleDeepLink(Uri uri) {
    debugPrint(
        '🔍 [DeepLink] scheme=${uri.scheme} host=${uri.host} path=${uri.path}');
    debugPrint(
        '🔍 [DeepLink] query=${uri.queryParameters} fragment=${uri.fragment}');

    final host = uri.host;
    final path = uri.path;
    final fragment = uri.fragment;

    // ── Extraer parámetros de query y/o fragment ──────────────────────────
    // Supabase puede enviar el code antes del #  (?code=X#/ruta)
    // o dentro del fragment (#access_token=X&type=recovery)
    Map<String, String> fParams = {};
    if (fragment.isNotEmpty) {
      // El fragment puede ser "/reset-password" o "access_token=...&type=recovery"
      final clean = fragment.startsWith('/') ? '' : fragment;
      if (clean.contains('=')) {
        fParams = Uri.splitQueryString(clean);
      }
    }

    String code = uri.queryParameters['code'] ?? fParams['code'] ?? '';
    String tokenHash =
        uri.queryParameters['token_hash'] ?? fParams['token_hash'] ?? '';
    String token =
        uri.queryParameters['access_token'] ?? fParams['access_token'] ?? '';
    String type = uri.queryParameters['type'] ?? fParams['type'] ?? '';
    String email = uri.queryParameters['email'] ?? fParams['email'] ?? '';
    String errorCode =
        uri.queryParameters['error_code'] ?? fParams['error_code'] ?? '';

    // Inferir tipo por el host/path si no viene explícito
    final isResetPath = host == 'reset-password' ||
        path.contains('reset-password') ||
        fragment.contains('reset-password') ||
        type == 'recovery';

    final isAuthCallback =
        host == 'auth-callback' || path.contains('auth-callback');

    final isLoginCallback =
        host == 'login-callback' || path.contains('login-callback');

    // 📧 Email confirmation: type=signup, type=email_change, o host=email-confirmed
    // IMPORTANTE: Esta detección es DISTINTA de Google OAuth (login-callback)
    // para evitar que los usuarios de email confirmation terminen en /complete-profile
    // desde el navegador.
    final isEmailConfirmed = host == 'email-confirmed' ||
        path.contains('email-confirmed') ||
        fragment.contains('email-confirmed') ||
        type == 'signup' ||
        type == 'email_change';

    debugPrint(
        '🔍 [DeepLink] code=$code token=$token type=$type error=$errorCode');
    debugPrint(
        '🔍 [DeepLink] isReset=$isResetPath isAuth=$isAuthCallback isLogin=$isLoginCallback isEmail=$isEmailConfirmed');

    // ── CASO 0: Volver al login desde reset-password web ──────────────────────
    // La web reset-password redirige a com.example.convive_://login tras cambio exitoso.
    if (host == 'login' && uri.scheme == 'com.example.convive_') {
      debugPrint('🏠 [DeepLink] → Reset-password web completado, ir a /login');
      Future.microtask(() async {
        // Cerrar sesión de recuperación si existe (sesión temporal de Supabase)
        try {
          await SupabaseProvider.client.auth.signOut();
        } catch (_) {}
        _router.go('/login');
      });
      return;
    }

    // ── CASO: Error en el link ─────────────────────────────────────────────
    if (errorCode.isNotEmpty) {
      debugPrint('⚠️ [DeepLink] Error en link: $errorCode');
      _router
          .go('/reset-password?error_code=${Uri.encodeComponent(errorCode)}');
      return;
    }

    // ── CASO 1: Reset password ─────────────────────────────────────────────
    if (isResetPath ||
        (isAuthCallback &&
            (type == 'recovery' || code.isNotEmpty && type.isEmpty))) {
      if (tokenHash.isNotEmpty) {
        debugPrint('🔑 [DeepLink] → /reset-password con token_hash');
        _router.push(
          '/reset-password?token_hash=${Uri.encodeComponent(tokenHash)}&email=${Uri.encodeComponent(email)}',
        );
      } else if (code.isNotEmpty) {
        debugPrint('🔑 [DeepLink] → /reset-password con code PKCE');
        // Guardamos el code para que ResetPasswordScreen lo use
        _router.push(
          '/reset-password?code=${Uri.encodeComponent(code)}&email=${Uri.encodeComponent(email)}',
        );
      } else if (token.isNotEmpty) {
        debugPrint('🔑 [DeepLink] → /reset-password con access_token');
        _router.push(
          '/reset-password?token=${Uri.encodeComponent(token)}&email=${Uri.encodeComponent(email)}',
        );
      } else {
        debugPrint('⚠️ [DeepLink] Reset sin code ni token, navegando igual');
        _router.push('/reset-password');
      }
      return;
    }

    // ── CASO 2: Google OAuth callback ─────────────────────────────────────
    // En Android, supabase_flutter procesa el deep link automáticamente y
    // dispara onAuthStateChange cuando la sesión está lista.
    // Pero puede haber un delay → intentar esperar la sesión antes de navegar.
    if (isLoginCallback) {
      debugPrint('🔵 [DeepLink] → Google OAuth callback');
      debugPrint('🔵 [DeepLink] Platform: ${kIsWeb ? "Web" : "Android"}');

      Future.microtask(() async {
        // Esperar hasta 5 segundos a que supabase_flutter procese el código
        // y establezca la sesión automáticamente
        var session = SupabaseProvider.client.auth.currentSession;
        if (session == null) {
          debugPrint('🔵 [DeepLink] Sesión no disponible aún, esperando...');
          _waitingForGoogleSession = true;

          // Intentar hasta 10 veces con 500ms entre cada intento
          for (var i = 0; i < 10; i++) {
            await Future.delayed(const Duration(milliseconds: 500));
            session = SupabaseProvider.client.auth.currentSession;
            if (session != null) {
              debugPrint('🔵 [DeepLink] Sesión detectada después de ${(i + 1) * 500}ms');
              _waitingForGoogleSession = false;
              break;
            }
          }
        }

        if (session != null) {
          debugPrint('🔵 [DeepLink] Sesión activa, procesando callback...');
          final authProvider = _router.routerDelegate.navigatorKey.currentContext
              ?.read<AuthProvider>();
          if (authProvider != null) {
            await authProvider.handleGoogleCallback();
            final role =
                authProvider.currentUser?.role.toString().split('.').last ??
                    'student';
            _router.go(role == 'admin' ? '/admin' : '/home');
          } else {
            _router.go('/home');
          }
        } else {
          // Si después de 5s no hay sesión, dejar que onAuthStateChange lo maneje
          debugPrint('⚠️ [DeepLink] Sin sesión después de 5s, esperando onAuthStateChange...');
          // _waitingForGoogleSession ya está true → onAuthStateChange navegará
        }
      });
      return;
    }

    // ── CASO 3: Confirmación de email (auth-callback con type=signup O directo a email-confirmed) ──
    // IMPORTANTE: Si es email-confirmed, SIEMPRE navegar a /email-confirmed SIN parámetros adicionales.
    // Esto garantiza que nunca se abre /complete-profile desde el navegador web.
    if (isEmailConfirmed) {
      debugPrint('📧 [DeepLink] → Email confirmation');
      // Guardamos el code/token globalmente para que EmailConfirmedRedirectScreen lo consuma
      // sin depender de Uri.base (que en Android es localhost)
      if (code.isNotEmpty) {
        EmailConfirmedRedirectScreen.pendingCode = code;
        _router.go('/email-confirmed');
      } else if (token.isNotEmpty) {
        // Legacy: access_token directo (flujo implicit)
        EmailConfirmedRedirectScreen.pendingCode = token;
        _router.go('/email-confirmed');
      } else {
        // Sin code: puede que Supabase ya confirmó server-side
        _router.go('/email-confirmed');
      }
      return;
    }

    // ── CASO 4: Auth callback que NO es email confirmation ────────────────
    // (puede ser recovery/reset-password con type=recovery, pero eso debería haber sido capturado antes)
    if (isAuthCallback) {
      debugPrint('🔐 [DeepLink] → Auth callback (no es email confirmation)');
      // Si llegamos aquí y no fue recovery, probablemente sea un email confirmation
      // que no fue detectado correctamente. Redirigir a /email-confirmed por seguridad.
      if (type == 'signup' || type == 'email_change') {
        EmailConfirmedRedirectScreen.pendingCode =
            code.isNotEmpty ? code : token;
        _router.go('/email-confirmed');
      } else {
        // Si no sabemos qué es, asumir que no es email confirmation
        // y dejar que se maneje en el router redirect
        _router.go('/email-confirmed');
      }
      return;
    }

    debugPrint('⚠️ [DeepLink] Link no reconocido: $uri');
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  GoRouter _setupRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final session = SupabaseProvider.client.auth.currentSession;
        final location = state.matchedLocation;

        if (location.startsWith('/error=')) {
          return '/reset-password?error_code=otp_expired';
        }

        // 🚨 PRIORIDAD 1: Si es /email-confirmed, PERMITIR INCONDICIONALMENTE
        // SIN verificar perfil, sin redirigir, nada.
        // Esta es una ruta de confirmación que NO debe ser interceptada.
        if (location == '/email-confirmed' ||
            location.startsWith('/email-confirmed?') ||
            location.startsWith('/email-confirmed#')) {
          return null;
        }

        // 🚨 EMERGENCIA: Si viene a /complete-profile pero tiene un 'code' (parámetro de email)
        // y NO tiene userId válido, redirigir a /email-confirmed.
        // Esto maneja el caso donde Supabase Auth está cacheado con un redirectTo incorrecto.
        if (location.startsWith('/complete-profile')) {
          final code = state.uri.queryParameters['code'] ?? '';
          final userId = state.uri.queryParameters['userId'] ?? '';

          // Si hay code pero no hay userId = es un intento de email confirmation
          if (code.isNotEmpty && userId.isEmpty) {
            debugPrint(
                '🚨 EMERGENCIA: /complete-profile con code de email → redirigiendo a /email-confirmed');
            return '/email-confirmed?code=${Uri.encodeComponent(code)}';
          }

          // Si hay userId = es un flujo legítimo de complete-profile
          // Proteger: requiere sesión
          if (session == null) {
            return '/login';
          }
          return null;
        }

        // Si es una ruta de recuperación de contraseña, forgot password, permitir (sin redirigir)
        if (location == '/auth-callback' ||
            location == '/suspended' ||
            location == '/reset-password' ||
            location.startsWith('/reset-password?') ||
            location.startsWith('/reset-password#') ||
            location == '/forgot-password' ||
            location.startsWith('/forgot-password?') ||
            location == '/email-verification' ||
            location.startsWith('/email-verification?')) {
          return null;
        }

        // Proteger rutas de admin (solo para usuarios con rol admin)
        if (location.startsWith('/admin')) {
          if (session == null) {
            return '/login';
          }
          return null;
        }

        // Si viene de Supabase con parámetros de recovery (en fragment o query), redirigir a /auth-callback
        if (location == '/') {
          final uriBaseParams = Uri.base.queryParameters;
          final fragmentParams = state.uri.fragment.isNotEmpty
              ? Uri.parse('http://example.com?${state.uri.fragment}')
                  .queryParameters
              : <String, String>{};
          final errorCode = state.uri.queryParameters['error_code'] ??
              uriBaseParams['error_code'] ??
              fragmentParams['error_code'] ??
              '';

          if (errorCode.isNotEmpty) {
            return '/reset-password?error_code=$errorCode';
          }

          // ── Extraer token_hash y code de cualquier fuente ──
          String tokenHash = state.uri.queryParameters['token_hash'] ??
              uriBaseParams['token_hash'] ??
              fragmentParams['token_hash'] ??
              '';
          String code = state.uri.queryParameters['code'] ??
              uriBaseParams['code'] ??
              fragmentParams['code'] ??
              '';

          // ── Detectar si es recovery ──
          bool isRecovery = state.uri.fragment.contains('type=recovery') ||
              state.uri.queryParameters['type'] == 'recovery' ||
              uriBaseParams['type'] == 'recovery';

          // token_hash SIEMPRE es recovery
          if (tokenHash.isNotEmpty && !isRecovery) {
            isRecovery = true;
            print('🔐 token_hash detectado → recovery');
          }

          // code sin type explícito → NO asumir recovery.
          // Antes asumíamos recovery, pero eso hace que email verification
          // y Google OAuth muestren la pantalla de Reset Password.
          // Recovery SIEMPRE viene con token_hash (template nuevo) o type=recovery.
          // Code sin type = email confirmation o Google OAuth.
          if (code.isNotEmpty && !isRecovery) {
            final typeParam = state.uri.queryParameters['type'] ??
                uriBaseParams['type'] ??
                fragmentParams['type'] ??
                '';
            if (typeParam == 'recovery') {
              isRecovery = true;
              print('🔐 type=recovery explícito → recovery');
            } else if (typeParam == 'signup' || typeParam == 'email_change') {
              // Es email confirmation, NO recovery
              print('📧 type=$typeParam → email confirmation');
            } else {
              // Sin type: tratar como email confirmation (NO recovery)
              // Recovery usa token_hash ahora, no code sin type
              print('📧 Code sin type → tratando como email confirmation (NO recovery)');
            }
          }

          if (isRecovery && (tokenHash.isNotEmpty || code.isNotEmpty)) {
            print('🔐 Recovery detectado en /, redirigiendo a /reset-password');

            String email = state.uri.queryParameters['email'] ??
                uriBaseParams['email'] ??
                fragmentParams['email'] ??
                '';
            if (email.isEmpty) {
              email = SupabaseProvider.client.auth.currentUser?.email ?? '';
            }

            // Priorizar token_hash sobre code
            if (tokenHash.isNotEmpty) {
              return '/reset-password?token_hash=${Uri.encodeComponent(tokenHash)}&type=recovery&email=${Uri.encodeComponent(email)}';
            } else if (code.isNotEmpty) {
              return '/reset-password?code=$code&type=recovery&email=${Uri.encodeComponent(email)}';
            }
          }

          // Si hay code pero NO es recovery → es confirmación de email
          final hasCode = uriBaseParams.containsKey('code') ||
              state.uri.queryParameters.containsKey('code');
          if (hasCode && !isRecovery) {
            print('📧 Código de confirmación de email detectado → /email-confirmed');
            final emailCode = uriBaseParams['code'] ??
                state.uri.queryParameters['code'] ??
                '';
            return '/email-confirmed?code=${Uri.encodeComponent(emailCode)}';
          }
        }

        // Si es perfil público o chat, permitir si hay sesión
        if (location.startsWith('/user-profile') ||
            location.startsWith('/chat')) {
          return null;
        }

        // Si no hay sesión, ir a login (pero excepto en reset/forgot password/email-confirmed)
        if (session == null &&
            !location.startsWith('/login') &&
            !location.startsWith('/reset-password') &&
            !location.startsWith('/forgot-password') &&
            !location.startsWith('/email-verification') &&
            !location.startsWith('/auth-callback') &&
            location != '/email-confirmed') {
          return '/login';
        }

        // Si hay sesión y se intenta acceder a login, ir a home
        if (session != null && location.startsWith('/login')) {
          return '/home';
        }

        // 🔒 GUARD: Si hay sesión y el usuario intenta acceder a rutas protegidas,
        // verificar que tenga perfil completo en public.profiles.
        // Rutas protegidas = cualquier ruta que requiere estar logueado y tener perfil.
        final protectedRoutes = [
          '/home',
          '/matches',
          '/profile',
          '/notifications',
          '/map',
          '/my-publications',
          '/settings',
          '/help',
          '/user-profile',
          '/chat',
          '/chatbot',
          '/complaints',
        ];
        final isProtectedRoute =
            protectedRoutes.any((r) => location.startsWith(r));

        if (session != null && isProtectedRoute) {
          try {
            final userId = session.user.id;
            final profile =
                await SupabaseProvider.databaseService.getProfile(userId);
            if (profile == null) {
              print('⚠️ Router guard: usuario sin perfil → /complete-profile');
              final email = Uri.encodeComponent(session.user.email ?? '');
              return '/complete-profile?userId=$userId&email=$email';
            }
          } catch (e) {
            // Si falla la consulta, dejar pasar (evitar loop)
            print('⚠️ Router guard: error consultando perfil: $e');
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/suspended',
          builder: (context, state) => const SuspendedAccountScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const HomeScreen(initialIndex: 4),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) {
            final userId = state.uri.queryParameters['userId'] ?? '';
            final email = state.uri.queryParameters['email'] ?? '';
            return CompleteProfileScreen(userId: userId, email: email);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/email-verification',
          builder: (context, state) => EmailVerificationScreen(
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        // ✅ RUTA: Confirmación de email exitosa (desde el link del correo)
        GoRoute(
          path: '/email-confirmed',
          builder: (context, state) => const EmailConfirmedRedirectScreen(),
        ),
        /*
        GoRoute(
          path: '/email-confirmed-old',
          builder: (context, state) {
            return const EmailConfirmedRedirectScreen();
            // Cuando el usuario llega aquí después de confirmar su email,
            // Supabase ya estableció una sesión. Redirigir a home.

            final session = SupabaseProvider.client.auth.currentSession;
            if (session != null) {
              // Sesión activa → ir a home
              Future.microtask(() => context.go('/home'));
            } else {
              // Sin sesión → ir a login con mensaje
              Future.microtask(() => context.go('/login'));
            }
            // Mostrar loading mientras redirige
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );

          },
        ),
        // 🔐 RUTA DE RECUPERACIÓN DE CONTRASEÑA (desde el email)
        */
        GoRoute(
          path: '/auth-callback',
          builder: (context, state) {
            // Debug: Mostrar toda la URI
            print('🔍 URI Completa: ${state.uri}');
            print('🔍 Query Parameters: ${state.uri.queryParameters}');
            print('🔍 Fragment: ${state.uri.fragment}');

            // Capturar parámetros de la URL
            String token = '';
            String code = '';
            String tokenHash = '';
            String type = '';
            String email = '';

            tokenHash = state.uri.queryParameters['token_hash'] ?? '';
            if (tokenHash.isNotEmpty) {
              type = state.uri.queryParameters['type'] ?? 'recovery';
              email = state.uri.queryParameters['email'] ?? '';
              print('📝 Token Hash (Supabase recovery): $tokenHash');

              return ResetPasswordScreen(
                resetToken: '',
                tokenHash: tokenHash,
                email: email.isNotEmpty ? email : null,
              );
            }

            // Si hay code (nuevo flujo de Supabase), usarlo
            if (state.uri.queryParameters.containsKey('code')) {
              code = state.uri.queryParameters['code'] ?? '';
              type = state.uri.queryParameters['type'] ?? 'recovery';
              print('📝 Code (Supabase recovery): $code');
              print('📝 Type: $type');

              // Retornar ResetPasswordScreen con el code
              // El code será procesado por verifyOtp() en el provider
              return ResetPasswordScreen(
                resetToken: code,
                email: null,
              );
            }

            // Si hay token directo (fallback), usarlo
            if (state.uri.queryParameters.containsKey('token')) {
              token = state.uri.queryParameters['token'] ?? '';
              type = state.uri.queryParameters['type'] ?? '';
              email = state.uri.queryParameters['email'] ?? '';
            }
            // Si no, buscar en el fragment
            else if (state.uri.fragment.isNotEmpty) {
              final fragmentParams =
                  Uri.parse('http://example.com?${state.uri.fragment}')
                      .queryParameters;
              tokenHash = fragmentParams['token_hash'] ?? '';
              token = fragmentParams['access_token'] ?? '';
              type = fragmentParams['type'] ?? '';
              email = fragmentParams['email'] ?? '';
            }

            if (tokenHash.isNotEmpty) {
              return ResetPasswordScreen(
                resetToken: '',
                tokenHash: tokenHash,
                email: email.isNotEmpty ? email : null,
              );
            }

            print('📝 Token: $token');
            print('📝 Type: $type');
            print('📝 Email: $email');

            // Si es recuperación de contraseña
            if ((type == 'recovery' || type.isEmpty) && token.isNotEmpty) {
              return ResetPasswordScreen(
                resetToken: token,
                email: email.isNotEmpty ? email : null,
              );
            }

            // Fallback: mostrar error en ResetPasswordScreen
            return const ResetPasswordScreen(
              resetToken: '',
              email: null,
            );
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            // Leer error_code primero — si viene, mostrar pantalla de error
            final errorCode = state.uri.queryParameters['error_code'] ?? '';

            // ── 1. Extraer token_hash (método principal, NO requiere PKCE) ──
            String tokenHash = state.uri.queryParameters['token_hash'] ?? '';
            if (tokenHash.isEmpty) {
              tokenHash = Uri.base.queryParameters['token_hash'] ?? '';
            }

            // ── 2. Extraer code PKCE (legacy/fallback) ──
            String token = state.uri.queryParameters['code'] ?? '';
            if (token.isEmpty) {
              token = Uri.base.queryParameters['code'] ?? '';
            }
            if (token.startsWith('/')) {
              token = token.substring(1);
            }
            if (token.isEmpty) {
              token = state.uri.queryParameters['token'] ?? '';
            }
            if (token.isEmpty) {
              token = Uri.base.queryParameters['token'] ?? '';
            }

            // ── 3. Extraer email ──
            String email = state.uri.queryParameters['email'] ?? '';
            if (email.isEmpty) {
              email = Uri.base.queryParameters['email'] ?? '';
            }

            // ── 4. Buscar en fragment como último recurso ──
            if (tokenHash.isEmpty && token.isEmpty && state.uri.fragment.isNotEmpty) {
              final fragmentParams =
                  Uri.parse('http://example.com?${state.uri.fragment}')
                      .queryParameters;
              tokenHash = fragmentParams['token_hash'] ?? '';
              token = fragmentParams['code'] ?? '';
              if (token.startsWith('/')) {
                token = token.substring(1);
              }
              if (token.isEmpty) {
                token = fragmentParams['access_token'] ?? '';
              }
              if (email.isEmpty) {
                email = fragmentParams['email'] ?? '';
              }
            }

            print('🔍 Reset Password Route');
            print('📝 TokenHash: ${tokenHash.isNotEmpty ? '[present]' : '[empty]'}');
            print('📝 Code/Token: ${token.isNotEmpty ? '[present]' : '[empty]'}');
            print('📧 Email: $email');
            print('⚠️ Error Code: $errorCode');

            return ResetPasswordScreen(
              resetToken: token,
              tokenHash: tokenHash,
              email: email.isNotEmpty ? email : null,
              errorCode: errorCode,
            );
          },
        ),
        GoRoute(
          path: '/chatbot',
          builder: (context, state) => const ChatbotScreen(),
        ),
        GoRoute(
          path: '/user-profile',
          builder: (context, state) {
            final userId = state.extra as String? ?? '';
            return UserProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            final matchId = state.extra as String? ?? '';
            return ChatScreen(matchId: matchId);
          },
        ),
        // ==================== RUTAS DE ADMINISTRADOR ====================
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/properties',
          builder: (context, state) => const AdminPropertiesScreen(),
        ),
        GoRoute(
          path: '/admin/feedback',
          builder: (context, state) => const AdminFeedbackScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MatchingProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => RoommateSearchProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatbotProvider(
            chatbotService: ChatbotService(),
            databaseService:
                SupabaseDatabaseService(supabase: SupabaseProvider.client),
          ),
        ),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, AuthProvider>(
        builder: (context, themeProvider, localeProvider, authProvider, child) {
          // Inicializar autenticación al abrir la app
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_didInitializeAuth == true) return;
            _didInitializeAuth = true;

            authProvider.initializeAuth().then((_) {
              if (authProvider.isSuspendedAccount) {
                _router.go('/suspended');
              }
            });
          });

          return MaterialApp.router(
            title: 'ConVive',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

class EmailConfirmedRedirectScreen extends StatefulWidget {
  const EmailConfirmedRedirectScreen({Key? key}) : super(key: key);

  /// El deep link handler guarda aquí el code antes de navegar a /email-confirmed.
  /// Esto evita depender de Uri.base (que en Android siempre es localhost/).
  static String? pendingCode;

  @override
  State<EmailConfirmedRedirectScreen> createState() =>
      _EmailConfirmedRedirectScreenState();
}

class _EmailConfirmedRedirectScreenState
    extends State<EmailConfirmedRedirectScreen> {
  bool _emailConfirmed = false;
  String _message = 'Verificando email...';

  @override
  void initState() {
    super.initState();
    _confirmEmailAndRedirect();
  }

  Future<void> _confirmEmailAndRedirect() async {
    try {
      // 1️⃣ Leer el code:
      //    - En Android: viene del pendingCode que llenó _handleDeepLink()
      //    - En Web:     viene de Uri.base.queryParameters (el navegador tiene la URL completa)
      final String code = EmailConfirmedRedirectScreen.pendingCode ??
          Uri.base.queryParameters['code'] ??
          '';

      // Limpiar el pendingCode para evitar que se reutilice
      EmailConfirmedRedirectScreen.pendingCode = null;

      final String errorCode = Uri.base.queryParameters['error_code'] ?? '';

      debugPrint('🔍 [EmailConfirmed] code=$code errorCode=$errorCode');
      debugPrint('🔍 [EmailConfirmed] Uri.base=${Uri.base}');

      if (errorCode.isNotEmpty) {
        if (mounted) {
          setState(() {
            _emailConfirmed = false;
            _message = 'El enlace expiró. Solicita uno nuevo.';
          });
        }
        // No redirigir automáticamente - el usuario debe tomar una acción manualmente
        return;
      }

      if (code.isEmpty) {
        // Sin code en la URL — posiblemente ya se procesó o es acceso directo
        print('⚠️ No se encontró code en la URL');
        if (mounted) {
          setState(() {
            _emailConfirmed = true;
            _message = '¡Tu correo ha sido confirmado!';
          });
        }
        // No redirigir automáticamente - el usuario debe volver a la app manualmente
        return;
      }

      // ✅ Intentar intercambiar el code por una sesión
      // NOTA: Esto puede fallar si el code_verifier PKCE no está disponible
      // (por ejemplo, cuando el usuario se registró en otro navegador/origen).
      // Supabase ya confirmó el email server-side al hacer clic en el enlace,
      // así que si falla, simplemente redirigimos a login.
      bool sessionCreated = false;

      try {
        print('🔄 Intentando exchangeCodeForSession...');
        await SupabaseProvider.client.auth
            .exchangeCodeForSession(code)
            .timeout(const Duration(seconds: 10));

        final user = SupabaseProvider.client.auth.currentUser;
        if (user != null) {
          sessionCreated = true;
          print('✅ Sesión creada exitosamente para: ${user.email}');

          // Intentar crear el usuario en public.users
          final userId = user.id;
          final userEmail = user.email ?? '';
          final userMetadata = user.userMetadata ?? {};
          final fullName = userMetadata['full_name'] as String? ?? '';
          final role = userMetadata['role'] as String? ?? 'student';

          print('📝 Creando usuario en public.users...');
          try {
            await SupabaseProvider.client.from('users').insert({
              'id': userId,
              'email': userEmail,
              'full_name': fullName,
              'role': role,
            });
            print('✅ Usuario creado en public.users');
          } catch (insertErr) {
            final errStr = insertErr.toString();
            if (errStr.contains('duplicate') || errStr.contains('unique')) {
              print('⚠️ Usuario ya existe en public.users (esperado)');
            } else {
              print('⚠️ Error al insertar en public.users: $insertErr');
            }
          }
        }
      } catch (exchangeErr) {
        print('⚠️ exchangeCodeForSession falló (esperado si PKCE code_verifier '
            'no está en este origen): $exchangeErr');
        // No es error fatal — Supabase ya confirmó el email server-side
      }

      // ✅ Mostrar éxito
      if (mounted) {
        setState(() {
          _emailConfirmed = true;
          _message = sessionCreated
              ? '¡Correo confirmado! Ya puedes iniciar sesión.'
              : '¡Correo confirmado! Inicia sesión para continuar.';
        });
      }

      // 📱 En Android APK: auto-redirigir a /login después de 2 segundos
      // porque el usuario YA está en la app (deep link abrió el APK).
      // 🌐 En Web: NO redirigir — el usuario debe volver manualmente a la app.
      if (!kIsWeb) {
        debugPrint('📱 [EmailConfirmed] Android → auto-redirect a /login en 2s');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // Cerrar sesión de confirmación (si existe) para que haga login limpio
          try {
            await SupabaseProvider.client.auth.signOut();
          } catch (_) {}
          GoRouter.of(context).go('/login');
        }
      } else {
        debugPrint('🌐 [EmailConfirmed] Web → usuario debe volver a la app manualmente');
      }
    } catch (e) {
      print('❌ Error en _confirmEmailAndRedirect: $e');
      // Aun con error, el email probablemente ya fue confirmado
      if (mounted) {
        setState(() {
          _emailConfirmed = true;
          _message = '¡Correo confirmado! Inicia sesión para continuar.';
        });
      }
      // 📱 Android: auto-redirect incluso con error
      if (!kIsWeb && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) GoRouter.of(context).go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F7), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _emailConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.mark_email_read_rounded,
                  size: 58,
                  color: _emailConfirmed
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDB2777),
                ),
                const SizedBox(height: 18),
                Text(
                  _emailConfirmed ? 'Email verificado' : 'Verificando email...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 22),
                if (!_emailConfirmed)
                  const CircularProgressIndicator(
                    color: Color(0xFFDB2777),
                    strokeWidth: 3,
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Tu email ha sido confirmado exitosamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        kIsWeb
                            ? 'Por favor, regresa a la app para completar tu registro.'
                            : 'Redirigiendo al login...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
