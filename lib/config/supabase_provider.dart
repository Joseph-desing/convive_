import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/index.dart';
import 'app_config.dart';

class SupabaseProvider {
  static late SupabaseClient _client;
  static late SupabaseAuthService _authService;
  static late SupabaseDatabaseService _databaseService;
  static late SupabaseRealtimeService _realtimeService;
  static late SupabaseStorageService _storageService;
  static late SupabaseMessagesService _messagesService;

  /// Inicializar Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;

      _authService = SupabaseAuthService(supabase: _client);
      _databaseService = SupabaseDatabaseService(supabase: _client);
      _realtimeService = SupabaseRealtimeService(supabase: _client);
      _storageService = SupabaseStorageService(supabase: _client);
      _messagesService = SupabaseMessagesService(supabase: _client);

      if (kDebugMode) {
        print('✅ Supabase inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando Supabase: $e');
      }
      rethrow;
    }
  }

  static SupabaseClient get client => _client;
  static SupabaseAuthService get authService => _authService;
  static SupabaseDatabaseService get databaseService => _databaseService;
  static SupabaseRealtimeService get realtimeService => _realtimeService;
  static SupabaseStorageService get storageService => _storageService;
  static SupabaseMessagesService get messagesService => _messagesService;
}
