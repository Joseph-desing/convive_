import 'package:flutter/material.dart';
import 'dart:async';
import '../config/supabase_provider.dart';
import '../utils/colors.dart';
import '../models/message.dart';
import '../models/profile.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  
  const ChatScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  Profile? _otherUserProfile;
  bool _isLoading = true;
  String? _chatId;
  StreamSubscription<Message>? _messagesSubscription;
  Timer? _pollingTimer;  // ✅ NUEVO: Fallback polling timer

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Obtener o crear chat para este match
      final chat = await SupabaseProvider.messagesService.getOrCreateChat(widget.matchId);
      _chatId = chat.id;
      print('💬 Chat ID: $_chatId');

      // Obtener información del usuario actual
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      // Actualizar lastReadAt para este usuario y chat (apenas se abre el chat)
      if (_chatId != null && currentUserId != null) {
        await SupabaseProvider.messagesService.updateLastReadAt(_chatId!, currentUserId);
      }

      // Cargar mensajes
      final messages = await SupabaseProvider.messagesService.getChatMessages(_chatId!);
      print('📨 Mensajes cargados: ${messages.length}');

      final match = await SupabaseProvider.databaseService.getMatch(widget.matchId);
      print('🤝 Match obtenido: ${match?.id}');

      if (match != null) {
        print('👥 Match userA: ${match.userA}, userB: ${match.userB}');
        final otherUserId = match.userA == currentUserId ? match.userB : match.userA;
        print('🎯 Otro usuario ID: $otherUserId');

        final profile = await SupabaseProvider.databaseService.getProfile(otherUserId);
        print('📸 Perfil cargado: ${profile?.fullName ?? "null"}');

        if (mounted) {
          setState(() {
            _messages = messages;
            _otherUserProfile = profile;
            _isLoading = false;
          });
          // Esperar al próximo frame para hacer scroll
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // ✅ NUEVO: Suscribirse a nuevos mensajes en realtime
          _subscribeToNewMessages();
        }
      } else {
        print('❌ Match no encontrado');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error cargando chat: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ NUEVO: Escuchar nuevos mensajes en tiempo real
  void _subscribeToNewMessages() {
    if (_chatId == null) return;
    
    print('🔔 Iniciando escucha de realtime para chat: $_chatId');
    
    // ✅ IMPORTANTE: Limpiar TODO antes de crear nuevas suscripciones
    _cleanupListeners();
    
    print('⏱️ POLLING FALLBACK INICIADO - verificando mensajes cada 3 segundos');
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _checkNewMessagesWithPolling();
      }
    });

    // Intentar realtime EN PARALELO
    _messagesSubscription = SupabaseProvider.messagesService
        .watchNewMessages(_chatId!)
        .listen(
          (newMessage) {
            print('📨 ✅ Nuevo mensaje recibido en REALTIME: ${newMessage.id}');
            
            if (mounted) {
              setState(() {
                // Evitar duplicados
                if (!_messages.any((m) => m.id == newMessage.id)) {
                  _messages.add(newMessage);
                  print('📨 Mensaje agregado a lista. Total: ${_messages.length}');
                }
              });
              
              // Scroll automático al nuevo mensaje
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          onError: (error) {
            print('❌ Error en stream realtime: $error');
          },
          cancelOnError: false, // ✅ NUEVO: No cancelar el stream si hay error
        );
  }

  /// ✅ NUEVO: Limpiar todos los listeners activos
  void _cleanupListeners() {
    try {
      if (_messagesSubscription != null) {
        print('🧹 Cancelando suscripción realtime anterior');
        _messagesSubscription?.cancel();
        _messagesSubscription = null;
      }
      
      if (_pollingTimer != null) {
        print('🧹 Cancelando timer de polling anterior');
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }
    } catch (e) {
      print('⚠️ Error limpiando listeners: $e');
    }
  }

  /// ✅ NUEVO: Verificar nuevos mensajes usando polling
  Future<void> _checkNewMessagesWithPolling() async {
    if (_chatId == null) return;
    
    try {
      final newMessages = await SupabaseProvider.messagesService.getChatMessages(_chatId!);
      
      if (mounted) {
        int newCount = 0;
        setState(() {
          // Agregar solo mensajes nuevos (que no existan en la lista)
          for (final msg in newMessages) {
            if (!_messages.any((m) => m.id == msg.id)) {
              print('📨 ⏱️ POLLING: Nuevo mensaje detectado: ${msg.id} - ${msg.content}');
              _messages.add(msg);
              newCount++;
            }
          }
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
        
        if (newCount > 0) {
          print('📨 ⏱️ Se encontraron $newCount mensajes nuevos por polling');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('⚠️ Error en polling: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    _messageController.clear();

    try {
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Crear mensaje localmente para feedback inmediato
      final localMessage = Message(
        chatId: _chatId!,
        senderId: currentUserId,
        content: text,
      );

      // Agregar a la lista local inmediatamente (feedback instantáneo)
      if (mounted) {
        setState(() {
          _messages.add(localMessage);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // Enviar al servidor (el realtime traerá la versión confirmada)
      await SupabaseProvider.messagesService.sendMessage(
        chatId: _chatId!,
        senderId: currentUserId,
        content: text,
      );
      
      print('✅ Mensaje enviado al servidor');
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error enviando mensaje')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Actualizar lastReadAt justo antes de salir
        final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
        if (_chatId != null && currentUserId != null) {
          await SupabaseProvider.messagesService.updateLastReadAt(_chatId!, currentUserId);
          await Future.delayed(const Duration(milliseconds: 300));
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
              if (_chatId != null && currentUserId != null) {
                await SupabaseProvider.messagesService.updateLastReadAt(_chatId!, currentUserId);
                await Future.delayed(const Duration(milliseconds: 300));
              }
              Navigator.pop(context);
            },
          ),
          title: _isLoading
              ? const Text('Cargando...')
              : Row(
                  children: [
                    if (_otherUserProfile != null)
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          _otherUserProfile!.profileImageUrl ??
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_otherUserProfile!.fullName)}&background=9C27B0&color=fff',
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      _otherUserProfile?.fullName ?? 'Usuario',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(),
                  ),
                  _buildMessageInput(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Es un Match!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Envía un mensaje para romper el hielo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == currentUserId;
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: isMe ? AppColors.primaryGradient : null,
              color: isMe ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}min';
    } else {
      return 'Ahora';
    }
  }

  @override
  void dispose() {
    print('🛑 Limpiando ChatScreen - disponiéndose');
    
    _messageController.dispose();
    _scrollController.dispose();
    
    // ✅ MEJORADO: Limpieza exhaustiva de listeners
    _cleanupListeners();
    
    super.dispose();
  }
}
