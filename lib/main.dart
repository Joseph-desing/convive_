import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
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
import 'config/groq_config.dart';
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
  bool? _didInitializeAuth = false;

  @override
  void initState() {
    super.initState();
    _router = _setupRouter();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    _appLinks = AppLinks();
    
    // Escuchar deep links cuando la app está abierta
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('🔗 Deep link recibido: $uri');
        print('🔗 Scheme: ${uri.scheme}');
        print('🔗 Host: ${uri.host}');
        print('🔗 Path: ${uri.path}');
        print('🔗 Query Parameters: ${uri.queryParameters}');
        print('🔗 Fragment: ${uri.fragment}');

        final host = uri.host;
        final path = uri.path;

        // ── CASO 1: Reset password con code (flujo PKCE de Supabase) ──
        // URI: com.example.convive://reset-password?code=XXX
        if (host == 'reset-password' ||
            path.contains('reset-password') ||
            uri.fragment.contains('reset-password') ||
            uri.queryParameters['type'] == 'recovery') {
          String code = uri.queryParameters['code'] ?? '';
          String token = uri.queryParameters['token'] ?? '';
          String email = uri.queryParameters['email'] ?? '';

          // Fallback: buscar en fragment
          if (code.isEmpty && token.isEmpty && uri.fragment.isNotEmpty) {
            final fp = Uri.parse('http://x.com?${uri.fragment}').queryParameters;
            code = fp['code'] ?? '';
            token = fp['access_token'] ?? '';
            email = fp['email'] ?? '';
          }

          print('📝 Code: $code | Token: $token | Email: $email');

          if (code.isNotEmpty) {
            _router.push('/reset-password?code=${Uri.encodeComponent(code)}&email=${Uri.encodeComponent(email)}');
          } else if (token.isNotEmpty) {
            _router.push('/reset-password?token=${Uri.encodeComponent(token)}&email=${Uri.encodeComponent(email)}');
          }
        }

        // ── CASO 2: Email confirmado (com.example.convive://login-callback) ──
        else if (host == 'login-callback' || path.contains('login-callback')) {
          print('✅ Email confirmado via deep link mobile. Redirigiendo a home...');
          _router.go('/home');
        }

        // ── CASO 3: Auth callback legacy ──
        else if (host == 'auth-callback' || path.contains('auth-callback')) {
          String token = '';
          String email = '';

          if (uri.queryParameters.containsKey('token')) {
            token = uri.queryParameters['token'] ?? '';
            email = uri.queryParameters['email'] ?? '';
          } else if (uri.fragment.isNotEmpty) {
            final fp = Uri.parse('http://x.com?${uri.fragment}').queryParameters;
            token = fp['access_token'] ?? '';
            email = fp['email'] ?? '';
          }

          print('📝 Token: $token | Email: $email');

          if (token.isNotEmpty) {
            _router.push('/reset-password?token=${Uri.encodeComponent(token)}&email=${Uri.encodeComponent(email)}');
          }
        }
      },
      onError: (err) {
        print('❌ Error en deep link: $err');
      },
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
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
        
        // Si es una ruta de recuperación de contraseña, forgot password o email-confirmed, permitir (sin redirigir)
        if (location == '/auth-callback' ||
            location == '/suspended' ||
            location == '/reset-password' ||
            location.startsWith('/reset-password?') ||
            location.startsWith('/reset-password#') ||
            location == '/forgot-password' ||
            location.startsWith('/forgot-password?') ||
            location == '/email-verification' ||
            location.startsWith('/email-verification?') ||
            location == '/email-confirmed' ||
            location.startsWith('/complete-profile')) {
          return null;
        }
        
        // Proteger rutas de admin (solo para usuarios con rol admin)
        if (location.startsWith('/admin')) {
          if (session == null) {
            return '/login';
          }
          // Aquí podrías agregar lógica adicional para verificar el rol
          // Por ahora, permitir si hay sesión
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

          // Detectar si es recovery por type=recovery o por presencia de code
          bool isRecovery = state.uri.fragment.contains('type=recovery') || 
                            state.uri.queryParameters['type'] == 'recovery' ||
                            uriBaseParams['type'] == 'recovery' ||
                            uriBaseParams.containsKey('code') ||
                            state.uri.queryParameters.containsKey('code');
          
          if (isRecovery) {
            print('🔐 Detectado recovery en URI, redirigiendo a /auth-callback');
            
            // Pasar los parámetros a /auth-callback
            String token = state.uri.queryParameters['access_token'] ??
                fragmentParams['access_token'] ??
                uriBaseParams['access_token'] ??
                '';
            String code = state.uri.queryParameters['code'] ??
                uriBaseParams['code'] ??
                fragmentParams['code'] ??
                '';
            String type = state.uri.queryParameters['type'] ??
                uriBaseParams['type'] ??
                fragmentParams['type'] ??
                'recovery';
            String email = state.uri.queryParameters['email'] ??
                uriBaseParams['email'] ??
                fragmentParams['email'] ??
                '';
            
            // Si hay code, pasarlo también
            if (code.isNotEmpty) {
              return '/reset-password?code=$code&type=$type&email=$email';
            } else if (token.isNotEmpty) {
              return '/reset-password?token=$token&type=$type&email=$email';
            }
          }
        }
        
        // Si es perfil público o chat, permitir si hay sesión
        if (location.startsWith('/user-profile') || location.startsWith('/chat')) {
          return null;
        }

        // Si no hay sesión, ir a login (pero excepto en reset/forgot password/email-confirmed)
        if (session == null && !location.startsWith('/login') && 
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
            String type = '';
            String email = '';

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
              final fragmentParams = Uri.parse('http://example.com?${state.uri.fragment}').queryParameters;
              token = fragmentParams['access_token'] ?? '';
              type = fragmentParams['type'] ?? '';
              email = fragmentParams['email'] ?? '';
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
            // Buscar parámetros en query (fallback)
            String token = state.uri.queryParameters['code'] ?? '';  // Primero buscar 'code' (lo que envía Supabase)
            
            String email = state.uri.queryParameters['email'] ?? '';
            if (token.isEmpty) {
              token = Uri.base.queryParameters['code'] ?? '';
            }
            if (email.isEmpty) {
              email = Uri.base.queryParameters['email'] ?? '';
            }

            // Limpiar la barra inicial si existe
            if (token.startsWith('/')) {
              token = token.substring(1);
            }
            
            if (token.isEmpty) {
              token = state.uri.queryParameters['token'] ?? '';  // Fallback a 'token'
            }
            if (token.isEmpty) {
              token = Uri.base.queryParameters['token'] ?? '';
            }

            // Si no hay en query, buscar en fragment
            if (token.isEmpty && state.uri.fragment.isNotEmpty) {
              final fragmentParams = Uri.parse('http://example.com?${state.uri.fragment}').queryParameters;
              token = fragmentParams['code'] ?? '';  // Buscar 'code' en fragment
              
              // Limpiar la barra inicial si existe
              if (token.startsWith('/')) {
                token = token.substring(1);
              }
              
              if (token.isEmpty) {
                token = fragmentParams['access_token'] ?? '';  // Fallback a 'access_token'
              }
              email = fragmentParams['email'] ?? '';
            }

            print('🔍 Reset Password Route');
            print('📝 Token/Code: $token');
            print('📧 Email: $email');

            return ResetPasswordScreen(
              resetToken: token,
              email: email,
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
            chatbotService: ChatbotService(
              groqApiKey: GroqConfig.enableGroq ? GroqConfig.apiKey : null,
            ),
            databaseService: SupabaseDatabaseService(supabase: SupabaseProvider.client),
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
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
      final errorCode = Uri.base.queryParameters['error_code'] ?? '';
      final code = Uri.base.queryParameters['code'] ?? '';

      print('🔍 Email Confirmed Screen');
      print('🔍 Error Code: $errorCode');
      print('🔍 Code from URL: $code');
      print('🔍 Full URI: ${Uri.base}');

      if (errorCode.isNotEmpty) {
        if (mounted) {
          setState(() {
            _emailConfirmed = false;
            _message = 'El enlace expiró. Solicita uno nuevo.';
          });
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
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
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
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
              ? '¡Correo confirmado! Entrando a tu cuenta...'
              : '¡Correo confirmado! Inicia sesión para continuar.';
        });
      }

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (sessionCreated) {
        print('🚀 Sesión activa, redirigiendo a /home');
        context.go('/home');
      } else {
        print('🚀 Sin sesión, redirigiendo a /login');
        context.go('/login');
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
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
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
                  const Text(
                    'Te llevaremos a continuar en un momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
