import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';

/// Provider para gestionar mensajes y chats
class MessagesProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  List<ChatPreview> _chatPreviews = []; // Datos optimizados para lista
  Map<String, List<Message>> _messages = {}; // chatId -> messages
  Map<String, bool> _loadingChats = {}; // chatId -> isLoading
  Map<String, DateTime> _lastReadAt = {}; // chatId -> lastReadAt
  String? _error;
  String? _selectedChatId;

  List<Chat> get chats => _chats;
  List<ChatPreview> get chatPreviews => _chatPreviews; // ✅ Para usar en UI sin queries
  String? get error => _error;
  bool get isLoadingChats => _chats.isEmpty && _loadingChats.isEmpty;
  String? get selectedChatId => _selectedChatId;

  /// Obtener mensajes de un chat específico
  List<Message> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  /// Saber si un chat está cargando
  bool isChatLoading(String chatId) {
    return _loadingChats[chatId] ?? false;
  }

  /// ✅ NUEVO: Cargar previews de chats (optimizado)
  /// Una sola operación para obtener todo lo necesario
  /// ✅ Consolida múltiples chats del mismo usuario en uno solo
  Future<void> loadChatPreviews(String userId) async {
    _error = null;
    notifyListeners();

    try {
      _chats = await SupabaseProvider.messagesService.getUserChats(userId);
      _chatPreviews = [];

      // Mapa para consolidar chats por usuario (un chat por usuario)
      Map<String, ChatPreview> consolidatedChats = {};

      for (final chat in _chats) {
        try {
          // Obtener match data
          final match = await SupabaseProvider.databaseService.getMatch(chat.matchId);
          if (match == null) continue;

          final otherUserId = match.userA == userId ? match.userB : match.userA;

          // Obtener perfil del otro usuario
          final profile = await SupabaseProvider.databaseService.getProfile(otherUserId);
          if (profile == null) continue;

          // Obtener último mensaje
          final messages = await SupabaseProvider.messagesService.getChatMessages(chat.id, limit: 50);
          _messages[chat.id] = messages;
          final lastMessage =
              messages.isNotEmpty ? messages.where((m) => m.senderId == otherUserId).lastOrNull : null;

          // Obtener último mensaje leído
          final lastReadAt = await SupabaseProvider.messagesService.getLastReadAt(chat.id, userId);
          _lastReadAt[chat.id] = lastReadAt ?? DateTime.now();

          // Contar mensajes no leídos
          final unreadCount = messages
              .where((m) => m.senderId == otherUserId && (lastReadAt == null || m.createdAt.isAfter(lastReadAt)))
              .length;

          // Crear preview
          final newPreview = ChatPreview(
            chat: chat,
            otherUserProfile: profile,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
          );

          // ✅ Consolidar: si ya existe un chat con este usuario, mantener el más reciente
          if (consolidatedChats.containsKey(otherUserId)) {
            final existingPreview = consolidatedChats[otherUserId]!;
            // Mantener el chat con mensajes más recientes
            if (lastMessage != null && 
                (existingPreview.lastMessage == null || 
                 lastMessage.createdAt.isAfter(existingPreview.lastMessage!.createdAt))) {
              consolidatedChats[otherUserId] = newPreview;
            }
          } else {
            consolidatedChats[otherUserId] = newPreview;
          }
        } catch (e) {
          print('Error cargando preview del chat ${chat.id}: $e');
        }
      }

      // Convertir map a lista
      _chatPreviews = consolidatedChats.values.toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error cargando previews: $e');
    }

    notifyListeners();
  }

  /// Cargar todos los chats del usuario
  Future<void> loadUserChats(String userId) async {
    _error = null;
    notifyListeners();

    try {
      _chats = await SupabaseProvider.messagesService.getUserChats(userId);
      _error = null;
      // Cargar mensajes de cada chat automáticamente
      for (final chat in _chats) {
        try {
          final messages = await SupabaseProvider.messagesService.getChatMessages(chat.id, limit: 50);
          _messages[chat.id] = messages.reversed.toList();
        } catch (e) {
          print('Error cargando mensajes del chat ${chat.id}: $e');
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Error cargando chats: $e');
    }
    notifyListeners();
  }

  /// Cargar mensajes de un chat específico
  Future<void> loadChatMessages(String chatId, {int limit = 50}) async {
    _loadingChats[chatId] = true;
    notifyListeners();

    try {
      final messages =
          await SupabaseProvider.messagesService.getChatMessages(chatId, limit: limit);
      _messages[chatId] = messages;  // ✅ Mantener orden: antiguo → nuevo
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error cargando mensajes del chat: $e');
    }

    _loadingChats[chatId] = false;
    notifyListeners();
  }

  /// Seleccionar un chat
  void selectChat(String chatId) {
    _selectedChatId = chatId;
    notifyListeners();
  }

  /// Deseleccionar chat
  void deselectChat() {
    _selectedChatId = null;
    notifyListeners();
  }

  /// Enviar un mensaje
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      final message = await SupabaseProvider.messagesService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
      );

      // Agregar el mensaje a la lista local
      if (!_messages.containsKey(chatId)) {
        _messages[chatId] = [];
      }
      _messages[chatId]!.add(message);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error enviando mensaje: $e');
    }
    notifyListeners();
  }

  /// Actualizar un mensaje
  Future<void> updateMessage(String chatId, String messageId, String newContent) async {
    try {
      await SupabaseProvider.messagesService
          .updateMessage(messageId, newContent);

      // Actualizar en la lista local
      if (_messages.containsKey(chatId)) {
        final index = _messages[chatId]!
            .indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[chatId]![index] =
              _messages[chatId]![index].copyWith(content: newContent);
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error actualizando mensaje: $e');
    }
    notifyListeners();
  }

  /// Eliminar un mensaje
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await SupabaseProvider.messagesService.deleteMessage(messageId);

      // Eliminar de la lista local
      if (_messages.containsKey(chatId)) {
        _messages[chatId]!.removeWhere((m) => m.id == messageId);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error eliminando mensaje: $e');
    }
    notifyListeners();
  }

  /// ✅ PROBLEMA 5 ARREGLADO: Agregar mensaje entrante sin duplicados
  void addIncomingMessage(String chatId, Message message) {
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = [];
    }
    
    // ✅ PREVENCIÓN ROBUSTA DE DUPLICADOS:
    // Verificar tanto por ID como por (senderId, content, createdAt)
    // para evitar problemas con UUIDs de cliente vs servidor
    final isDuplicate = _messages[chatId]!.any((m) {
      return m.id == message.id || 
             (m.senderId == message.senderId && 
              m.content == message.content && 
              m.createdAt == message.createdAt);
    });
    
    if (!isDuplicate) {
      _messages[chatId]!.add(message);
      print('✅ Mensaje agregado (ID: ${message.id}, duplicado: false)');
    } else {
      print('⚠️ Mensaje duplicado detectado, ignorado (ID: ${message.id})');
    }

    // Actualizar preview
    final previewIndex = _chatPreviews.indexWhere((p) => p.chat.id == chatId);
    if (previewIndex != -1) {
      final preview = _chatPreviews[previewIndex];
      _chatPreviews[previewIndex] = ChatPreview(
        chat: preview.chat,
        otherUserProfile: preview.otherUserProfile,
        lastMessage: message,
        unreadCount: !isDuplicate ? preview.unreadCount + 1 : preview.unreadCount,
      );
    }

    notifyListeners();
  }

  /// Actualizar lastReadAt
  void updateLastReadAt(String chatId, DateTime readAt) {
    _lastReadAt[chatId] = readAt;

    final previewIndex = _chatPreviews.indexWhere((p) => p.chat.id == chatId);
    if (previewIndex != -1) {
      final preview = _chatPreviews[previewIndex];
      _chatPreviews[previewIndex] = ChatPreview(
        chat: preview.chat,
        otherUserProfile: preview.otherUserProfile,
        lastMessage: preview.lastMessage,
        unreadCount: 0, // Marcar como leído
      );
    }

    notifyListeners();
  }

  /// Stream para escuchar nuevos mensajes en tiempo real
  Stream<Message> watchChatMessages(String chatId) {
    return SupabaseProvider.messagesService.watchNewMessages(chatId);
  }

  /// Limpiar datos
  void clear() {
    _chats = [];
    _chatPreviews = [];
    _messages.clear();
    _lastReadAt.clear();
    _loadingChats.clear();
    _selectedChatId = null;
    _error = null;
  }

  /// Limpiar el cache de mensajes
  void clearMessagesCache() {
    _messages.clear();
    notifyListeners();
  }
}
