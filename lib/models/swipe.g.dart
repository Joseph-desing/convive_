// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Swipe _$SwipeFromJson(Map<String, dynamic> json) => Swipe(
      id: json['id'] as String?,
      swiperId: json['swiper_id'] as String,
      targetUserId: json['target_user_id'] as String,
      direction: $enumDecode(_$SwipeDirectionEnumMap, json['direction']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SwipeToJson(Swipe instance) => <String, dynamic>{
      'id': instance.id,
      'swiper_id': instance.swiperId,
      'target_user_id': instance.targetUserId,
      'direction': _$SwipeDirectionEnumMap[instance.direction]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$SwipeDirectionEnumMap = {
  SwipeDirection.like: 'like',
  SwipeDirection.dislike: 'dislike',
};
