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
  final Map<String, DateTime> _lastProcessedTime = {}; // Rastrear último mensaje procesado

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

    controller = StreamController<Message>.broadcast(
      onListen: () {
        try {
          print('🔌 onListen disparado - Intentando conectar canal realtime');
          
          // ✅ USAR CANAL CACHEADO SI EXISTE, sino crear uno nuevo
          if (_channelCache.containsKey(chatId)) {
            print('♻️ REUSING canal cacheado para chat $chatId');
            final channel = _channelCache[chatId]!;
            print('✅ Canal ya existe, reutilizando suscripción');
            return;
          }

          // ✅ CREAR CANAL CON NOMBRE ÚNICO (UUID) para evitar colisiones
          final channelName = 'messages_${DateTime.now().millisecondsSinceEpoch}_$chatId';
          
          final channel = _supabase
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
                callback: (payload) async {
                  try {
                    print('✅ REALTIME CALLBACK DISPARADO - Nuevo mensaje recibido');
                    
                    // Extraer el nuevo registro del payload (PostgresChangePayload)
                    final newRecord = payload.newRecord;
                    print('📦 newRecord: $newRecord');
                    
                    if (newRecord == null) {
                      print('⚠️ Payload.newRecord es null - obteniendo mensajes más nuevos del chat...');
                      // Fallback: obtener mensajes más nuevos que el último procesado
                      try {
                        final lastTime = _lastProcessedTime[chatId] ?? DateTime.now().subtract(const Duration(seconds: 30));
                        print('🔍 Buscando mensajes después de: $lastTime');
                        
                        final lastMessages = await _supabase
                            .from('messages')
                            .select('*')
                            .eq('chat_id', chatId)
                            .gt('created_at', lastTime.toIso8601String())
                            .order('created_at', ascending: false)
                            .limit(5); // Obtener hasta 5 últimos para detectar múltiples
                        
                        print('📨 Encontrados ${lastMessages.length} mensajes nuevos');
                        
                        if (lastMessages.isNotEmpty) {
                          // Procesar en orden inverso (más antiguos primero)
                          for (int i = lastMessages.length - 1; i >= 0; i--) {
                            final msg = Message.fromJson(lastMessages[i]);
                            
                            // Actualizar el tiempo procesado
                            if (msg.createdAt.isAfter(_lastProcessedTime[chatId] ?? DateTime(1970))) {
                              _lastProcessedTime[chatId] = msg.createdAt;
                            }
                            
                            if (!controller.isClosed) {
                              controller.add(msg);
                            }
                            print('✅ Mensaje agregado via fallback: ${msg.id}');
                          }
                        }
                      } catch (fallbackErr) {
                        print('❌ Error en fallback: $fallbackErr');
                      }
                      return;
                    }

                    // Si tenemos el newRecord completo, usarlo directamente
                    if (newRecord is Map<String, dynamic>) {
                      try {
                        final message = Message.fromJson(newRecord);
                        
                        // Actualizar el tiempo del último procesado
                        if (message.createdAt.isAfter(_lastProcessedTime[chatId] ?? DateTime(1970))) {
                          _lastProcessedTime[chatId] = message.createdAt;
                        }
                        
                        print('📨 Mensaje recibido (realtime): ${message.id}');
                        if (!controller.isClosed) {
                          controller.add(message);
                        }
                      } catch (e) {
                        print('❌ Error parseando mensaje: $e');
                        // Si no se puede parsear, obtener de la BD por ID
                        final messageId = newRecord['id'] as String?;
                        if (messageId != null) {
                          try {
                            final response = await _supabase
                                .from('messages')
                                .select('*')
                                .eq('id', messageId)
                                .single();
                            final message = Message.fromJson(response);
                            
                            if (message.createdAt.isAfter(_lastProcessedTime[chatId] ?? DateTime(1970))) {
                              _lastProcessedTime[chatId] = message.createdAt;
                            }
                            
                            if (!controller.isClosed) {
                              controller.add(message);
                            }
                          } catch (err) {
                            print('❌ Error obteniendo mensaje de BD: $err');
                          }
                        }
                      }
                    } else {
                      print('⚠️ newRecord no es Map, obteniendo mensajes más nuevos de la BD...');
                      // Fallback: obtener últimos mensajes del chat
                      try {
                        final lastTime = _lastProcessedTime[chatId] ?? DateTime.now().subtract(const Duration(seconds: 30));
                        final newerMessages = await _supabase
                            .from('messages')
                            .select('*')
                            .eq('chat_id', chatId)
                            .gt('created_at', lastTime.toIso8601String())
                            .order('created_at', ascending: true)
                            .limit(10);
                        
                        if (newerMessages.isNotEmpty) {
                          for (final msgData in newerMessages) {
                            final message = Message.fromJson(msgData);
                            
                            if (message.createdAt.isAfter(_lastProcessedTime[chatId] ?? DateTime(1970))) {
                              _lastProcessedTime[chatId] = message.createdAt;
                            }
                            
                            if (!controller.isClosed) {
                              controller.add(message);
                            }
                            print('✅ Mensaje obtenido como fallback: ${message.id}');
                          }
                        }
                      } catch (fallbackErr) {
                        print('❌ Error en fallback: $fallbackErr');
                      }
                    }
                  } catch (e) {
                    print('❌ Error en realtime callback: $e');
                    // Fallback extremo: obtener mensajes nuevos si todo falla
                    try {
                      final lastTime = _lastProcessedTime[chatId] ?? DateTime.now().subtract(const Duration(seconds: 30));
                      final lastMessages = await _supabase
                          .from('messages')
                          .select('*')
                          .eq('chat_id', chatId)
                          .gt('created_at', lastTime.toIso8601String())
                          .order('created_at', ascending: true)
                          .limit(10);
                      
                      if (lastMessages.isNotEmpty) {
                        for (final msgData in lastMessages) {
                          final message = Message.fromJson(msgData);
                          
                          if (message.createdAt.isAfter(_lastProcessedTime[chatId] ?? DateTime(1970))) {
                            _lastProcessedTime[chatId] = message.createdAt;
                          }
                          
                          if (!controller.isClosed) {
                            controller.add(message);
                          }
                        }
                        print('✅ ${lastMessages.length} mensajes agregados via fallback extremo');
                      }
                    } catch (fallbackErr) {
                      print('❌ Error en fallback extremo: $fallbackErr');
                    }
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
