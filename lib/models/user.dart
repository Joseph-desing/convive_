import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

enum UserRole { student, non_student, admin }

enum SubscriptionType { free, premium }

@JsonSerializable()
class User {
  final String id;
  final String email;
  final UserRole role;
  final SubscriptionType subscriptionType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    String? id,
    required this.email,
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
    UserRole? role,
    SubscriptionType? subscriptionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
