import 'dart:async';
import 'dart:convert';
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
          .or('user_a_id.eq.$userId,user_b_id.eq.$userId');

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
    print('💬 Buscando chat para match: $matchId');
    
    // Intentar obtener chat existente
    final existing = await _supabase
        .from('chats')
        .select('*')
        .eq('match_id', matchId)
        .maybeSingle();
    
    if (existing != null) {
      print('✅ Chat encontrado: ${existing['id']}');
      return Chat.fromJson(existing);
    }
    
    // Si no existe, crear uno nuevo
    print('🆕 Creando nuevo chat para match: $matchId');
    final chat = Chat(matchId: matchId);
    final chatData = chat.toJson();
    chatData.remove('created_at');
    chatData.remove('updated_at');

    final response = await _supabase
        .from('chats')
        .insert(chatData)
        .select('*')
        .single();
    
    print('✅ Chat creado: ${response['id']}');
    return Chat.fromJson(response);
  }

  // ==================== MESSAGES ====================
  /// Obtener mensajes de un chat (ordenados de antiguo a nuevo)
  Future<List<Message>> getChatMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)  // ✅ Antiguo primero
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
      // Remover createdAt para que Supabase asigne la hora del servidor
      messageData.remove('created_at');
      messageData.remove('updated_at');

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
  /// Nota: utiliza el stream de Supabase filtrado por `chat_id`.
  Stream<Message> watchNewMessages(String chatId) {
    RealtimeChannel? channel;

    // Declarar controller y función intermedia antes de inicializar
    late final StreamController<Message> controller;
    late void Function(Message) _addMessage;

    controller = StreamController<Message>.broadcast(
      onListen: () {
        try {
          print('🔌 onListen disparado - Activando canal realtime para chat: $chatId');
          
          channel = _supabase
              .channel('messages:chat_id=eq.$chatId')
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'messages',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'chat_id',
                  value: chatId,
                ),
                callback: (payload) {
                  try {
                    print('✅ REALTIME CALLBACK DISPARADO - Nuevo mensaje recibido');
                    // Debug: imprimir payload crudo para entender su formato
                    try {
                      final encodedPayload = jsonEncode(payload);
                      print('🔔 RAW PAYLOAD (${payload.runtimeType}): $encodedPayload');
                    } catch (e) {
                      print('🔔 RAW PAYLOAD toString (${payload.runtimeType}): ${payload.toString()}');
                    }

                    // Trabajar con payload como dynamic para evitar errores de operador
                    final dynamic p = payload;
                    dynamic newRecord;

                    if (p is Map) {
                      newRecord = p['new'] ?? p['record'] ?? p['new_record'] ?? p['record_new'];
                    } else {
                      // Fallback: serializar y parsear para extraer el nuevo registro
                      try {
                        final encoded = jsonEncode(p);
                        final decoded = jsonDecode(encoded);
                        if (decoded is Map) {
                          newRecord = decoded['new'] ?? decoded['record'] ?? decoded['new_record'] ?? decoded['record_new'];
                        }
                      } catch (_) {}
                    }

                    if (newRecord == null) {
                      print('⚠️ Realtime payload sin newRecord (tipo ${p.runtimeType})');
                      return;
                    }

                    final parsed = Map<String, dynamic>.from(newRecord as Map);
                    final message = Message.fromJson(parsed);
                    print('📨 Mensaje parseado: ${message.id} - ${message.content}');

                    // Usar la función intermedia (declarada abajo)
                    _addMessage(message);
                  } catch (e, st) {
                    print('❌ Error parseando payload realtime: $e\n$st');
                  }
                },
              )
              .subscribe((status, error) {
                print('📡 Estado de suscripción al canal: $status, error: $error');
                if (status == RealtimeSubscribeStatus.subscribed) {
                  print('✅✅✅ CANAL ACTIVO: Escuchando nuevos mensajes en chat $chatId');
                } else if (status == RealtimeSubscribeStatus.closed) {
                  print('❌ Canal cerrado - intentando reconectar');
                }
              });
          
          print('✅ Canal realtime suscrito correctamente');
        } catch (e, st) {
          print('❌ Error suscribiendo canal realtime: $e\n$st');
        }
      },
      onCancel: () async {
        try {
          print('🛑 onCancel disparado - Limpiando canal realtime');
          if (channel != null) {
            await _supabase.removeChannel(channel!);
            channel = null;
          }
          if (!controller.isClosed) await controller.close();
        } catch (e) {
          print('❌ Error removiendo canal realtime: $e');
        }
      },
    );

    // Inicializar la función que añade mensajes al controller
    _addMessage = (Message msg) {
      if (!controller.isClosed) {
        print('➕ Agregando mensaje al stream: ${msg.id}');
        controller.add(msg);
      }
    };

    return controller.stream;
  }

  /// Obtener la fecha de último leído para un chat y usuario (versión robusta con single)
  Future<DateTime?> getLastReadAt(String chatId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_reads')
          .select('last_read_at')
          .eq('chat_id', chatId)
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      print('DEBUG getLastReadAt response: $response');
      if (response == null || response['last_read_at'] == null) return null;
      final value = response['last_read_at'];
      print('DEBUG last_read_at value: $value, type: ${value.runtimeType}');
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parseando last_read_at: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo lastReadAt (robusto): $e');
      return null;
    }
  }

  /// Actualizar la fecha de último leído para un chat y usuario
  Future<void> updateLastReadAt(String chatId, String userId) async {
    try {
      await _supabase
          .from('chat_reads')
          .upsert({
            'chat_id': chatId,
            'user_id': userId,
            'last_read_at': DateTime.now().toUtc().toIso8601String(),
          });
    } catch (e) {
      print('Error actualizando lastReadAt: $e');
    }
  }
}
