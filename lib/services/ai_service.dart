import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  final String baseUrl;
  late final http.Client _client;

  AIService({
    this.baseUrl = 'http://localhost:8000', // Cambiar a la URL real del servidor
  }) {
    _client = http.Client();
  }

  /// Calcular score de compatibilidad entre dos usuarios
  /// Basado en sus hábitos y perfil
  Future<double> calculateCompatibilityScore({
    required String userId1,
    required String userId2,
    required Map<String, dynamic> user1Habits,
    required Map<String, dynamic> user2Habits,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/compatibility-score'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id_1': userId1,
          'user_id_2': userId2,
          'habits_1': user1Habits,
          'habits_2': user2Habits,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout calculating compatibility score'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['compatibility_score'] as num).toDouble();
      } else {
        throw Exception('Failed to calculate compatibility: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calculating compatibility: $e');
    }
  }

  /// Validar imagen de perfil
  /// Retorna si la imagen es válida (rostro detectado, calidad, etc)
  Future<bool> validateProfileImage(String imageUrl) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/validate-profile-image'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_url': imageUrl,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout validating profile image'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_valid'] as bool;
      } else {
        throw Exception('Failed to validate profile image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error validating profile image: $e');
    }
  }

  /// Validar imagen de propiedad
  /// Retorna si la imagen es válida (contiene el departamento, calidad, etc)
  Future<bool> validatePropertyImage(String imageUrl) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/validate-property-image'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_url': imageUrl,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout validating property image'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_valid'] as bool;
      } else {
        throw Exception('Failed to validate property image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error validating property image: $e');
    }
  }

  /// Obtener recomendaciones personalizadas
  /// Basado en el perfil y hábitos del usuario
  Future<List<String>> getRecommendations({
    required String userId,
    required Map<String, dynamic> userHabits,
    int limit = 10,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'habits': userHabits,
          'limit': limit,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout getting recommendations'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = (data['recommendations'] as List)
            .map((e) => e as String)
            .toList();
        return recommendations;
      } else {
        throw Exception('Failed to get recommendations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting recommendations: $e');
    }
  }

  /// Detectar anomalías o perfiles sospechosos
  Future<Map<String, dynamic>> detectAnomaly({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/detect-anomaly'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'profile_data': profileData,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout detecting anomaly'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to detect anomaly: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error detecting anomaly: $e');
    }
  }

  /// Cerrar el cliente HTTP
  void dispose() {
    _client.close();
  }
}
