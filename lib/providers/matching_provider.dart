import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';
import '../config/ai_service_provider.dart';

/// Provider para matches y compatibilidad
class MatchingProvider extends ChangeNotifier {
  List<Match> _matches = [];
  List<User> _candidates = [];
  bool _isLoading = false;
  String? _error;

  List<Match> get matches => _matches;
  List<User> get candidates => _candidates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar matches del usuario
  Future<void> loadUserMatches(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches =
          await SupabaseProvider.databaseService.getUserMatches(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Crear match si hay compatibilidad
  Future<void> createMatchIfCompatible({
    required String userId1,
    required String userId2,
    required Map<String, dynamic> habits1,
    required Map<String, dynamic> habits2,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calcular compatibilidad con IA
      final score = await AIServiceProvider.instance
          .calculateCompatibilityScore(
        userId1: userId1,
        userId2: userId2,
        user1Habits: habits1,
        user2Habits: habits2,
      );

      // Si la compatibilidad es > 70, crear match
      if (score > 70.0) {
        final match = Match(
          userA: userId1,
          userB: userId2,
          compatibilityScore: score,
        );
        final createdMatch = await SupabaseProvider.databaseService.createMatch(match);
        _matches.add(createdMatch);
        
        // Crear chat automáticamente para el match
        try {
          await SupabaseProvider.messagesService.getOrCreateChat(createdMatch.id);
          if (kDebugMode) {
            print('✅ Chat creado automáticamente para el match: ${createdMatch.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error creando chat: $e');
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Hacer swipe
  Future<void> swipe({
    required String swiperId,
    required String targetUserId,
    required SwipeDirection direction,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Registrar el swipe
      final swipe = Swipe(
        swiperId: swiperId,
        targetUserId: targetUserId,
        direction: direction,
      );
      await SupabaseProvider.databaseService.createSwipe(swipe);

      // Si es un LIKE, verificar si hay match mutuo
      if (direction == SwipeDirection.like) {
        // Verificar si ya existe match
        final existingMatch = await SupabaseProvider.databaseService
            .getExistingMatch(swiperId, targetUserId);

        if (existingMatch == null) {
          // Verificar si hay swipe mutuo LIKE
          final isMutualLike = await SupabaseProvider.databaseService
              .checkMutualLike(swiperId, targetUserId);

          if (isMutualLike) {
            // ¡MATCH! Crear match automáticamente
            final match = Match(
              userA: swiperId,
              userB: targetUserId,
              compatibilityScore: 80.0, // Score por defecto
            );
            final createdMatch =
                await SupabaseProvider.databaseService.createMatch(match);
            _matches.add(createdMatch);

            // Crear chat automáticamente
            try {
              await SupabaseProvider.messagesService
                  .getOrCreateChat(createdMatch.id);
              if (kDebugMode) {
                print('✅ ¡MATCH! Chat creado: ${createdMatch.id}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error creando chat: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error en swipe: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
