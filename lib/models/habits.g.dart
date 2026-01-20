// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habits _$HabitsFromJson(Map<String, dynamic> json) => Habits(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      sleepStart: (json['sleepStart'] as num?)?.toInt() ?? 23,
      sleepEnd: (json['sleepEnd'] as num?)?.toInt() ?? 7,
      cleanlinessLevel: (json['cleanlinessLevel'] as num?)?.toInt() ?? 5,
      noiseTolerance: (json['noiseTolerance'] as num?)?.toInt() ?? 5,
      partyFrequency: (json['partyFrequency'] as num?)?.toInt() ?? 3,
      guestsTolerance: (json['guestsTolerance'] as num?)?.toInt() ?? 5,
      pets: json['pets'] as bool? ?? false,
      petTolerance: (json['petTolerance'] as num?)?.toInt() ?? 5,
      alcoholFrequency: (json['alcoholFrequency'] as num?)?.toInt() ?? 3,
      workMode: $enumDecodeNullable(_$WorkModeEnumMap, json['workMode']) ??
          WorkMode.hybrid,
      timeAtHome: (json['timeAtHome'] as num?)?.toInt() ?? 50,
      communicationStyle: (json['communicationStyle'] as num?)?.toInt() ?? 5,
      conflictManagement: (json['conflictManagement'] as num?)?.toInt() ?? 5,
      responsibilityLevel: (json['responsibilityLevel'] as num?)?.toInt() ?? 5,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$HabitsToJson(Habits instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'sleepStart': instance.sleepStart,
      'sleepEnd': instance.sleepEnd,
      'cleanlinessLevel': instance.cleanlinessLevel,
      'noiseTolerance': instance.noiseTolerance,
      'partyFrequency': instance.partyFrequency,
      'guestsTolerance': instance.guestsTolerance,
      'pets': instance.pets,
      'petTolerance': instance.petTolerance,
      'alcoholFrequency': instance.alcoholFrequency,
      'workMode': _$WorkModeEnumMap[instance.workMode]!,
      'timeAtHome': instance.timeAtHome,
      'communicationStyle': instance.communicationStyle,
      'conflictManagement': instance.conflictManagement,
      'responsibilityLevel': instance.responsibilityLevel,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$WorkModeEnumMap = {
  WorkMode.remote: 'remote',
  WorkMode.office: 'office',
  WorkMode.hybrid: 'hybrid',
};
