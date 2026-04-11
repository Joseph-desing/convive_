import 'package:flutter/foundation.dart';
import '../models/chatbot_message.dart';
import '../models/user.dart';
import '../services/chatbot_service.dart';
import '../services/supabase_database_service.dart';

class ChatbotProvider extends ChangeNotifier {
  final ChatbotService _chatbotService;
  final SupabaseDatabaseService _databaseService;

  List<ChatbotMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentRecommendation;

  ChatbotProvider({
    required ChatbotService chatbotService,
    required SupabaseDatabaseService databaseService,
  })  : _chatbotService = chatbotService,
        _databaseService = databaseService;

  /// Getters
  List<ChatbotMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get currentRecommendation => _currentRecommendation;

  /// Inicializar chatbot con bienvenida
  Future<void> initializeChatbot(User user, {String? fullName}) async {
    try {
      _isLoading = true;
      _error = null;
      // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
      Future.microtask(() => notifyListeners());

      // Obtener nombre completo del perfil si no viene en parámetro
      String userName = fullName ?? 'Usuario';
      
      if (userName == 'Usuario') {
        try {
          // Cargar perfil desde BD para obtener nombre completo
          final profile = await _databaseService.getProfile(user.id);
          userName = profile?.fullName ?? user.email.split('@').first ?? 'Usuario';
        } catch (e) {
          // Si falla, usar email
          userName = user.email.split('@').first ?? 'Usuario';
        }
      }
      
      // Obtener mensaje de bienvenida del backend (con opciones)
      final welcomeMessage = await _chatbotService.getWelcomeMessage(userName);

      // Agregar mensaje de bienvenida completo (incluye opciones)
      _messages.add(welcomeMessage);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error inicializando chatbot: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enviar mensaje del usuario
  Future<void> sendMessage(
    String userMessage,
    User currentUser,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
      Future.microtask(() => notifyListeners());

      // Agregar mensaje del usuario
      _messages.add(
        ChatbotMessage(
          type: MessageType.user,
          content: userMessage,
        ),
      );

      // Contar cuántos turnos llevan en la conversación (solo mensajes del usuario)
      int conversationCount = _messages.where((m) => m.type == MessageType.user).length;

      // Obtener perfil y hábitos del usuario (ANTES de usarlos)
      final userProfile = {
        'id': currentUser.id,
        'email': currentUser.email,
        'role': currentUser.role.toString(),
        'subscription_type': currentUser.subscriptionType.toString(),
      };

      // TODO: Obtener hábitos reales del usuario
      final userHabits = {
        'cleanliness': 4,        // Nivel de limpieza: 4/10
        'noise_level': 3,        // Tolerancia al ruido: 3/10
        'party_frequency': 3,    // Frecuencia de fiestas: 3/10
        'guests_frequency': 2,   // Tolerancia a invitados: 2/10
        'home_time': 5,          // Tiempo en casa: 5/10
        'responsibility': 7,     // Nivel de responsabilidad: 7/10
        'pets_tolerance': 10,    // Tolerancia a mascotas: 10/10
      };

      // Detectar si el usuario quiere ver recomendaciones
      if (userMessage.toLowerCase().contains('mostrar') || 
          userMessage.toLowerCase().contains('sí') ||
          userMessage.toLowerCase().contains('si')) {
        // Extraer respuestas del usuario del historial
        List<String> userResponses = _messages
            .where((m) => m.type == MessageType.user)
            .map((m) => m.content)
            .toList();

        // Llamar a endpoint de recomendaciones
        await getRecommendation(
          currentUser,
          userResponses,
          userHabits,
        );

        _isLoading = false;
        notifyListeners();
        return; // Salir sin procesar mensaje normal
      }

      // Procesar mensaje con IA
      final response = await _chatbotService.processUserMessage(
        userId: currentUser.id,
        userMessage: userMessage,
        userProfile: userProfile,
        userHabits: userHabits,
        chatHistory: _messages,  // Pasar historial para contexto
        conversationCount: conversationCount,
      );

      // Agregar respuesta del chatbot
      _messages.add(response);

      // Si la respuesta contiene una sugerencia, guardarla
      if (response.type == MessageType.suggestion && response.matchedUserId != null) {
        _currentRecommendation = {
          'user_id': response.matchedUserId,
          'name': response.matchedUserName,
          'avatar': response.matchedUserAvatar,
          'compatibility_score': response.compatibilityScore,
          'location': response.propertyLocation,
        };
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error enviando mensaje: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener recomendación de compatibilidad basada en hábitos del usuario
  Future<void> getRecommendation(
    User currentUser,
    List<String> userResponses,
    Map<String, dynamic>? userHabits,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      // ✅ NUEVO: Diferir notifyListeners para evitar errores durante build
      Future.microtask(() => notifyListeners());

      // Usar hábitos proporcionados o utilizar valores por defecto
      final habits = userHabits ?? {
        'cleanliness': 4,        // Nivel de limpieza: 4/10
        'noise_level': 3,        // Tolerancia al ruido: 3/10
        'party_frequency': 3,    // Frecuencia de fiestas: 3/10
        'guests_frequency': 2,   // Tolerancia a invitados: 2/10
        'home_time': 5,          // Tiempo en casa: 5/10
        'responsibility': 7,     // Nivel de responsabilidad: 7/10
        'pets_tolerance': 10,    // Tolerancia a mascotas: 10/10
      };

      // Obtener lista de recomendaciones
      final responses = await _chatbotService.getCompatibilityRecommendation(
        userId: currentUser.id,
        userResponses: userResponses,
        userHabits: habits,
      );

      // Agregar TODAS las recomendaciones como mensajes
      for (final response in responses) {
        _messages.add(response);

        if (response.type == MessageType.suggestion && response.matchedUserId != null) {
          _currentRecommendation = {
            'user_id': response.matchedUserId,
            'name': response.matchedUserName,
            'avatar': response.matchedUserAvatar,
            'compatibility_score': response.compatibilityScore,
            'location': response.propertyLocation,
          };
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error obteniendo recomendación: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpiar mensajes
  void clearMessages() {
    _messages = [];
    _currentRecommendation = null;
    _error = null;
    notifyListeners();
  }

  /// Obtener detalles de usuario recomendado
  Future<User?> getRecommendedUserDetails(String userId) async {
    try {
      // TODO: Implementar obtención de datos del usuario desde Supabase
      return null;
    } catch (e) {
      _error = 'Error obteniendo detalles: $e';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _chatbotService.dispose();
    super.dispose();
  }
}
