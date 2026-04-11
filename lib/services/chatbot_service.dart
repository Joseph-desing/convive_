import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chatbot_message.dart';

class ChatbotService {
  final String baseUrl;
  late final http.Client _client;

  ChatbotService({
    this.baseUrl = 'http://localhost:8000', // Cambiar a URL real
  }) {
    _client = http.Client();
  }

  /// Procesar mensaje del usuario y obtener respuesta del chatbot con IA
  Future<ChatbotMessage> processUserMessage({
    required String userId,
    required String userMessage,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userHabits,
    required List<ChatbotMessage> chatHistory,
    int conversationCount = 0,
  }) async {
    try {
      // Convertir historial a JSON (últimos 10 mensajes)
      final history = chatHistory
          .take(10)
          .map((msg) => {
                'type': msg.type.toString().split('.').last,
                'content': msg.content,
              })
          .toList();

      final response = await _client.post(
        Uri.parse('$baseUrl/chatbot/process'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'message': userMessage,
          'user_profile': userProfile,
          'user_habits': userHabits,
          'conversation_count': conversationCount,
          'chat_history': history,  // Nuevo: historial de chat
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout en chatbot service'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatbotMessage.fromJson(data);
      } else {
        throw Exception('Error chatbot: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error procesando mensaje: $e');
    }
  }

  /// Obtener múltiples recomendaciones de compatibilidad
  Future<List<ChatbotMessage>> getCompatibilityRecommendation({
    required String userId,
    required List<String> userResponses,
    required Map<String, dynamic> userHabits,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chatbot/recommend'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'responses': userResponses,
          'habits': userHabits,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout en recomendación'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Caso 1: Mensaje de "no hay resultados" (sin recommendations array)
        if (data['recommendations'] == null && data['type'] != null) {
          // Es un mensaje especial (error/no-results)
          return [ChatbotMessage.fromJson(data)];
        }
        
        // Caso 2: Array de recomendaciones
        if (data['recommendations'] != null && data['recommendations'] is List) {
          final List<ChatbotMessage> recommendations = [];
          for (var rec in data['recommendations']) {
            recommendations.add(ChatbotMessage.fromJson(rec));
          }
          return recommendations;
        }
        
        // Fallback: una sola recomendación
        return [ChatbotMessage.fromJson(data)];
      } else {
        throw Exception('Error obteniendo recomendación: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en recomendación: $e');
    }
  }

  /// Obtener mensaje de bienvenida personalizado con opciones
  Future<ChatbotMessage> getWelcomeMessage(String userName) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chatbot/welcome'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_name': userName,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatbotMessage.fromJson(data);
      } else {
        // Retornar mensaje por defecto
        return ChatbotMessage(
          type: MessageType.assistant,
          content: 'Bienvenido a ConVive',
          options: ['Compañero de cuarto', 'Departamento'],
        );
      }
    } catch (e) {
      return ChatbotMessage(
        type: MessageType.assistant,
        content: 'Bienvenido a ConVive',
        options: ['Compañero de cuarto', 'Departamento'],
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
