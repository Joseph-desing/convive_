import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/chatbot_message.dart';
import 'groq_service.dart';

class ChatbotService {
  final String baseUrl;
  final String mockBaseUrl;
  late final http.Client _client;
  final GroqService? _groqService;

  ChatbotService({
    String? baseUrl,
    String? mockBaseUrl,
    String? groqApiKey,
  })  : baseUrl = (baseUrl ?? AppConfig.aiServiceUrl).trim(),
        mockBaseUrl = (mockBaseUrl ?? AppConfig.chatbotMockUrl).trim(),
        _groqService = ((baseUrl ?? AppConfig.aiServiceUrl).trim().isNotEmpty ||
                (mockBaseUrl ?? AppConfig.chatbotMockUrl).trim().isNotEmpty)
            ? GroqService(
                apiKey: groqApiKey,
                baseUrl: (baseUrl ?? AppConfig.aiServiceUrl).trim().isNotEmpty
                    ? (baseUrl ?? AppConfig.aiServiceUrl).trim()
                    : (mockBaseUrl ?? AppConfig.chatbotMockUrl).trim(),
              )
            : null {
    _client = http.Client();
  }

  bool get useGroq =>
      _groqService != null && (baseUrl.isNotEmpty || mockBaseUrl.isNotEmpty);
  bool get useMock => mockBaseUrl.isNotEmpty;

  /// Procesar mensaje del usuario y obtener respuesta del chatbot con IA.
  Future<ChatbotMessage> processUserMessage({
    required String userId,
    required String userMessage,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userHabits,
    required List<ChatbotMessage> chatHistory,
    int conversationCount = 0,
    bool preferGroq = false,
  }) async {
    if (preferGroq) {
      if (useGroq) {
        try {
          return await _groqService!.processMessageWithContext(
            userId: userId,
            userMessage: userMessage,
            userProfile: userProfile,
            userHabits: userHabits,
            chatHistory: chatHistory,
          );
        } catch (error) {
          return _serviceUnavailableMessage(detail: error.toString());
        }
      }
      return _serviceUnavailableMessage();
    }

    // Primario cuando esta configurado: backend guiado con opciones/botones.
    if (useMock) {
      try {
        final history = chatHistory
            .where((m) =>
                m.type == MessageType.user || m.type == MessageType.assistant)
            .map((m) => {'type': m.type.name, 'content': m.content})
            .toList();

        final response = await _client.post(
          Uri.parse('$mockBaseUrl/chatbot/process'),
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
        // Mock no disponible: fallback a Groq si esta configurado.
      }
    }

    if (useGroq) {
      try {
        return await _groqService!.processMessageWithContext(
          userId: userId,
          userMessage: userMessage,
          userProfile: userProfile,
          userHabits: userHabits,
          chatHistory: chatHistory,
        );
      } catch (_) {
        return _serviceUnavailableMessage();
      }
    }

    return _serviceUnavailableMessage();
  }

  /// Obtener multiples recomendaciones de compatibilidad.
  Future<List<ChatbotMessage>> getCompatibilityRecommendation({
    required String userId,
    required List<String> userResponses,
    required Map<String, dynamic> userHabits,
    List<Map<String, dynamic>> roommateSearches = const [],
  }) async {
    if (useMock) {
      try {
        final response = await _client.post(
          Uri.parse('$mockBaseUrl/chatbot/recommend'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'responses': userResponses,
            'habits': userHabits,
            'roommate_searches': roommateSearches,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          if (data['type'] == 'suggestions_batch') {
            final recs = data['recommendations'] as List;

            if (recs.isEmpty) {
              final searchType = userResponses.any(
                (r) => r.toLowerCase().contains('departamento'),
              )
                  ? 'departamento'
                  : 'companero';
              return [
                ChatbotMessage(
                  type: MessageType.assistant,
                  content:
                      'Lo siento, no encontramos ningun $searchType compatible para ti en este momento.\n\nPuedes ajustar tus preferencias o intentarlo mas tarde cuando haya mas usuarios en tu zona.',
                  options: ['Intentar de nuevo', 'Cambiar preferencias'],
                ),
              ];
            }

            return recs.map((r) {
              final rec = r as Map<String, dynamic>;
              return ChatbotMessage(
                type: MessageType.suggestion,
                content: rec['content'] as String,
                matchedUserId: rec['matched_user_id'] as String?,
                matchedUserName: rec['matched_user_name'] as String?,
                matchedUserAvatar: rec['matched_user_avatar'] as String?,
                compatibilityScore:
                    (rec['compatibility_score'] as num?)?.toDouble(),
                propertyLocation:
                    rec['property_location'] as Map<String, dynamic>?,
              );
            }).toList();
          }

          return [
            ChatbotMessage(
              type: MessageType.assistant,
              content: data['content'] as String,
              options: (data['options'] as List?)?.cast<String>(),
            ),
          ];
        }
      } catch (_) {
        // Mock no disponible: intentar Groq.
      }
    }

    if (useGroq) {
      try {
        return await _groqService!.getCompatibilityRecommendations(
          userId: userId,
          userResponses: userResponses,
          userHabits: userHabits,
        );
      } catch (_) {
        return [_serviceUnavailableMessage()];
      }
    }

    return [_serviceUnavailableMessage()];
  }

  /// Obtener mensaje de bienvenida personalizado con opciones.
  Future<ChatbotMessage> getWelcomeMessage(String userName) async {
    if (useMock) {
      try {
        final response = await _client.post(
          Uri.parse('$mockBaseUrl/chatbot/welcome'),
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
        // Mock no disponible, usar bienvenida local.
      }
    }

    return ChatbotMessage(
      type: MessageType.assistant,
      content:
          'Hola $userName! Soy tu asistente de ConVive. Que estas buscando?',
      options: ['Companero de cuarto', 'Departamento'],
    );
  }

  void dispose() {
    _client.close();
    _groqService?.dispose();
  }

  ChatbotMessage _serviceUnavailableMessage({String? detail}) {
    return ChatbotMessage(
      type: MessageType.assistant,
      content: detail == null
          ? 'Aun no tengo conexion con el asistente en linea. Para que funcione en el APK, configura la URL publica del backend al compilar.'
          : 'El asistente en linea respondio con un error. Revisa que el backend este desplegado con el modelo correcto de Groq.\n\nDetalle tecnico: $detail',
    );
  }
}
