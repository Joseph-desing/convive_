import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/email_verification_screen.dart';
import 'utils/colors.dart';
import 'config/supabase_provider.dart';
import 'config/ai_service_provider.dart';
import 'providers/index.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class ConViveApp extends StatelessWidget {
  const ConViveApp({Key? key}) : super(key: key);

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
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
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
            home: const AuthGate(),
            routes: {
              '/home': (_) => const HomeScreen(),
              '/login': (_) => const LoginScreen(),
              '/welcome': (_) => const WelcomeScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();

    SupabaseProvider.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (!mounted) return;

      switch (event) {
        case AuthChangeEvent.passwordRecovery:
          _showResetPasswordDialog(context);
          break;

        case AuthChangeEvent.signedIn:
          // Nada aquí: StreamBuilder se encarga del flujo
          break;

        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseProvider.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final session = SupabaseProvider.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return const HomeScreen();
      },
    );
  }

  // 🔐 Modal IN-APP para cambiar contraseña
  void _showResetPasswordDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Nueva contraseña'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu nueva contraseña',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SupabaseProvider.client.auth.updateUser(
                UserAttributes(password: controller.text),
              );

              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}



