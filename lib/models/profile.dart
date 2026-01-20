import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'profile.g.dart';

enum Gender { male, female, other }

@JsonSerializable()
class Profile {
  final String id;
  final String userId;
  final String fullName;
  final DateTime? birthDate;
  final Gender? gender;
  final String? bio;
  final String? profileImageUrl;
  final bool verified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    String? id,
    required this.userId,
    required this.fullName,
    this.birthDate,
    this.gender,
    this.bio,
    this.profileImageUrl,
    this.verified = false,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? birthDate,
    Gender? gender,
    String? bio,
    String? profileImageUrl,
    bool? verified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
