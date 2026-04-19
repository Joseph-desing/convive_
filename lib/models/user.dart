import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

enum UserRole { 
  @JsonValue('student') student, 
  @JsonValue('non_student') non_student, 
  @JsonValue('admin') admin 
}

enum SubscriptionType { 
  @JsonValue('free') free, 
  @JsonValue('premium') premium 
}

@JsonSerializable()
class User {
  @JsonKey(name: 'id')
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(unknownEnumValue: UserRole.student)
  final UserRole role;
  @JsonKey(name: 'subscription_type', unknownEnumValue: SubscriptionType.free)
  final SubscriptionType subscriptionType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  User({
    String? id,
    required this.email,
    this.fullName,
    required this.role,
    this.subscriptionType = SubscriptionType.free,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    SubscriptionType? subscriptionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}