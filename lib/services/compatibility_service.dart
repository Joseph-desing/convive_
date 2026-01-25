import 'dart:math';
import '../models/habits.dart';

class CompatibilityService {
  /// Calcula compatibilidad entre dos perfiles basado en sus hábitos
  /// Retorna un porcentaje de 0 a 100
  static int calculateCompatibility(Habits userHabits, Habits otherHabits) {
    double totalScore = 0;
    int factorCount = 0;

    // 1. Horarios de sueño (peso: 15%)
    final sleepOverlap = _calculateSleepCompatibility(
      userHabits.sleepStart,
      userHabits.sleepEnd,
      otherHabits.sleepStart,
      otherHabits.sleepEnd,
    );
    totalScore += sleepOverlap * 0.15;
    factorCount++;

    // 2. Nivel de limpieza (peso: 20%)
    final cleanlinessScore = _calculateScaleDifference(
      userHabits.cleanlinessLevel,
      otherHabits.cleanlinessLevel,
    );
    totalScore += cleanlinessScore * 0.20;
    factorCount++;

    // 3. Tolerancia al ruido (peso: 15%)
    final noiseScore = _calculateScaleDifference(
      userHabits.noiseTolerance,
      otherHabits.noiseTolerance,
    );
    totalScore += noiseScore * 0.15;
    factorCount++;

    // 4. Frecuencia de fiestas (peso: 15%)
    final partyScore = _calculateScaleDifference(
      userHabits.partyFrequency,
      otherHabits.partyFrequency,
    );
    totalScore += partyScore * 0.15;
    factorCount++;

    // 5. Tolerancia a invitados (peso: 10%)
    final guestsScore = _calculateScaleDifference(
      userHabits.guestsTolerance,
      otherHabits.guestsTolerance,
    );
    totalScore += guestsScore * 0.10;
    factorCount++;

    // 6. Mascotas (peso: 10%)
    final petsScore = _calculatePetCompatibility(
      userHabits.pets,
      userHabits.petTolerance,
      otherHabits.pets,
      otherHabits.petTolerance,
    );
    totalScore += petsScore * 0.10;
    factorCount++;

    // 7. Frecuencia de alcohol (peso: 5%)
    final alcoholScore = _calculateScaleDifference(
      userHabits.alcoholFrequency,
      otherHabits.alcoholFrequency,
    );
    totalScore += alcoholScore * 0.05;
    factorCount++;

    // 8. Tiempo en casa (peso: 10%)
    final timeAtHomeScore = _calculateScaleDifference(
      userHabits.timeAtHome,
      otherHabits.timeAtHome,
      maxDifference: 100,
    );
    totalScore += timeAtHomeScore * 0.10;
    factorCount++;

    // Normalizar a porcentaje (0-100)
    return (totalScore * 100).round();
  }

  /// Calcula compatibilidad de horarios de sueño
  /// Retorna un valor entre 0 y 1
  static double _calculateSleepCompatibility(
    int userStart,
    int userEnd,
    int otherStart,
    int otherEnd,
  ) {
    // Convertir horarios a minutos desde medianoche
    final userSleepMinutes = _getSleepDurationMinutes(userStart, userEnd);
    final otherSleepMinutes = _getSleepDurationMinutes(otherStart, otherEnd);

    // Calcular diferencia en hora de inicio
    int startDiff = (userStart - otherStart).abs();
    if (startDiff > 12) startDiff = 24 - startDiff;

    // Calcular diferencia en hora de fin
    int endDiff = (userEnd - otherEnd).abs();
    if (endDiff > 12) endDiff = 24 - endDiff;

    // Penalizar diferencias grandes
    final avgDiff = (startDiff + endDiff) / 2;
    return max(0, 1 - (avgDiff / 6)); // Máximo 6 horas de diferencia aceptable
  }

  static int _getSleepDurationMinutes(int start, int end) {
    if (end > start) {
      return (end - start) * 60;
    } else {
      return ((24 - start) + end) * 60;
    }
  }

  /// Calcula compatibilidad en escalas numéricas (1-10)
  /// Retorna un valor entre 0 y 1
  static double _calculateScaleDifference(
    int userValue,
    int otherValue, {
    int maxDifference = 10,
  }) {
    final difference = (userValue - otherValue).abs();
    // Diferencia de 0 = 100% compatible, diferencia máxima = 0% compatible
    return max(0, 1 - (difference / maxDifference));
  }

  /// Calcula compatibilidad de mascotas
  /// Retorna un valor entre 0 y 1
  static double _calculatePetCompatibility(
    bool userHasPets,
    int userPetTolerance,
    bool otherHasPets,
    int otherPetTolerance,
  ) {
    // Si ninguno tiene mascotas, compatibilidad alta
    if (!userHasPets && !otherHasPets) {
      return 1.0;
    }

    // Si uno tiene mascotas, verificar tolerancia del otro
    if (userHasPets && !otherHasPets) {
      return otherPetTolerance / 10;
    }

    if (!userHasPets && otherHasPets) {
      return userPetTolerance / 10;
    }

    // Si ambos tienen mascotas, compatibilidad alta
    if (userHasPets && otherHasPets) {
      return 1.0;
    }

    return 0.5; // fallback
  }
}
