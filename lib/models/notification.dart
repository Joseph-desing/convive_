class Notification {
  final String id;
  final String? publicationTitle;
  final String type; // 'match', 'like', 'system'
  final DateTime createdAt;
  final bool isRead;
  final String? senderUserId;
  final String? publicationId;

  Notification({
    required this.id,
    this.publicationTitle,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.senderUserId,
    this.publicationId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      publicationTitle: json['publication_title'] as String?,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read'] as bool? ?? false,
      senderUserId: json['sender_user_id'] as String?,
      publicationId: json['publication_id'] as String?,
    );
  }

  // Construir mensaje a partir del tipo
  String get message {
    switch (type) {
      case 'match':
        return '¡Nuevo match!';
      case 'like':
        return 'Alguien te dio like';
      case 'system':
        return publicationTitle ?? 'Notificación del sistema';
      default:
        return publicationTitle ?? 'Nueva notificación';
    }
  }

  // Construir título a partir del tipo
  String get title {
    switch (type) {
      case 'match':
        return '¡Nuevo match!';
      case 'like':
        return 'Nuevo like';
      case 'system':
        return 'Notificación';
      default:
        return publicationTitle ?? 'Notificación';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'publication_title': publicationTitle,
    'type': type,
    'created_at': createdAt.toIso8601String(),
    'read': isRead,
    'sender_user_id': senderUserId,
    'publication_id': publicationId,
  };
}
