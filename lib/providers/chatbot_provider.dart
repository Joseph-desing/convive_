import 'package:flutter/foundation.dart';
import '../models/chatbot_message.dart';
import '../models/property.dart';
import '../models/roommate_search.dart';
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
      Future.microtask(() => notifyListeners());

      // Obtener nombre completo del perfil si no viene en parámetro
      String userName = fullName ?? 'Usuario';
      
      if (userName == 'Usuario') {
        try {
          final profile = await _databaseService.getProfile(user.id);
          userName = profile?.fullName ?? user.email.split('@').first ?? 'Usuario';
        } catch (e) {
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
      Future.microtask(() => notifyListeners());

      // Agregar mensaje del usuario
      _messages.add(
        ChatbotMessage(
          type: MessageType.user,
          content: userMessage,
        ),
      );

      // Contar cuántos turnos llevan en la conversación
      int conversationCount = _messages.where((m) => m.type == MessageType.user).length;

      // Obtener perfil del usuario
      final userProfile = {
        'id': currentUser.id,
        'email': currentUser.email,
        'role': currentUser.role.toString(),
        'subscription_type': currentUser.subscriptionType.toString(),
      };

      // 🔍 LEER HÁBITOS REALES del usuario desde BD
      Map<String, dynamic> userHabits = {};
      try {
        final habits = await _databaseService.getHabits(currentUser.id);
        if (habits != null) {
          userHabits = {
            'cleanliness': habits.cleanlinessLevel ?? 5,
            'noise_level': habits.noiseTolerance ?? 5,
            'party_frequency': habits.partyFrequency ?? 5,
            'guests_frequency': habits.guestsTolerance ?? 5,
            'home_time': habits.timeAtHome ?? 50,
            'responsibility': habits.responsibilityLevel ?? 5,
            'pets_tolerance': habits.petTolerance ?? 5,
          };
          print('✅ Hábitos cargados: $userHabits');
        }
      } catch (e) {
        print('⚠️ Error cargando hábitos: $e');
        userHabits = {
          'cleanliness': 5,
          'noise_level': 5,
          'party_frequency': 5,
          'guests_frequency': 5,
          'home_time': 50,
          'responsibility': 5,
          'pets_tolerance': 5,
        };
      }

      // Detectar si el usuario quiere ver recomendaciones
      final msgLower = userMessage.toLowerCase();
      final wantsExplanation = _isCompatibilityExplanationRequest(msgLower);

      if (wantsExplanation) {
        final lastSuggestion = _lastSuggestionMessage();
        _messages.add(
          ChatbotMessage(
            type: MessageType.assistant,
            content: lastSuggestion == null
                ? 'Primero necesito mostrarte una coincidencia concreta para poder explicarte por qué es compatible contigo. Toca "Sí, mostrar departamentos" o "Sí, mostrar compañeros" y luego te explico el resultado.'
                : _buildCompatibilityExplanation(lastSuggestion, userHabits),
          ),
        );

        _isLoading = false;
        notifyListeners();
        return;
      }

      final wantsRecommendation =
          msgLower.contains('mostrar') ||
          msgLower.contains('sí, mostrar') ||
          msgLower.contains('si, mostrar') ||
          msgLower.contains('ver compañeros') ||
          msgLower.contains('mostrar compañeros') ||
          msgLower.contains('mostrar departamentos') ||
          msgLower.contains('ver departamentos') ||
          msgLower.contains('ver opciones');

      final shouldUseFreeAi =
          _isFreeTextQuestion(msgLower) && !_matchesLatestOption(userMessage);

      if (wantsRecommendation) {
        List<String> userResponses = _messages
            .where((m) => m.type == MessageType.user)
            .map((m) => m.content)
            .toList();

        await getRecommendation(currentUser, userResponses, userHabits);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Procesar mensaje con IA
      final response = await _chatbotService.processUserMessage(
        userId: currentUser.id,
        userMessage: userMessage,
        userProfile: userProfile,
        userHabits: userHabits,
        chatHistory: _messages,
        conversationCount: conversationCount,
        preferGroq: shouldUseFreeAi,
      );

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
      final wantsRoommate = userResponses.any(
        (response) => _normalizeText(response).contains('companero') ||
            response.toLowerCase().contains('compa') ||
            _normalizeText(response).contains('roommate') ||
            _normalizeText(response).contains('roomie'),
      );
      final activeRoommateSearches = wantsRoommate
          ? await _loadActiveRoommateSearches(currentUser.id)
          : <RoommateSearch>[];

      // Obtener lista de recomendaciones
      final responses = await _chatbotService.getCompatibilityRecommendation(
        userId: currentUser.id,
        userResponses: userResponses,
        userHabits: habits,
        roommateSearches:
            activeRoommateSearches.map((search) => search.toJson()).toList(),
      );
      final scopedResponses = wantsRoommate
          ? _scopeRoommateRecommendationsToSearches(
              responses,
              activeRoommateSearches,
            )
          : responses;
      final finalResponses = await _withPropertyFallbackIfNeeded(
        currentUser.id,
        userResponses,
        scopedResponses,
      );

      // Agregar TODAS las recomendaciones como mensajes
      for (final response in finalResponses) {
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

  Future<List<RoommateSearch>> _loadActiveRoommateSearches(
    String currentUserId,
  ) async {
    try {
      final searches = await _databaseService.getActiveRoommateSearches(
        limit: 20,
        excludeUserId: currentUserId,
      );
      final searchesWithLocation = searches
          .where((search) => search.latitude != null && search.longitude != null)
          .toList();
      print(
        'Chatbot: roommate_searches activas con ubicacion enviadas=${searchesWithLocation.length}',
      );
      return searchesWithLocation;
    } catch (e) {
      print('Chatbot: error cargando roommate_searches activas: $e');
      return [];
    }
  }

  List<ChatbotMessage> _scopeRoommateRecommendationsToSearches(
    List<ChatbotMessage> responses,
    List<RoommateSearch> activeSearches,
  ) {
    if (activeSearches.isEmpty) return responses;

    final searchesByUser = {
      for (final search in activeSearches) search.userId: search,
    };

    final scoped = responses
        .where((message) =>
            message.type != MessageType.suggestion ||
            (message.matchedUserId != null &&
                searchesByUser.containsKey(message.matchedUserId)))
        .map((message) {
      if (message.type != MessageType.suggestion ||
          message.matchedUserId == null) {
        return message;
      }

      final search = searchesByUser[message.matchedUserId];
      if (search == null) return message;

      return message.copyWith(
        propertyLocation: {
          'lat': search.latitude,
          'lng': search.longitude,
          'address': search.address,
        },
      );
    }).toList();

    if (scoped.any((message) => message.type == MessageType.suggestion)) {
      return scoped;
    }

    return activeSearches
        .where((search) => search.latitude != null && search.longitude != null)
        .take(3)
        .map(_buildRoommateSearchSuggestion)
        .toList();
  }

  ChatbotMessage _buildRoommateSearchSuggestion(RoommateSearch search) {
    final budget = search.budget > 0
        ? ' con presupuesto de \$${search.budget.toStringAsFixed(0)}/mes'
        : '';
    final address =
        search.address.trim().isNotEmpty ? ' en ${search.address.trim()}' : '';
    final preferences = search.habitsPreferences.isNotEmpty
        ? '\n\nBusca: ${search.habitsPreferences.take(4).join(', ')}.'
        : '';

    return ChatbotMessage(
      type: MessageType.suggestion,
      content:
          'Hay una publicación activa de compañero/a: ${search.title}$address$budget.$preferences',
      matchedUserId: search.userId,
      matchedUserName: search.title,
      compatibilityScore: 0.55,
      propertyLocation: {
        'lat': search.latitude,
        'lng': search.longitude,
        'address': search.address,
      },
    );
  }

  Future<List<ChatbotMessage>> _withPropertyFallbackIfNeeded(
    String currentUserId,
    List<String> userResponses,
    List<ChatbotMessage> responses,
  ) async {
    final wantsDepartment = userResponses.any(
      (response) => _normalizeText(response).contains('departamento') ||
          _normalizeText(response).contains('apartamento') ||
          _normalizeText(response).contains('depa') ||
          _normalizeText(response).contains('vivienda'),
    );

    final isEmptyDepartmentResponse = responses.length == 1 &&
        responses.first.type == MessageType.assistant &&
        _normalizeText(responses.first.content).contains('no encontramos') &&
        _normalizeText(responses.first.content).contains('departamento');

    if (!wantsDepartment || !isEmptyDepartmentResponse) {
      return responses;
    }

    try {
      print('Chatbot fallback: buscando departamentos activos en Supabase');
      final properties = await _databaseService.getProperties(
        limit: 3,
        excludeUserId: currentUserId,
      );
      print('Chatbot fallback: propiedades disponibles=${properties.length}');

      if (properties.isEmpty) {
        return responses;
      }

      return properties.map(_buildPropertySuggestion).toList();
    } catch (e) {
      print('Chatbot fallback: error consultando propiedades: $e');
      return responses;
    }
  }

  ChatbotMessage _buildPropertySuggestion(Property property) {
    final price = property.price > 0
        ? ' por \$${property.price.toStringAsFixed(0)}/mes'
        : '';
    final address = property.address.trim().isNotEmpty
        ? ' en ${property.address.trim()}'
        : '';
    final bedrooms = property.bedrooms > 0
        ? '${property.bedrooms} habitacion${property.bedrooms == 1 ? '' : 'es'}'
        : 'habitaciones disponibles';

    return ChatbotMessage(
      type: MessageType.suggestion,
      content:
          'Hay un departamento publicado disponible: ${property.title}$address$price.\n\n'
          'Cuenta con $bedrooms y esta disponible desde ${property.availableFrom.day}/${property.availableFrom.month}/${property.availableFrom.year}.\n\n'
          'No coincide necesariamente al 100% con todos tus criterios, pero es una opcion real disponible que puedes revisar.',
      matchedUserId: property.ownerId,
      matchedUserName: property.title,
      compatibilityScore: 0.55,
      propertyLocation: {
        'lat': property.latitude,
        'lng': property.longitude,
        'address': property.address,
      },
    );
  }

  bool _isCompatibilityExplanationRequest(String message) {
    final normalized = message
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');

    return normalized.contains('explica') ||
        normalized.contains('por que') ||
        normalized.contains('porque') ||
        normalized.contains('detalle') ||
        normalized.contains('compatible conmigo') ||
        normalized.contains('compatibilidad');
  }

  ChatbotMessage? _lastSuggestionMessage() {
    for (final message in _messages.reversed) {
      if (message.type == MessageType.suggestion) {
        return message;
      }
    }
    return null;
  }

  String _buildCompatibilityExplanation(
    ChatbotMessage suggestion,
    Map<String, dynamic> userHabits,
  ) {
    final score = ((suggestion.compatibilityScore ?? 0) * 100).round();
    final name = suggestion.matchedUserName ?? 'esta recomendación';
    final hasLocation = suggestion.propertyLocation != null;
    final target = hasLocation ? 'esta opción' : 'esta persona';
    final cleanedContent = suggestion.content
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final habitSummary = [
      if (userHabits['cleanliness'] != null)
        'limpieza ${userHabits['cleanliness']}/10',
      if (userHabits['noise_level'] != null)
        'ruido ${userHabits['noise_level']}/10',
      if (userHabits['responsibility'] != null)
        'responsabilidad ${userHabits['responsibility']}/10',
      if (userHabits['pets_tolerance'] != null)
        'mascotas ${userHabits['pets_tolerance']}/10',
    ].join(', ');

    return 'Claro. $name aparece con $score% de compatibilidad porque $target coincide con tus hábitos registrados y con las respuestas que diste en el chat.\n\n'
        'Se revisan factores como limpieza, ruido, visitas, fiestas, tiempo en casa, responsabilidad y mascotas${habitSummary.isEmpty ? '.' : ' ($habitSummary).'}\n\n'
        'Resumen de la coincidencia: $cleanedContent\n\n'
        'El porcentaje no es al azar: mientras más parecidos sean tus hábitos y preferencias con la publicación o el perfil recomendado, más alto aparece el resultado.';
  }

  bool _isFreeTextQuestion(String message) {
    final normalized = _normalizeText(message);

    return message.contains('?') ||
        normalized.contains('no hay') ||
        normalized.contains('mas opciones') ||
        normalized.contains('otra opcion') ||
        normalized.contains('otra casa') ||
        normalized.contains('otro departamento') ||
        normalized.contains('recomienda') ||
        normalized.contains('ayuda') ||
        normalized.contains('que hago') ||
        normalized.contains('cual') ||
        normalized.contains('como') ||
        normalized.contains('puedes') ||
        normalized.contains('dime');
  }

  bool _matchesLatestOption(String userMessage) {
    final normalizedMessage = _normalizeText(userMessage);
    if (normalizedMessage.isEmpty) return false;

    for (final message in _messages.reversed) {
      final options = message.options;
      if (message.type == MessageType.assistant &&
          options != null &&
          options.isNotEmpty) {
        return options.any((option) {
          final normalizedOption = _normalizeText(option);
          return normalizedOption == normalizedMessage ||
              normalizedOption.contains(normalizedMessage);
        });
      }
    }

    return false;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
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
