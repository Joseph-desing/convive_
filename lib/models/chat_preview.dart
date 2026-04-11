import 'chat.dart';
import 'profile.dart';
import 'message.dart';

/// Datos optimizados para mostrar en la lista de chats
/// Evita FutureBuilders anidados y múltiples queries
class ChatPreview {
  final Chat chat;
  final Profile otherUserProfile;
  final Message? lastMessage;
  final int unreadCount;

  ChatPreview({
    required this.chat,
    required this.otherUserProfile,
    required this.lastMessage,
    required this.unreadCount,
  });

  String get otherUserName => otherUserProfile.fullName ?? 'Usuario';
  String? get otherUserImage => otherUserProfile.profileImageUrl;
}
