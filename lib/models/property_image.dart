import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'property_image.g.dart';

@JsonSerializable()
class PropertyImage {
  final String id;
  final String propertyId;
  final String imageUrl;
  final bool validated;
  final DateTime createdAt;

  PropertyImage({
    String? id,
    required this.propertyId,
    required this.imageUrl,
    this.validated = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory PropertyImage.fromJson(Map<String, dynamic> json) =>
      _$PropertyImageFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyImageToJson(this);

  PropertyImage copyWith({
    String? id,
    String? propertyId,
    String? imageUrl,
    bool? validated,
    DateTime? createdAt,
  }) {
    return PropertyImage(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      imageUrl: imageUrl ?? this.imageUrl,
      validated: validated ?? this.validated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
