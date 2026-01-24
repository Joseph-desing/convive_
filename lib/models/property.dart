import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'property.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime availableFrom;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Property({
    String? id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.availableFrom,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);

  Property copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    double? price,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? availableFrom,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Property(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      availableFrom: availableFrom ?? this.availableFrom,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
