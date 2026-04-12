import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/chat_screen.dart';
import 'config/supabase_provider.dart';
import 'config/ai_service_provider.dart';
import 'providers/index.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/chatbot_provider.dart';
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

        // Si es un reset password
        if (uri.host == 'auth-callback' || uri.path.contains('auth-callback')) {
          // Intentar obtener el token del fragment (donde Supabase lo pone)
          String token = '';
          String type = '';
          String email = '';

          // Primero buscar en query parameters (fallback)
          if (uri.queryParameters.containsKey('token')) {
            token = uri.queryParameters['token'] ?? '';
            type = uri.queryParameters['type'] ?? '';
            email = uri.queryParameters['email'] ?? '';
          }
          // Si no, buscar en el fragment (donde Supabase lo envía realmente)
          else if (uri.fragment.isNotEmpty) {
            // El fragment viene como: access_token=...&type=recovery
            final fragmentParams = Uri.parse('http://example.com?${uri.fragment}').queryParameters;
            token = fragmentParams['access_token'] ?? '';
            type = fragmentParams['type'] ?? '';
            email = fragmentParams['email'] ?? '';
          }

          print('📝 Token extraído: $token');
          print('📝 Type: $type');
          print('📝 Email: $email');

          if (token.isNotEmpty) {
            // Navegar a ResetPasswordScreen
            context.push('/reset-password?token=$token&email=$email');
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
        
        // Si es una ruta de recuperación de contraseña o forgot password, permitir (sin redirigir)
        if (location == '/auth-callback' || 
            location == '/reset-password' ||
            location.startsWith('/reset-password?') ||
            location.startsWith('/reset-password#') ||
            location == '/forgot-password' ||
            location.startsWith('/forgot-password?')) {
          return null;
        }
        
        // Si viene de Supabase con parámetros de recovery (en fragment o query), redirigir a /auth-callback
        if (location == '/') {
          // Detectar si es recovery por type=recovery o por presencia de code
          bool isRecovery = state.uri.fragment.contains('type=recovery') || 
                            state.uri.queryParameters['type'] == 'recovery' ||
                            state.uri.queryParameters.containsKey('code');
          
          if (isRecovery) {
            print('🔐 Detectado recovery en URI, redirigiendo a /auth-callback');
            
            // Pasar los parámetros a /auth-callback
            String token = state.uri.queryParameters['access_token'] ?? 
                           Uri.parse('http://example.com?${state.uri.fragment}').queryParameters['access_token'] ?? '';
            String code = state.uri.queryParameters['code'] ?? '';
            String type = state.uri.queryParameters['type'] ?? 'recovery';
            String email = state.uri.queryParameters['email'] ?? '';
            
            // Si hay code, pasarlo también
            if (code.isNotEmpty) {
              return '/auth-callback?code=$code&type=$type';
            } else if (token.isNotEmpty) {
              return '/auth-callback?token=$token&type=$type&email=$email';
            }
          }
        }
        
        // Si es perfil público o chat, permitir si hay sesión
        if (location.startsWith('/user-profile') || location.startsWith('/chat')) {
          return null;
        }

        // Si no hay sesión, ir a login (pero excepto en reset/forgot password)
        if (session == null && !location.startsWith('/login') && 
            !location.startsWith('/reset-password') && 
            !location.startsWith('/forgot-password') &&
            !location.startsWith('/auth-callback')) {
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
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        // 🔐 RUTA DE RECUPERACIÓN DE CONTRASEÑA (desde el email)
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
            
            // Limpiar la barra inicial si existe
            if (token.startsWith('/')) {
              token = token.substring(1);
            }
            
            if (token.isEmpty) {
              token = state.uri.queryParameters['token'] ?? '';  // Fallback a 'token'
            }
            
            String email = state.uri.queryParameters['email'] ?? '';

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
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatbotProvider(
            chatbotService: ChatbotService(),
            databaseService: SupabaseDatabaseService(supabase: SupabaseProvider.client),
          ),
        ),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, AuthProvider>(
        builder: (context, themeProvider, localeProvider, authProvider, child) {
          // Inicializar autenticación al abrir la app
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.initializeAuth();
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
