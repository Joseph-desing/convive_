import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';

/// Provider para datos del usuario
class UserProvider extends ChangeNotifier {
  User? _user;
  Profile? _profile;
  Habits? _habits;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  Habits? get habits => _habits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar usuario completo (User + Profile + Habits)
  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await SupabaseProvider.databaseService.getUser(userId);
      _profile = await SupabaseProvider.databaseService.getProfile(userId);
      _habits = await SupabaseProvider.databaseService.getHabits(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualizar perfil
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_profile == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseProvider.databaseService
          .updateProfile(_profile!.id, updates);
      _profile = _profile!.copyWith(
        fullName: updates['full_name'] ?? _profile!.fullName,
        bio: updates['bio'] ?? _profile!.bio,
        profileImageUrl:
            updates['profile_image_url'] ?? _profile!.profileImageUrl,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Actualizar hábitos
  Future<void> updateHabits(Map<String, dynamic> updates) async {
    if (_habits == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseProvider.databaseService
          .updateHabits(_habits!.id, updates);
      _habits = _habits!.copyWith(
        cleanlinessLevel: updates['cleanliness_level'] ?? _habits!.cleanlinessLevel,
        noiseTolerance: updates['noise_tolerance'] ?? _habits!.noiseTolerance,
        partyFrequency: updates['party_frequency'] ?? _habits!.partyFrequency,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
