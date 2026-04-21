import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chatbot_message.dart';

class GroqService {
  final String apiKey;
  final String model;
  final String baseUrl;
  late final http.Client _client;

  GroqService({
    required this.apiKey,
    this.model = 'llama-3.1-8b-instant', // Modelo disponible en Groq
    // 🔄 DESARROLLO: Apunta al backend local (FastAPI en puerto 8000)
    this.baseUrl = 'http://localhost:8000',
  }) {
    _client = http.Client();
  }

  /// Enviar mensaje a Groq y obtener respuesta
  Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> chatHistory,
    String? systemPrompt,
  }) async {
    try {
      // 🔄 ACTUALIZADO: Ahora enviamos al backend propio
      // El backend se encarga de comunicarse con Groq
      
      final response = await _client.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'user_message': userMessage,
          'chat_history': chatHistory,
          if (systemPrompt != null) 'system_prompt': systemPrompt,
        }),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout en backend'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 🔄 ACTUALIZADO: Cambio en la estructura de respuesta
        // Backend retorna: { "content": "...", "usage": {...} }
        final content = data['content'] as String?;

        if (content == null || content.isEmpty) {
          throw Exception('No content in response');
        }

        return content;
      } else {
        print('❌ Backend Error ${response.statusCode}. Response: ${response.body}');
        print('📤 Request Body: ${jsonEncode({
          'user_message': userMessage,
          'chat_history': chatHistory,
          if (systemPrompt != null) 'system_prompt': systemPrompt,
        })}');
        final error = jsonDecode(response.body);
        throw Exception('Backend Error: ${error['detail'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error en Groq service: $e');
    }
  }

  /// Obtener recomendaciones de compatibilidad basadas en respuestas del usuario
  Future<List<ChatbotMessage>> getCompatibilityRecommendations({
    required String userId,
    required List<String> userResponses,
    required Map<String, dynamic> userHabits,
  }) async {
    try {
      // Crear un mensaje que solicite recomendaciones
      final prompt = '''
Basándote en las siguientes respuestas del usuario y sus hábitos, proporciona 3 recomendaciones de tipos de compañeros ideales:

Respuestas del usuario: ${userResponses.join(', ')}
Hábitos: ${userHabits.entries.map((e) => '${e.key}: ${e.value}').join(', ')}

Proporciona recomendaciones claras y útiles en formato de lista.
''';

      final response = await sendMessage(
        userMessage: prompt,
        chatHistory: [],
      );

      // Parsear la respuesta en múltiples mensajes
      return [ChatbotMessage(
        type: MessageType.assistant,
        content: response,
      )];
    } catch (e) {
      throw Exception('Error obteniendo recomendaciones: $e');
    }
  }

  /// Procesar mensaje con contexto del usuario
  Future<ChatbotMessage> processMessageWithContext({
    required String userId,
    required String userMessage,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userHabits,
    required List<ChatbotMessage> chatHistory,
  }) async {
    try {
      // Construir prompt de sistema con contexto del usuario
      final systemPrompt = _buildSystemPrompt(userProfile, userHabits);

      // 🔄 ACTUALIZADO: Convertir historial a formato que espera el backend
      // El backend ahora espera: [{ "role": "...", "content": "..." }, ...]
      final groqHistory = chatHistory
          .where((msg) => msg.type.name == 'user' || msg.type.name == 'assistant')
          .map((msg) {
            final role = msg.type.name == 'user' ? 'user' : 'assistant';
            return {'role': role, 'content': msg.content};
          })
          .cast<Map<String, dynamic>>()
          .toList();

      // Enviar al backend propio (no directamente a Groq)
      final response = await sendMessage(
        userMessage: userMessage,
        chatHistory: groqHistory,
        systemPrompt: systemPrompt,
      );

      return ChatbotMessage(
        type: MessageType.assistant,
        content: response,
      );
    } catch (e) {
      throw Exception('Error procesando mensaje: $e');
    }
  }

  /// Construir prompt de sistema con información del usuario
  String _buildSystemPrompt(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> userHabits,
  ) {
    return '''
Eres un asistente amable de ConVive que ayuda a encontrar compañeros de habitación compatibles.

Perfil del usuario:
- Email: ${userProfile['email'] ?? 'N/A'}
- Tipo: ${userProfile['role'] ?? 'N/A'}

Hábitos del usuario (escala 0-10):
- Limpieza: ${userHabits['cleanliness'] ?? 'N/A'}/10
- Tolerancia al ruido: ${userHabits['noise_level'] ?? 'N/A'}/10
- Frecuencia de fiestas: ${userHabits['party_frequency'] ?? 'N/A'}/10
- Tolerancia a invitados: ${userHabits['guests_frequency'] ?? 'N/A'}/10
- Tiempo en casa: ${userHabits['home_time'] ?? 'N/A'}/10
- Responsabilidad: ${userHabits['responsibility'] ?? 'N/A'}/10
- Tolerancia a mascotas: ${userHabits['pets_tolerance'] ?? 'N/A'}/10

Tu rol es ayudar a este usuario a encontrar el compañero ideal según sus hábitos.
Responde siempre en español, de forma concisa y útil.
''';
  }

  void dispose() {
    _client.close();
  }
}
