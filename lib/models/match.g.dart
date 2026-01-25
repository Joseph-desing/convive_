// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Match _$MatchFromJson(Map<String, dynamic> json) => Match(
      id: json['id'] as String?,
      userA: json['user_a_id'] as String,
      userB: json['user_b_id'] as String,
      compatibilityScore: (json['compatibility_score'] as num).toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      contextType: json['context_type'] as String?,
      contextId: json['context_id'] as String?,
    );

Map<String, dynamic> _$MatchToJson(Match instance) => <String, dynamic>{
      'id': instance.id,
      'user_a_id': instance.userA,
      'user_b_id': instance.userB,
      'compatibility_score': instance.compatibilityScore,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'context_type': instance.contextType,
      'context_id': instance.contextId,
    };
