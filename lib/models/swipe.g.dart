// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Swipe _$SwipeFromJson(Map<String, dynamic> json) => Swipe(
      id: json['id'] as String?,
      swiperId: json['swiperId'] as String,
      targetUserId: json['targetUserId'] as String,
      direction: $enumDecode(_$SwipeDirectionEnumMap, json['direction']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SwipeToJson(Swipe instance) => <String, dynamic>{
      'id': instance.id,
      'swiperId': instance.swiperId,
      'targetUserId': instance.targetUserId,
      'direction': _$SwipeDirectionEnumMap[instance.direction]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$SwipeDirectionEnumMap = {
  SwipeDirection.like: 'like',
  SwipeDirection.dislike: 'dislike',
};
