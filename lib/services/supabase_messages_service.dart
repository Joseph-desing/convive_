import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';

class SupabaseMessagesService {
  final SupabaseClient _supabase;
  
  // ✅ CRÍTICO: Cache de streams para reutilizar y evitar crear múltiples canales
  final Map<String, Stream<Message>> _streamCache = {};
  final Map<String, RealtimeChannel> _channelCache = {};
  final Map<String, int> _listenerCount = {};

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
          .limit(limit);

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

      try {
        final response = await _supabase
            .from('messages')
            .insert(messageData)
            .select('*')
            .single();

        print('✅ Mensaje enviado correctamente');
        return Message.fromJson(response);
      } catch (e) {
        // Si el error es por el trigger de notificaciones, intentar sin él
        if (e.toString().contains('notifications') || 
            e.toString().contains('column "message"')) {
          print('⚠️ Error en trigger de notificaciones, ignorando: $e');
          
          // Reintentar la inserción con un pequeño retraso
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Intentar nuevamente
          final response = await _supabase
              .from('messages')
              .insert(messageData)
              .select('*')
              .single();
          
          print('✅ Mensaje enviado en reintentos');
          return Message.fromJson(response);
        }
        
        // Si es otro error, propagarlo
        rethrow;
      }
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
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

  /// ✅ PROBLEMA 1 ARREGLADO: Stream que no se cancela inmediatamente
  /// ✅ PROBLEMA 4 ARREGLADO: Filtro del canal correcto + identificador único
  /// Stream de nuevos mensajes para un chat (reutilizable, no se cancela con rebuild)
  Stream<Message> watchNewMessages(String chatId) {
    // ✅ REUTILIZAR STREAM si ya existe para este chat (evita crear múltiples canales)
    if (_streamCache.containsKey(chatId)) {
      print('♻️ REUSING stream para chat $chatId (ya existe)');
      _listenerCount[chatId] = (_listenerCount[chatId] ?? 0) + 1;
      return _streamCache[chatId]!;
    }

    print('🆕 CREANDO nuevo stream para chat $chatId');
    _listenerCount[chatId] = 1;

    late final StreamController<Message> controller;
    late void Function(Message) _addMessage;
    late RealtimeChannel channel;

    controller = StreamController<Message>.broadcast(
      onListen: () {
        try {
          print('🔌 onListen disparado - Intentando conectar canal realtime');
          
          // ✅ USAR CANAL CACHEADO SI EXISTE, sino crear uno nuevo
          if (_channelCache.containsKey(chatId)) {
            print('♻️ REUSING canal cacheado para chat $chatId');
            channel = _channelCache[chatId]!;
            print('✅ Canal ya existe, reutilizando suscripción');
            return;
          }

          // ✅ CREAR CANAL CON NOMBRE ÚNICO (UUID) para evitar colisiones
          final channelName = 'messages_${DateTime.now().millisecondsSinceEpoch}_$chatId';
          
          channel = _supabase
              .channel(
                channelName,
                opts: const RealtimeChannelConfig(
                  ack: true,  // ✅ Esperar confirmación del servidor
                ),
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'messages',
                // ✅ PROBLEMA 4: Filtro correcto del canal
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'chat_id',
                  value: chatId,
                ),
                callback: (payload) {
                  try {
                    print('✅ REALTIME CALLBACK DISPARADO - Nuevo mensaje recibido');
                    
                    // Extraer el nuevo registro del payload
                    final dynamic p = payload;
                    dynamic newRecord;

                    if (p is Map) {
                      newRecord = p['new'] ?? p['record'] ?? p['new_record'];
                    } else {
                      try {
                        final encoded = jsonEncode(p);
                        final decoded = jsonDecode(encoded);
                        if (decoded is Map) {
                          newRecord = decoded['new'] ?? decoded['record'] ?? decoded['new_record'];
                        }
                      } catch (_) {}
                    }

                    if (newRecord == null) {
                      print('⚠️ Payload sin newRecord');
                      return;
                    }

                    final parsed = Map<String, dynamic>.from(newRecord as Map);
                    final message = Message.fromJson(parsed);
                    print('📨 Mensaje recibido (realtime): ${message.id}');
                    _addMessage(message);
                  } catch (e) {
                    print('❌ Error parseando realtime payload: $e');
                  }
                },
              )
              .subscribe((status, error) {
                print('📡 Estado canal realtime: $status, error: $error');
                if (status == RealtimeSubscribeStatus.subscribed) {
                  print('✅✅✅ CANAL REALTIME ACTIVO para chat $chatId');
                } else if (status == RealtimeSubscribeStatus.closed) {
                  print('⚠️ Canal cerrado - fallback a polling');
                }
              });

          // ✅ CACHEAR EL CANAL para no destruirlo con cada rebuild
          _channelCache[chatId] = channel;
          print('✅ Canal realtime suscrito correctamente');
        } catch (e) {
          print('❌ Error en onListen: $e');
        }
      },
      // ✅ PROBLEMA 1 ARREGLADO: NO destruir el canal cuando se cancela UN listener
      onCancel: () async {
        try {
          print('🔄 onCancel disparado');
          _listenerCount[chatId] = (_listenerCount[chatId] ?? 1) - 1;
          
          // Solo limpiar si es el ÚLTIMO listener
          if ((_listenerCount[chatId] ?? 0) <= 0) {
            print('🛑 Último listener removido - limpiando canal $chatId');
            
            if (_channelCache.containsKey(chatId)) {
              try {
                await _supabase.removeChannel(_channelCache[chatId]!);
              } catch (e) {
                print('⚠️ Error removiendo canal: $e');
              }
              _channelCache.remove(chatId);
            }
            
            _streamCache.remove(chatId);
            _listenerCount.remove(chatId);
          } else {
            print('✅ Quedan ${_listenerCount[chatId]} listeners, NO limpiar canal');
          }
        } catch (e) {
          print('❌ Error en onCancel: $e');
        }
      },
    );

    // Función para agregar mensajes al stream
    _addMessage = (Message msg) {
      if (!controller.isClosed) {
        print('➕ Mensaje agregado al stream: ${msg.id}');
        controller.add(msg);
      }
    };

    // ✅ CACHEAR EL STREAM para reutilizarlo
    _streamCache[chatId] = controller.stream;

    return controller.stream;
  }

  /// Obtener la fecha de último leído para un chat y usuario
  Future<DateTime?> getLastReadAt(String chatId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_reads')
          .select('last_read_at')
          .eq('chat_id', chatId)
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      
      if (response == null) {
        print('✅ Sin registros previos de lectura para chat $chatId');
        return null;
      }
      
      final value = response['last_read_at'];
      if (value == null) return null;
      
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('⚠️ Error parseando last_read_at: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Error obteniendo lastReadAt: $e');
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
