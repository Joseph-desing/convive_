import 'package:uuid/uuid.dart';

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
  final int bedrooms;
  final bool? _includeAlicuota;
  final String? verificationPdfUrl;
  final String status;

  bool get includeAlicuota => _includeAlicuota ?? false;

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
    this.isActive = false, // Inactivo hasta aprobación del admin
    DateTime? createdAt,
    this.updatedAt,
    this.bedrooms = 1,
    bool? includeAlicuota,
    this.verificationPdfUrl,
    String? status,
  })  : _includeAlicuota = includeAlicuota ?? false,
        status = status ?? (isActive ? 'active' : 'pending'),
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Property.fromJson(Map<String, dynamic> json) {
    final storedIsActive = json['is_active'] is bool
        ? json['is_active'] as bool
        : (json['is_active'] as bool? ?? false);
    final status =
        json['status'] as String? ?? (storedIsActive ? 'active' : 'pending');
    return Property(
      id: json['id'] as String?,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      availableFrom: json['available_from'] != null ? DateTime.parse(json['available_from']) : DateTime.now(),
      isActive: status == 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      bedrooms: json['bedrooms'] is num ? (json['bedrooms'] as num).toInt() : (int.tryParse(json['bedrooms']?.toString() ?? '') ?? 1),
      includeAlicuota: json['include_alicuota'] is bool ? (json['include_alicuota'] as bool) : null,
      verificationPdfUrl: json['verification_pdf_url'] as String?,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'available_from': availableFrom.toIso8601String(),
      'is_active': status == 'active',
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'bedrooms': bedrooms,
      'include_alicuota': _includeAlicuota ?? false,
      if (verificationPdfUrl != null) 'verification_pdf_url': verificationPdfUrl,
    };
  }

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
    int? bedrooms,
    bool? includeAlicuota,
    String? verificationPdfUrl,
    String? status,
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
      bedrooms: bedrooms ?? this.bedrooms,
      includeAlicuota: includeAlicuota ?? _includeAlicuota,
      verificationPdfUrl: verificationPdfUrl ?? this.verificationPdfUrl,
      status: status ?? this.status,
    );
  }
}
