import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat.g.dart';

@JsonSerializable()
class Chat {
  final String id;
  
  @JsonKey(name: 'match_id')
  final String matchId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Chat({
    String? id,
    required this.matchId,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);

  Map<String, dynamic> toJson() => _$ChatToJson(this);

  Chat copyWith({
    String? id,
    String? matchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
