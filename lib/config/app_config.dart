import 'package:flutter/foundation.dart';

/// URLs y configuracion segun ambiente.
abstract class AppConfig {
  /// Supabase
  static const String supabaseUrl = 'https://xdpknfhbieejnqpjqpll.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_N1HtO6hxmRLYb8V1kL0uoA_n3LKuHUv';

  /// Microservicio IA.
  ///
  /// En desarrollo usa localhost. Para APK/produccion debe enviarse con:
  /// --dart-define=AI_SERVICE_URL=https://tu-backend.com
  static const String _aiServiceUrlFromEnv =
      String.fromEnvironment('AI_SERVICE_URL');
  static const bool _useLocalBackend =
      bool.fromEnvironment('USE_LOCAL_BACKEND');

  static String get aiServiceUrl {
    if (_aiServiceUrlFromEnv.isNotEmpty) return _aiServiceUrlFromEnv;
    if (!kReleaseMode && _useLocalBackend) return 'http://localhost:8000';
    return '';
  }

  /// Backend guiado del chatbot.
  ///
  /// En release queda desactivado si no se configura explicitamente, para evitar
  /// errores por localhost dentro del celular.
  static const String _chatbotMockUrlFromEnv =
      String.fromEnvironment('CHATBOT_MOCK_URL');
  static String get chatbotMockUrl {
    if (_chatbotMockUrlFromEnv.isNotEmpty) return _chatbotMockUrlFromEnv;
    if (!kReleaseMode && _useLocalBackend) return 'http://localhost:8001';
    return '';
  }

  /// OneSignal
  static const String oneSignalAppId = 'your-onesignal-app-id';

  /// Otras configuraciones
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
