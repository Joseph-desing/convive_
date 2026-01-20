import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'habits.g.dart';

enum WorkMode { remote, office, hybrid }

@JsonSerializable()
class Habits {
  final String id;
  final String userId;
  final int sleepStart; // 0-23 (hora)
  final int sleepEnd; // 0-23 (hora)
  final int cleanlinessLevel; // 1-10
  final int noiseTolerance; // 1-10
  final int partyFrequency; // 1-10
  final int guestsTolerance; // 1-10
  final bool pets;
  final int petTolerance; // 1-10
  final int alcoholFrequency; // 1-10
  final WorkMode workMode;
  final int timeAtHome; // porcentaje 0-100
  final int communicationStyle; // 1-10
  final int conflictManagement; // 1-10
  final int responsibilityLevel; // 1-10
  final DateTime createdAt;
  final DateTime? updatedAt;

  Habits({
    String? id,
    required this.userId,
    this.sleepStart = 23,
    this.sleepEnd = 7,
    this.cleanlinessLevel = 5,
    this.noiseTolerance = 5,
    this.partyFrequency = 3,
    this.guestsTolerance = 5,
    this.pets = false,
    this.petTolerance = 5,
    this.alcoholFrequency = 3,
    this.workMode = WorkMode.hybrid,
    this.timeAtHome = 50,
    this.communicationStyle = 5,
    this.conflictManagement = 5,
    this.responsibilityLevel = 5,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory Habits.fromJson(Map<String, dynamic> json) => _$HabitsFromJson(json);

  Map<String, dynamic> toJson() => _$HabitsToJson(this);

  Habits copyWith({
    String? id,
    String? userId,
    int? sleepStart,
    int? sleepEnd,
    int? cleanlinessLevel,
    int? noiseTolerance,
    int? partyFrequency,
    int? guestsTolerance,
    bool? pets,
    int? petTolerance,
    int? alcoholFrequency,
    WorkMode? workMode,
    int? timeAtHome,
    int? communicationStyle,
    int? conflictManagement,
    int? responsibilityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habits(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sleepStart: sleepStart ?? this.sleepStart,
      sleepEnd: sleepEnd ?? this.sleepEnd,
      cleanlinessLevel: cleanlinessLevel ?? this.cleanlinessLevel,
      noiseTolerance: noiseTolerance ?? this.noiseTolerance,
      partyFrequency: partyFrequency ?? this.partyFrequency,
      guestsTolerance: guestsTolerance ?? this.guestsTolerance,
      pets: pets ?? this.pets,
      petTolerance: petTolerance ?? this.petTolerance,
      alcoholFrequency: alcoholFrequency ?? this.alcoholFrequency,
      workMode: workMode ?? this.workMode,
      timeAtHome: timeAtHome ?? this.timeAtHome,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      conflictManagement: conflictManagement ?? this.conflictManagement,
      responsibilityLevel: responsibilityLevel ?? this.responsibilityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
