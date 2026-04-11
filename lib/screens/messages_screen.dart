import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat.dart';
import '../models/chat_preview.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';
import '../config/supabase_provider.dart';
import '../models/profile.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    
    if (authProvider.currentUser != null) {
      // ✅ Nueva forma: cargar previews en lugar de hacer queries en UI
      await messagesProvider.loadChatPreviews(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<MessagesProvider>(
                  builder: (context, messagesProvider, _) {
                    if (messagesProvider.chatPreviews.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildChatList(messagesProvider.chatPreviews);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mensajes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadChats,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatPreview> previews) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: previews.length,
      itemBuilder: (context, index) {
        final preview = previews[index];
        return _ChatTile(
          preview: preview,
          onTap: () => _showChatDetail(preview.chat),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Sin mensajes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Empieza a conectar con tus matches',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatDetail(Chat chat) async {
    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final currentUserId = authProvider.currentUser?.id;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chat: chat),
      ),
    );

    // ✅ Recargar previews al volver (en lugar de hacer reintentos)
    if (currentUserId != null && mounted) {
      await messagesProvider.loadChatPreviews(currentUserId);
    }
  }
}

/// Widget para mostrar un chat en la lista
/// ✅ OPTIMIZADO: Sin FutureBuilders, sin queries
class _ChatTile extends StatelessWidget {
  final ChatPreview preview;
  final VoidCallback onTap;

  const _ChatTile({
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          image: preview.otherUserImage != null
              ? DecorationImage(image: NetworkImage(preview.otherUserImage!), fit: BoxFit.cover)
              : null,
        ),
        child: preview.otherUserImage == null
            ? const Center(child: Icon(Icons.person, color: Colors.white, size: 28))
            : null,
      ),
      title: Text(
        preview.otherUserName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: preview.lastMessage != null
          ? Text(
              preview.lastMessage!.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            )
          : Text(
              'Match creado ${DateFormat('dd MMM').format(preview.chat.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${preview.unreadCount}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Pantalla de detalle de chat
class ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const ChatDetailScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  String? _otherUserName;
  String? _otherUserProfileImage;
  late Stream<Message> _messageStream;
  StreamSubscription<Message>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    
    // ✅ PROBLEMA 2 ARREGLADO: Setup listener PRIMERO (antes de cargar mensajes)
    _setupRealtimeListener();
    
    // Cargar datos en paralelo sin esperar al listener
    _markChatAsRead();
    _loadMessages();
    _loadOtherUserName();
  }

  /// ✅ Configurar listener para mensajes en tiempo real
  void _setupRealtimeListener() {
    final provider = context.read<MessagesProvider>();
    print('🔄 Iniciando listener en tiempo real para chat: ${widget.chat.id}');
    
    _messageStream = provider.watchChatMessages(widget.chat.id);
    
    _messageSubscription = _messageStream.listen(
      (incomingMessage) {
        if (mounted) {
          print('✅ Mensaje recibido: ${incomingMessage.content}');
          
          // ✅ Agregar mensaje sin recargar toda la lista
          provider.addIncomingMessage(widget.chat.id, incomingMessage);
          
          // ✅ Auto-scroll al nuevo mensaje
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      },
      onError: (error) {
        print('❌ Error en listener de tiempo real: $error');
        // Intentar reconectar
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _setupRealtimeListener();
          }
        });
      },
      cancelOnError: false, // No cancelar por errores, reintentar
    );
  }

  Future<void> _loadOtherUserName() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.id;
      
      if (currentUserId == null) return;
      
      // Obtener el match para saber quién es el otro usuario
      final match = await SupabaseProvider.databaseService.getMatch(widget.chat.matchId);
      if (match == null) return;
      
      final otherUserId = match.userA == currentUserId ? match.userB : match.userA;
      
      // Obtener el perfil del otro usuario
      final profile = await SupabaseProvider.databaseService.getProfile(otherUserId);
      
      if (mounted) {
        setState(() {
          _otherUserName = profile?.fullName ?? 'Usuario';
          _otherUserProfileImage = profile?.profileImageUrl;
        });
      }
    } catch (e) {
      print('Error cargando nombre del usuario: $e');
    }
  }

  Future<void> _markChatAsRead() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    if (currentUserId != null) {
      await SupabaseProvider.messagesService.updateLastReadAt(widget.chat.id, currentUserId);
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messagesProvider = context.read<MessagesProvider>();
    
    print('📥 Cargando mensajes del chat: ${widget.chat.id}');
    await messagesProvider.loadChatMessages(widget.chat.id);
    
    // Scroll al final después de cargar mensajes
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        print('⬇️ Scroll al final de mensajes');
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (authProvider.currentUser == null) return;

    try {
      await messagesProvider.sendMessage(
        chatId: widget.chat.id,
        senderId: authProvider.currentUser!.id,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
      
      // ✅ Auto-scroll después de enviar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: _otherUserProfileImage != null
                  ? NetworkImage(_otherUserProfileImage!)
                  : null,
              child: _otherUserProfileImage == null
                  ? Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              _otherUserName ?? 'Cargando...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, messagesProvider, _) {
                final messages = messagesProvider.getMessagesForChat(widget.chat.id);

                if (messagesProvider.isChatLoading(widget.chat.id)) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Sin mensajes aún',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                // ✅ Los mensajes ya vienen ordenados del provider
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(
                      message: messages[index],
                      isOwn: messages[index].senderId ==
                          context.read<AuthProvider>().currentUser?.id,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
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
}

/// Widget para mostrar un mensaje individual
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOwn ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isOwn ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                color: isOwn ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
