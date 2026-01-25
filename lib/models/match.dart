import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'match.g.dart';

@JsonSerializable()
class Match {
  final String id;
  
  @JsonKey(name: 'user_a_id')
  final String userA;
  
  @JsonKey(name: 'user_b_id')
  final String userB;
  
  @JsonKey(name: 'compatibility_score')
  final double compatibilityScore;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'context_type')
  final String? contextType; // 'property' o 'roommate_search'

  @JsonKey(name: 'context_id')
  final String? contextId; // ID de la propiedad o búsqueda

  Match({
    String? id,
    required this.userA,
    required this.userB,
    required this.compatibilityScore,
    DateTime? createdAt,
    this.updatedAt,
    this.contextType,
    this.contextId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  Map<String, dynamic> toJson() => _$MatchToJson(this);

  Match copyWith({
    String? id,
    String? userA,
    String? userB,
    double? compatibilityScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contextType,
    String? contextId,
  }) {
    return Match(
      id: id ?? this.id,
      userA: userA ?? this.userA,
      userB: userB ?? this.userB,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
    );
  }
}
