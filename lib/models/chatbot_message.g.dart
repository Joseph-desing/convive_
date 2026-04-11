// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatbot_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatbotMessage _$ChatbotMessageFromJson(Map<String, dynamic> json) =>
    ChatbotMessage(
      id: json['id'] as String?,
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      content: json['content'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      matchedUserId: json['matched_user_id'] as String?,
      matchedUserName: json['matched_user_name'] as String?,
      matchedUserAvatar: json['matched_user_avatar'] as String?,
      compatibilityScore: (json['compatibility_score'] as num?)?.toDouble(),
      propertyLocation: json['property_location'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChatbotMessageToJson(ChatbotMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'options': instance.options,
      'matched_user_id': instance.matchedUserId,
      'matched_user_name': instance.matchedUserName,
      'matched_user_avatar': instance.matchedUserAvatar,
      'compatibility_score': instance.compatibilityScore,
      'property_location': instance.propertyLocation,
    };

const _$MessageTypeEnumMap = {
  MessageType.user: 'user',
  MessageType.assistant: 'assistant',
  MessageType.suggestion: 'suggestion',
};
