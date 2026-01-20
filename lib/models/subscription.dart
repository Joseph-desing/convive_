import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'subscription.g.dart';

enum SubscriptionStatus { active, expired, cancelled }

@JsonSerializable()
class Subscription {
  final String id;
  final String userId;
  final double price;
  final bool isStudent;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Subscription({
    String? id,
    required this.userId,
    required this.price,
    required this.isStudent,
    required this.startDate,
    required this.endDate,
    required this.status,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  Subscription copyWith({
    String? id,
    String? userId,
    double? price,
    bool? isStudent,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      price: price ?? this.price,
      isStudent: isStudent ?? this.isStudent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
