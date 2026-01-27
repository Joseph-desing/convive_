class RoommateSearch {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final double budget;
  final double? latitude;
  final double? longitude;
  final String? genderPreference;
  final String address;
  final List<String> habitsPreferences;
  final List<String> imageUrls;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoommateSearch({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.budget,
    this.latitude,
    this.longitude,
    this.genderPreference,
    required this.address,
    required this.habitsPreferences,
    required this.imageUrls,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'budget': budget,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'gender_preference': genderPreference,
      'address': address,
      'habits_preferences': habitsPreferences,
      'image_urls': imageUrls,
      'status': status,
    };
  }

  factory RoommateSearch.fromJson(Map<String, dynamic> json) {
    return RoommateSearch(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num).toDouble(),
      latitude: json['latitude'] != null ? (json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude'].toString())) : null,
      genderPreference: json['gender_preference'] as String?,
      address: json['address'] as String,
      habitsPreferences: List<String>.from(json['habits_preferences'] as List? ?? []),
      imageUrls: List<String>.from(json['image_urls'] as List? ?? []),
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
