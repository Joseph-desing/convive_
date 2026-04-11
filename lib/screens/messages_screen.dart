import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';
import '../config/supabase_provider.dart';
import '../models/match.dart' as models;
import '../models/profile.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
    // Mapa local para guardar el lastReadAt actualizado tras leer un chat
    Map<String, DateTime> _localLastReadAt = <String, DateTime>{};
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    messagesProvider.clearMessagesCache();
    if (authProvider.currentUser != null) {
      await messagesProvider.loadUserChats(authProvider.currentUser!.id);
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
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
                    if (messagesProvider.chats.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildChatList(messagesProvider.chats);
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

  Widget _buildChatList(List<Chat> chats) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    final messagesProvider = context.read<MessagesProvider>();
    // Filtrar chats donde hay al menos un mensaje (conversaciones activas)
    final filteredChats = chats.where((chat) {
      final messages = messagesProvider.getMessagesForChat(chat.id);
      return messages.isNotEmpty; // Mostrar todos los chats con al menos un mensaje
    }).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return _ChatTile(
          chat: chat,
          onTap: () => _showChatDetail(chat),
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
    final currentUserId = authProvider.currentUser?.id;
    final now = DateTime.now().toUtc();
    // Guardar localmente el lastReadAt actualizado
    if (currentUserId != null) {
      _localLastReadAt[chat.id] = now;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(chat: chat),
      ),
    );
    // Esperar a que Supabase refleje el nuevo lastReadAt antes de recargar la lista
    if (currentUserId != null) {
      int retries = 0;
      const int maxRetries = 5;
      const Duration retryDelay = Duration(milliseconds: 300);
      bool actualizado = false;
      while (retries < maxRetries && !actualizado) {
        await Future.delayed(retryDelay);
        final remoteLastReadAt = await SupabaseProvider.messagesService.getLastReadAt(chat.id, currentUserId);
        if (remoteLastReadAt != null && !remoteLastReadAt.isBefore(now)) {
          actualizado = true;
        } else {
          retries++;
        }
      }
      if (!actualizado) {
        print('ADVERTENCIA: lastReadAt no se actualizó en Supabase tras $maxRetries reintentos.');
      }
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadChats();
    });
  }
}

/// Widget para mostrar un chat en la lista
class _ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    if (currentUserId == null) {
      return const ListTile(title: Text('Cargando...'));
    }

    // Acceso al mapa local de lastReadAt
    final messagesScreenState = context.findAncestorStateOfType<_MessagesScreenState>();
    final Map<String, DateTime> localMap = (messagesScreenState?._localLastReadAt) ?? <String, DateTime>{};
    return FutureBuilder<models.Match?>(
      future: SupabaseProvider.databaseService.getMatch(chat.matchId),
      builder: (context, matchSnapshot) {
        if (!matchSnapshot.hasData || matchSnapshot.data == null) {
          return const ListTile(title: Text('Cargando...'));
        }
        final match = matchSnapshot.data!;
        final otherUserId = match.userA == currentUserId ? match.userB : match.userA;
        return FutureBuilder<Profile?>(
          future: SupabaseProvider.databaseService.getProfile(otherUserId),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            final imageUrl = profile?.profileImageUrl;
            final name = profile?.fullName ?? 'Usuario';
            // Usar el lastReadAt local si existe, si no, consultar Supabase
            DateTime? localLastReadAt;
            if (localMap.containsKey(chat.id)) {
              localLastReadAt = localMap[chat.id];
            }
            return FutureBuilder<DateTime?>(
              key: ValueKey('lastReadAt_${chat.id}_$currentUserId'),
              future: localLastReadAt != null
                  ? Future.value(localLastReadAt)
                  : SupabaseProvider.messagesService.getLastReadAt(chat.id, currentUserId),
              builder: (context, readSnapshot) {
                final lastReadAt = readSnapshot.data;
                return FutureBuilder<List<Message>>(
                  future: SupabaseProvider.messagesService.getChatMessages(chat.id, limit: 50),
                  builder: (context, messagesSnapshot) {
                    final messages = messagesSnapshot.data ?? [];
                    // Último mensaje recibido de otro usuario
                    final lastReceived = messages.where((m) => m.senderId == otherUserId).toList().isNotEmpty
                        ? messages.where((m) => m.senderId == otherUserId).last
                        : null;
                    final int msgCount = messages
                        .where((m) => m.senderId == otherUserId && (lastReadAt == null || m.createdAt.isAfter(lastReadAt)))
                        .length;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                        ),
                        child: imageUrl == null
                            ? const Center(child: Icon(Icons.person, color: Colors.white, size: 28))
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: lastReceived != null
                          ? Text(
                              lastReceived.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            )
                          : Text(
                              'Match creado ${DateFormat('dd MMM').format(chat.createdAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (msgCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$msgCount',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.primary),
                        ],
                      ),
                      onTap: onTap,
                    );
                  },
                );
              },
            );
          },
        );
      },
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

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markChatAsRead();
      _loadMessages();
      _loadOtherUserName();
    });
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
      // Aumentar delay para asegurar sincronización con Supabase
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messagesProvider = context.read<MessagesProvider>();
    await messagesProvider.loadChatMessages(widget.chat.id);
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
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

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
