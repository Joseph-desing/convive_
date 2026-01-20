// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyImage _$PropertyImageFromJson(Map<String, dynamic> json) =>
    PropertyImage(
      id: json['id'] as String?,
      propertyId: json['propertyId'] as String,
      imageUrl: json['imageUrl'] as String,
      validated: json['validated'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PropertyImageToJson(PropertyImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'propertyId': instance.propertyId,
      'imageUrl': instance.imageUrl,
      'validated': instance.validated,
      'createdAt': instance.createdAt.toIso8601String(),
    };
