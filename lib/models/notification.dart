class Notification {
  final String id;
  final String? title;
  final String message;
  final String type; // 'match', 'message', 'like', 'system'
  final DateTime createdAt;
  final bool isRead;
  final String? senderUserId;
  final String? publicationId;

  Notification({
    required this.id,
    this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.senderUserId,
    this.publicationId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      title: json['publication_title'] as String?,
      message: _buildMessageFromType(json),
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read'] as bool? ?? false,
      senderUserId: json['sender_user_id'] as String?,
      publicationId: json['publication_id'] as String?,
    );
  }

  static String _buildMessageFromType(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'like':
        return 'Alguien te dio like';
      case 'message':
        return 'Nuevo mensaje';
      case 'match':
        return '¡Nuevo match!';
      default:
        return json['publication_title'] as String? ?? 'Nueva notificación';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'publication_title': title,
    'type': type,
    'created_at': createdAt.toIso8601String(),
    'read': isRead,
    'sender_user_id': senderUserId,
    'publication_id': publicationId,
  };
}
