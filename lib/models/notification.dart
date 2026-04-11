class Notification {
  final String id;
  final String? publicationTitle;
  final String type; // 'match', 'like', 'system'
  final DateTime createdAt;
  final bool isRead;
  final String? senderUserId;
  final String? senderName;
  final String? publicationId;
  final String? publicationType; // 'roommate' o 'departamento'

  Notification({
    required this.id,
    this.publicationTitle,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.senderUserId,
    this.senderName,
    this.publicationId,
    this.publicationType,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      publicationTitle: json['publication_title'] as String?,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['read'] as bool? ?? false,
      senderUserId: json['sender_user_id'] as String?,
      senderName: json['sender_name'] as String?,
      publicationId: json['publication_id'] as String?,
      publicationType: json['publication_type'] as String?,
    );
  }

  // Construir mensaje a partir del tipo
  String get message {
    switch (type) {
      case 'match':
        return '${senderName ?? 'Alguien'} te dió match ❤️';
      case 'like':
        if (publicationType == 'roommate') {
          return '${senderName ?? 'Alguien'} dio ❤️ a tu perfil';
        } else if (publicationType == 'departamento') {
          return '${senderName ?? 'Alguien'} dio ❤️ a: ${publicationTitle ?? 'tu departamento'}';
        }
        return '${senderName ?? 'Alguien'} dio ❤️';
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
        return '${senderName ?? 'Nuevo match'}';
      case 'like':
        return '${senderName ?? 'Nuevo like'}';
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
    'sender_name': senderName,
    'publication_id': publicationId,
    'publication_type': publicationType,
  };

  Notification copyWith({
    String? id,
    String? publicationTitle,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? senderUserId,
    String? senderName,
    String? publicationId,
    String? publicationType,
  }) {
    return Notification(
      id: id ?? this.id,
      publicationTitle: publicationTitle ?? this.publicationTitle,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      senderUserId: senderUserId ?? this.senderUserId,
      senderName: senderName ?? this.senderName,
      publicationId: publicationId ?? this.publicationId,
      publicationType: publicationType ?? this.publicationType,
    );
  }
}
