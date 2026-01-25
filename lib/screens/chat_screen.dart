import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener o crear chat para este match
      final chat = await SupabaseProvider.messagesService.getOrCreateChat(widget.matchId);
      _chatId = chat.id;
      print('💬 Chat ID: $_chatId');
      
      // Cargar mensajes
      final messages = await SupabaseProvider.messagesService.getChatMessages(_chatId!);
      print('📨 Mensajes cargados: ${messages.length}');
      
      // Obtener información del otro usuario
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      print('👤 Usuario actual: $currentUserId');
      
      final match = await SupabaseProvider.databaseService.getMatch(widget.matchId);
      print('🤝 Match obtenido: ${match?.id}');
      
      if (match != null) {
        print('👥 Match userA: ${match.userA}, userB: ${match.userB}');
        final otherUserId = match.userA == currentUserId ? match.userB : match.userA;
        print('🎯 Otro usuario ID: $otherUserId');
        
        final profile = await SupabaseProvider.databaseService.getProfile(otherUserId);
        print('📸 Perfil cargado: ${profile?.fullName ?? "null"}');
        
        setState(() {
          _messages = messages;
          _otherUserProfile = profile;
          _isLoading = false;
        });
        
        _scrollToBottom();
      } else {
        print('❌ Match no encontrado');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error cargando chat: $e');
      setState(() => _isLoading = false);
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
      
      await SupabaseProvider.messagesService.sendMessage(
        chatId: _chatId!,
        senderId: currentUserId,
        content: text,
      );
      
      // Recargar mensajes
      await _loadChat();
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error enviando mensaje')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
