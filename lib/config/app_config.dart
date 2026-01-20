/// URLs y configuración según ambiente
abstract class AppConfig {
  /// Supabase
  static const String supabaseUrl = 'https://xdpknfhbieejnqpjqpll.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_N1HtO6hxmRLYb8V1kL0uoA_n3LKuHUv';
  static const String supabaseSecretKey = 'sb_secret_A3ZbTGjrPbb7yrOSeX4CuQ_rtondvYm';

  /// Microservicio IA
  static const String aiServiceUrl = 'http://localhost:8000';

  /// OneSignal
  static const String oneSignalAppId = 'your-onesignal-app-id';

  /// Otras configuraciones
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
