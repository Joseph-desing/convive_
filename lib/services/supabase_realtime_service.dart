import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeService {
  final SupabaseClient _supabase;

  SupabaseRealtimeService({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Escuchar cambios en tiempo real de mensajes
  RealtimeChannel subscribeToMessages(String chatId) {
    return _supabase
        .channel('messages:chat_id=eq.$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            // Callback handler
          },
        )
        .subscribe();
  }

  /// Escuchar cambios de estado de match
  RealtimeChannel subscribeToMatches(String userId) {
    return _supabase
        .channel('matches:user_a_id=eq.$userId,user_b_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matches',
          callback: (payload) {
            // Callback handler
          },
        )
        .subscribe();
  }

  /// Dejar de escuchar cambios
  Future<void> unsubscribe(String channel) async {
    await _supabase.removeChannel(
      _supabase.channel(channel),
    );
  }

  /// Enviar actualización en tiempo real
  Future<void> updateMatchStatus(String matchId, String status) async {
    await _supabase.from('matches').update({'status': status}).eq('id', matchId);
  }
}
