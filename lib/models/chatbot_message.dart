import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chatbot_message.g.dart';

enum MessageType {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
  @JsonValue('suggestion')
  suggestion,
}

@JsonSerializable()
class ChatbotMessage {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  
  /// Opciones clickeables para el usuario (en lugar de escribir)
  final List<String>? options;
  
  /// Para mensajes de tipo 'suggestion', contiene datos del usuario recomendado
  @JsonKey(name: 'matched_user_id')
  final String? matchedUserId;
  
  @JsonKey(name: 'matched_user_name')
  final String? matchedUserName;
  
  @JsonKey(name: 'matched_user_avatar')
  final String? matchedUserAvatar;
  
  @JsonKey(name: 'compatibility_score')
  final double? compatibilityScore;
  
  @JsonKey(name: 'property_location')
  final Map<String, dynamic>? propertyLocation;

  ChatbotMessage({
    String? id,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.options,
    this.matchedUserId,
    this.matchedUserName,
    this.matchedUserAvatar,
    this.compatibilityScore,
    this.propertyLocation,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatbotMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatbotMessageToJson(this);

  ChatbotMessage copyWith({
    String? id,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    List<String>? options,
    String? matchedUserId,
    String? matchedUserName,
    String? matchedUserAvatar,
    double? compatibilityScore,
    Map<String, dynamic>? propertyLocation,
  }) {
    return ChatbotMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      options: options ?? this.options,
      matchedUserId: matchedUserId ?? this.matchedUserId,
      matchedUserName: matchedUserName ?? this.matchedUserName,
      matchedUserAvatar: matchedUserAvatar ?? this.matchedUserAvatar,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      propertyLocation: propertyLocation ?? this.propertyLocation,
    );
  }
}
