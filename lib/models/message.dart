import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

enum MessageStatus {
  pending('pending'),    // Siendo enviado
  sent('sent'),          // Enviado al servidor
  delivered('delivered'), // Recibido por receptor
  failed('failed');      // Error al enviar

  final String value;
  const MessageStatus(this.value);

  factory MessageStatus.fromString(String? value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

@JsonSerializable()
class Message {
  final String id;
  @JsonKey(name: 'chat_id')
  final String chatId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(defaultValue: 'sent')
  final String status; // pending, sent, delivered, failed

  Message({
    String? id,
    required this.chatId,
    required this.senderId,
    required this.content,
    DateTime? createdAt,
    this.updatedAt,
    this.status = 'sent',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return _$MessageFromJson(json);
    } catch (e) {
      // Fallback: constructor manual si el deserializador falla
      print('⚠️ Fallback en Message.fromJson: $e');
      
      DateTime parseDateTime(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (_) {
            return DateTime.now();
          }
        }
        return DateTime.now();
      }

      return Message(
        id: json['id'] as String? ?? const Uuid().v4(),
        chatId: json['chat_id'] as String? ?? '',
        senderId: json['sender_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: parseDateTime(json['created_at']),
        updatedAt: json['updated_at'] != null ? parseDateTime(json['updated_at']) : null,
        status: json['status'] as String? ?? 'sent',
      );
    }
  }

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  // ✅ Getters útiles para UI
  bool get isPending => status == MessageStatus.pending.value;
  bool get isFailed => status == MessageStatus.failed.value;
  bool get isDelivered => status == MessageStatus.delivered.value;
}
