// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habits _$HabitsFromJson(Map<String, dynamic> json) => Habits(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      sleepStart: (json['sleep_start'] as num?)?.toInt() ?? 23,
      sleepEnd: (json['sleep_end'] as num?)?.toInt() ?? 7,
      cleanlinessLevel: (json['cleanliness_level'] as num?)?.toInt() ?? 5,
      noiseTolerance: (json['noise_tolerance'] as num?)?.toInt() ?? 5,
      partyFrequency: (json['party_frequency'] as num?)?.toInt() ?? 3,
      guestsTolerance: (json['guests_tolerance'] as num?)?.toInt() ?? 5,
      pets: json['pets'] as bool? ?? false,
      petTolerance: (json['pet_tolerance'] as num?)?.toInt() ?? 5,
      alcoholFrequency: (json['alcohol_frequency'] as num?)?.toInt() ?? 3,
      workMode: $enumDecodeNullable(_$WorkModeEnumMap, json['work_mode']) ??
          WorkMode.hybrid,
      timeAtHome: (json['time_at_home'] as num?)?.toInt() ?? 50,
      communicationStyle: (json['communication_style'] as num?)?.toInt() ?? 5,
      conflictManagement: (json['conflict_management'] as num?)?.toInt() ?? 5,
      responsibilityLevel: (json['responsibility_level'] as num?)?.toInt() ?? 5,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$HabitsToJson(Habits instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'sleep_start': instance.sleepStart,
      'sleep_end': instance.sleepEnd,
      'cleanliness_level': instance.cleanlinessLevel,
      'noise_tolerance': instance.noiseTolerance,
      'party_frequency': instance.partyFrequency,
      'guests_tolerance': instance.guestsTolerance,
      'pets': instance.pets,
      'pet_tolerance': instance.petTolerance,
      'alcohol_frequency': instance.alcoholFrequency,
      'work_mode': _$WorkModeEnumMap[instance.workMode]!,
      'time_at_home': instance.timeAtHome,
      'communication_style': instance.communicationStyle,
      'conflict_management': instance.conflictManagement,
      'responsibility_level': instance.responsibilityLevel,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$WorkModeEnumMap = {
  WorkMode.remote: 'remote',
  WorkMode.office: 'office',
  WorkMode.hybrid: 'hybrid',
};
