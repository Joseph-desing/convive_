import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';

/// Provider para gestionar mensajes y chats
class MessagesProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  Map<String, List<Message>> _messages = {}; // chatId -> messages
  Map<String, bool> _loadingChats = {}; // chatId -> isLoading
  String? _error;
  String? _selectedChatId;

  List<Chat> get chats => _chats;
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
      _messages[chatId] = messages.reversed.toList(); // Invertir para mostrar arriba los nuevos
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

  /// Stream para escuchar nuevos mensajes
  Stream<Message> watchChatMessages(String chatId) {
    return SupabaseProvider.messagesService.watchNewMessages(chatId);
  }

  /// Limpiar datos
  void clear() {
    _chats = [];
    _messages.clear();
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
