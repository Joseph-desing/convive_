import 'package:flutter/material.dart';
import '../config/supabase_provider.dart';
import '../models/profile.dart';
import '../models/habits.dart';
import '../models/match.dart';
import 'chat_screen.dart';
import '../utils/colors.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Profile? _profile;
  Habits? _habits;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await SupabaseProvider.databaseService.getProfile(widget.userId);
      final habits = await SupabaseProvider.databaseService.getHabits(widget.userId);
      setState(() {
        _profile = profile;
        _habits = habits;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
    return age;
  }

  Future<void> _openChat() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para enviar mensajes')));
      return;
    }

    try {
      final existing = await SupabaseProvider.databaseService.getExistingMatch(currentUserId, widget.userId, 'profile', widget.userId);
      Match match;
      if (existing != null) {
        match = existing;
      } else {
        final m = Match(userA: currentUserId, userB: widget.userId, compatibilityScore: 0.0, contextType: 'profile', contextId: widget.userId);
        match = await SupabaseProvider.databaseService.createMatch(m);
      }
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: match.id)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: ${_error}'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage: _profile?.profileImageUrl != null ? NetworkImage(_profile!.profileImageUrl!) : null,
                            child: _profile?.profileImageUrl == null ? Text((_profile?.fullName ?? 'U').substring(0, 1).toUpperCase()) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(_profile?.fullName ?? 'Usuario', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                    if (_profile?.verified ?? false)
                                      const Icon(Icons.verified, color: Colors.blue, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _profile?.bio ?? '',
                                  style: const TextStyle(color: AppColors.textSecondary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                if (_profile?.birthDate != null)
                                  Text('${_calculateAge(_profile!.birthDate)} años', style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_habits != null) ...[
                        const Text('Hábitos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          Chip(label: Text('Limpieza: ${_habits!.cleanlinessLevel}/10')),
                          Chip(label: Text('Fiesta: ${_habits!.partyFrequency}/10')),
                          Chip(label: Text('Mascotas: ${_habits!.pets ? 'Sí' : 'No'}')),
                        ]),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _openChat,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Mensaje'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
