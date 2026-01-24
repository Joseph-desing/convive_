// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String?,
      email: json['email'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role'],
          unknownValue: UserRole.student),
      subscriptionType: $enumDecodeNullable(
              _$SubscriptionTypeEnumMap, json['subscription_type'],
              unknownValue: SubscriptionType.free) ??
          SubscriptionType.free,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'role': _$UserRoleEnumMap[instance.role]!,
      'subscription_type':
          _$SubscriptionTypeEnumMap[instance.subscriptionType]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.non_student: 'non_student',
  UserRole.admin: 'admin',
};

const _$SubscriptionTypeEnumMap = {
  SubscriptionType.free: 'free',
  SubscriptionType.premium: 'premium',
};
