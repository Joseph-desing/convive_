import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chatbot_message.dart';
import 'groq_service.dart';

class ChatbotService {
  final String baseUrl;
  // URL del backend mock (flujo guiado por etapas, sin Groq)
  static const String _mockUrl = 'http://localhost:8001';
  late final http.Client _client;
  final GroqService? _groqService;

  ChatbotService({
    this.baseUrl = 'http://localhost:8000',
    String? groqApiKey,
  }) : _groqService = (groqApiKey != null && groqApiKey.isNotEmpty)
          ? GroqService(apiKey: groqApiKey)
          : null {
    _client = http.Client();
  }

  bool get useGroq => _groqService != null;

  /// Procesar mensaje del usuario y obtener respuesta del chatbot con IA
  Future<ChatbotMessage> processUserMessage({
    required String userId,
    required String userMessage,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userHabits,
    required List<ChatbotMessage> chatHistory,
    int conversationCount = 0,
  }) async {
    // PRIMARIO: mock backend (flujo guiado con opciones/botones)
    // Groq se usa solo como fallback si el mock no está disponible
    try {
      final history = chatHistory
          .where((m) => m.type == MessageType.user || m.type == MessageType.assistant)
          .map((m) => {'type': m.type.name, 'content': m.content})
          .toList();

      final response = await _client.post(
        Uri.parse('$_mockUrl/chatbot/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'message': userMessage,
          'user_profile': userProfile,
          'user_habits': userHabits,
          'conversation_count': conversationCount,
          'chat_history': history,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatbotMessage(
          type: MessageType.assistant,
          content: data['content'] as String,
          options: (data['options'] as List?)?.cast<String>(),
        );
      }
    } catch (_) {
      // Mock no disponible → fallback a Groq si está configurado
    }

    // FALLBACK: Groq para respuestas libres cuando el mock no responde
    if (useGroq) {
      return await _groqService!.processMessageWithContext(
        userId: userId,
        userMessage: userMessage,
        userProfile: userProfile,
        userHabits: userHabits,
        chatHistory: chatHistory,
      );
    }

    return ChatbotMessage(
      type: MessageType.assistant,
      content: 'El servicio de chatbot no está disponible. Asegúrate de que el backend esté corriendo (puerto 8001).',
    );
  }

  /// Obtener múltiples recomendaciones de compatibilidad
  Future<List<ChatbotMessage>> getCompatibilityRecommendation({
    required String userId,
    required List<String> userResponses,
    required Map<String, dynamic> userHabits,
  }) async {
    // PRIMARIO: mock backend
    try {
      final response = await _client.post(
        Uri.parse('$_mockUrl/chatbot/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'responses': userResponses,
          'habits': userHabits,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Respuesta con lote de sugerencias
        if (data['type'] == 'suggestions_batch') {
          final recs = data['recommendations'] as List;

          // Sin resultados → mensaje amigable
          if (recs.isEmpty) {
            final searchType = (userResponses.any((r) => r.toLowerCase().contains('departamento')))
                ? 'departamento'
                : 'compañero';
            return [ChatbotMessage(
              type: MessageType.assistant,
              content: 'Lo siento 😔, no encontramos ningún $searchType compatible para ti en este momento.\n\nPuedes ajustar tus preferencias o intentarlo más tarde cuando haya más usuarios en tu zona.',
              options: ['Intentar de nuevo', 'Cambiar preferencias'],
            )];
          }

          return recs.map((r) {
            final rec = r as Map<String, dynamic>;
            return ChatbotMessage(
              type: MessageType.suggestion,
              content: rec['content'] as String,
              matchedUserId: rec['matched_user_id'] as String?,
              matchedUserName: rec['matched_user_name'] as String?,
              matchedUserAvatar: rec['matched_user_avatar'] as String?,
              compatibilityScore: (rec['compatibility_score'] as num?)?.toDouble(),
              propertyLocation: rec['property_location'] as Map<String, dynamic>?,
            );
          }).toList();
        }

        // Respuesta simple (sin resultados)
        return [ChatbotMessage(
          type: MessageType.assistant,
          content: data['content'] as String,
          options: (data['options'] as List?)?.cast<String>(),
        )];
      }
    } catch (_) {
      // Mock no disponible → intentar Groq
    }

    // FALLBACK: Groq
    if (useGroq) {
      return await _groqService!.getCompatibilityRecommendations(
        userId: userId,
        userResponses: userResponses,
        userHabits: userHabits,
      );
    }

    return [ChatbotMessage(
      type: MessageType.assistant,
      content: 'Lo siento 😔, no pudimos conectar con el servidor. Asegúrate de que el backend esté corriendo (puerto 8001).',
    )];
  }

  /// Obtener mensaje de bienvenida personalizado con opciones
  Future<ChatbotMessage> getWelcomeMessage(String userName) async {
    try {
      final response = await _client.post(
        Uri.parse('$_mockUrl/chatbot/welcome'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_name': userName}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatbotMessage(
          type: MessageType.assistant,
          content: data['content'] as String,
          options: (data['options'] as List?)?.cast<String>(),
        );
      }
    } catch (_) {
      // Mock no disponible, usar bienvenida local
    }

    return ChatbotMessage(
      type: MessageType.assistant,
      content: '¡Hola $userName! 👋 Soy tu asistente de ConVive. ¿Qué estás buscando?',
      options: ['Compañero de cuarto', 'Departamento'],
    );
  }

  void dispose() {
    _client.close();
    _groqService?.dispose();
  }
}
