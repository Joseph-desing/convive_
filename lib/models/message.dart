import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  @JsonKey(name: 'chat_id')
  final String chatId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Message({
    String? id,
    required this.chatId,
    required this.senderId,
    required this.content,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
