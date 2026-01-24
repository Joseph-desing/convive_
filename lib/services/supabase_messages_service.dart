import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';

class SupabaseMessagesService {
  final SupabaseClient _supabase;

  SupabaseMessagesService({required SupabaseClient supabase})
      : _supabase = supabase;

  // ==================== CHATS ====================
  /// Obtener todos los chats del usuario
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      // Obtener todos los matches donde el usuario está involucrado
      final matchesResponse = await _supabase
          .from('matches')
          .select('id')
          .or('user_a.eq.$userId,user_b.eq.$userId');

      final matchIds =
          (matchesResponse as List).map((m) => m['id'] as String).toList();

      if (matchIds.isEmpty) {
        return [];
      }

      // Obtener chats para esos matches
      final chatsResponse = await _supabase
          .from('chats')
          .select('*')
          .inFilter('match_id', matchIds)
          .order('created_at', ascending: false);

      return (chatsResponse as List).map((c) => Chat.fromJson(c)).toList();
    } catch (e) {
      print('Error obteniendo chats: $e');
      return [];
    }
  }

  /// Obtener o crear chat para un match
  Future<Chat> getOrCreateChat(String matchId) async {
    try {
      // Intentar obtener chat existente
      final response = await _supabase
          .from('chats')
          .select('*')
          .eq('match_id', matchId)
          .single();
      return Chat.fromJson(response);
    } catch (e) {
      // Si no existe, crear uno nuevo
      if (e.toString().contains('no rows')) {
        final chat = Chat(matchId: matchId);
        final chatData = chat.toJson();
        chatData.remove('createdAt');
        chatData.remove('updatedAt');

        final response = await _supabase
            .from('chats')
            .insert(chatData)
            .select('*')
            .single();
        return Chat.fromJson(response);
      }
      rethrow;
    }
  }

  // ==================== MESSAGES ====================
  /// Obtener mensajes de un chat
  Future<List<Message>> getChatMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((m) => Message.fromJson(m)).toList();
    } catch (e) {
      print('Error obteniendo mensajes: $e');
      return [];
    }
  }

  /// Enviar un nuevo mensaje
  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      final message = Message(
        chatId: chatId,
        senderId: senderId,
        content: content,
      );

      final messageData = message.toJson();
      messageData.remove('createdAt');
      messageData.remove('updatedAt');

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select('*')
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('Error enviando mensaje: $e');
      rethrow;
    }
  }

  /// Actualizar un mensaje
  Future<void> updateMessage(String messageId, String newContent) async {
    try {
      await _supabase
          .from('messages')
          .update({'content': newContent})
          .eq('id', messageId);
    } catch (e) {
      print('Error actualizando mensaje: $e');
      rethrow;
    }
  }

  /// Eliminar un mensaje
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      print('Error eliminando mensaje: $e');
      rethrow;
    }
  }

  /// Stream de nuevos mensajes para un chat
  Stream<Message> watchNewMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .map((List<dynamic> data) {
          if (data.isEmpty) throw Exception('No hay datos');
          return Message.fromJson(data.last);
        });
  }
}
