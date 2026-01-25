import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'swipe.g.dart';

enum SwipeDirection { like, dislike }

@JsonSerializable()
class Swipe {
  final String id;
  
  @JsonKey(name: 'swiper_id')
  final String swiperId;
  
  @JsonKey(name: 'target_user_id')
  final String targetUserId;
  
  final SwipeDirection direction;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Swipe({
    String? id,
    required this.swiperId,
    required this.targetUserId,
    required this.direction,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Swipe.fromJson(Map<String, dynamic> json) => _$SwipeFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeToJson(this);

  Swipe copyWith({
    String? id,
    String? swiperId,
    String? targetUserId,
    SwipeDirection? direction,
    DateTime? createdAt,
  }) {
    return Swipe(
      id: id ?? this.id,
      swiperId: swiperId ?? this.swiperId,
      targetUserId: targetUserId ?? this.targetUserId,
      direction: direction ?? this.direction,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
