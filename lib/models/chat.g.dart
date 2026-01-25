// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) => Chat(
      id: json['id'] as String?,
      matchId: json['match_id'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
