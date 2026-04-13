import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chatbot_message.dart';
import 'groq_service.dart';

class ChatbotService {
  final String baseUrl;
  late final http.Client _client;
  final GroqService? _groqService;

  ChatbotService({
    this.baseUrl = 'http://localhost:8000', // Cambiar a URL real
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
    // Si Groq está disponible, usar Groq
    if (useGroq) {
      return await _groqService!.processMessageWithContext(
        userId: userId,
        userMessage: userMessage,
        userProfile: userProfile,
        userHabits: userHabits,
        chatHistory: chatHistory,
      );
    }

    // Sin Groq ni Backend disponible
    return ChatbotMessage(
      type: MessageType.assistant,
      content: 'No hay servicio de IA disponible. Configura Groq primero.',
    );
  }

  /// Obtener múltiples recomendaciones de compatibilidad
  Future<List<ChatbotMessage>> getCompatibilityRecommendation({
    required String userId,
    required List<String> userResponses,
    required Map<String, dynamic> userHabits,
  }) async {
    // Si Groq está disponible, usarlo para generar recomendaciones
    if (useGroq) {
      return await _groqService!.getCompatibilityRecommendations(
        userId: userId,
        userResponses: userResponses,
        userHabits: userHabits,
      );
    }

    // Sin Groq disponible
    return [ChatbotMessage(
      type: MessageType.assistant,
      content: 'No hay servicio de IA disponible para búsqueda. Configura Groq primero.',
    )];
  }

  /// Obtener mensaje de bienvenida personalizado con opciones
  Future<ChatbotMessage> getWelcomeMessage(String userName) async {
    return ChatbotMessage(
      type: MessageType.assistant,
      content: 'Bienvenido a ConVive, $userName',
      options: ['Compañero de cuarto', 'Departamento'],
    );
  }

  void dispose() {
    _client.close();
    _groqService?.dispose();
  }
}
