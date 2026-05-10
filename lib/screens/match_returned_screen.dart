import 'package:flutter/material.dart';
import '../config/supabase_provider.dart';
import '../models/profile.dart';
import '../models/habits.dart';
import '../models/match.dart';
import '../utils/colors.dart';
import 'chat_screen.dart';

/// Pantalla que se muestra cuando alguien te devuelve el match (match_confirmed).
/// Muestra el perfil de la persona + botón directo al chat.
class MatchReturnedScreen extends StatefulWidget {
  /// Usuario que devolvió el match
  final String senderUserId;

  /// Tipo de publicación: 'departamento' | 'roommate' | 'profile'
  final String? publicationType;

  /// ID de la publicación (propiedad o búsqueda de roommate)
  final String? publicationId;

  /// Nombre del remitente (pre-cargado desde la notificación)
  final String? senderName;

  /// Foto del remitente (pre-cargada desde la notificación)
  final String? senderImageUrl;

  const MatchReturnedScreen({
    Key? key,
    required this.senderUserId,
    this.publicationType,
    this.publicationId,
    this.senderName,
    this.senderImageUrl,
  }) : super(key: key);

  @override
  State<MatchReturnedScreen> createState() => _MatchReturnedScreenState();
}

class _MatchReturnedScreenState extends State<MatchReturnedScreen>
    with TickerProviderStateMixin {
  Profile? _senderProfile;
  Habits? _senderHabits;
  Match? _existingMatch;

  bool _loading = true;
  String? _error;

  late AnimationController _celebrationController;
  late AnimationController _cardController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Helpers de contexto ─────────────────────────────────────────────────────

  String get _contextType {
    final t = widget.publicationType;
    if (t == 'departamento' || t == 'property') return 'property';
    if (t == 'roommate') return 'search';
    return 'profile';
  }

  String get _contextId {
    final id = widget.publicationId;
    return (id != null && id.isNotEmpty) ? id : widget.senderUserId;
  }

  bool get _isDepartamento => _contextType == 'property';

  // ─── Ciclo de vida ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _loadData();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final me = SupabaseProvider.client.auth.currentUser?.id;

      final profile = await SupabaseProvider.databaseService
          .getProfile(widget.senderUserId);

      Habits? habits;
      try {
        habits = await SupabaseProvider.databaseService
            .getHabits(widget.senderUserId);
      } catch (_) {}

      Match? match;
      if (me != null) {
        try {
          match = await SupabaseProvider.databaseService
              .getExistingMatch(me, widget.senderUserId, _contextType, _contextId)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _senderProfile = profile;
          _senderHabits = habits;
          _existingMatch = match;
          _loading = false;
        });

        // Disparar animaciones al cargar
        _celebrationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _cardController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar el perfil';
          _loading = false;
        });
      }
    }
  }

  // ─── Acciones ────────────────────────────────────────────────────────────────

  Future<void> _openChat() async {
    final me = SupabaseProvider.client.auth.currentUser?.id;
    if (me == null) return;

    // Intentar buscar match si aún no lo tenemos
    Match? match = _existingMatch;
    if (match == null) {
      try {
        match = await SupabaseProvider.databaseService.getExistingMatch(
            me, widget.senderUserId, _contextType, _contextId);
      } catch (_) {}
    }

    if (match == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se encontró el chat — intenta recargar'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(matchId: match!.id)),
      );
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '¡Match confirmado!',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Encabezado celebración ──
                      _buildCelebrationHeader(),
                      const SizedBox(height: 24),

                      // ── Tarjeta del perfil ──
                      SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildProfileCard(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Tipo de publicación ──
                      if (widget.publicationType != null)
                        SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildPublicationBadge(),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Hábitos (si existen) ──
                      if (_senderHabits != null && !_isDepartamento)
                        SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildHabitsCard(),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // ── Botón Ir al chat ──
                      SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildChatButton(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Volver ──
                      SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Volver a notificaciones',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ── Encabezado animado ───────────────────────────────────────────────────────

  Widget _buildCelebrationHeader() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.9),
              const Color(0xFF2E7D32).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icono central
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('💚', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Tienes un match!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.senderName ?? 'Alguien'} te devolvió el match.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Ya pueden enviarse mensajes 🎉',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta perfil ───────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    final name = _senderProfile?.fullName ?? widget.senderName ?? 'Usuario';
    final imageUrl = _senderProfile?.profileImageUrl ?? widget.senderImageUrl;
    final bio = _senderProfile?.bio;

    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitialAvatar(initials),
                    ),
                  )
                : _buildInitialAvatar(initials),
          ),
          const SizedBox(height: 14),

          // Nombre
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (_senderProfile?.verified == true) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Colors.blue, size: 22),
              ],
            ],
          ),

          // Bio
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                bio,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Badge publicación ────────────────────────────────────────────────────────

  Widget _buildPublicationBadge() {
    final isDep = _isDepartamento;
    final label = isDep ? '🏠 Departamento' : '👤 Buscando Roommate';
    final color = isDep ? Colors.orange : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              )),
        ],
      ),
    );
  }

  // ── Hábitos ──────────────────────────────────────────────────────────────────

  Widget _buildHabitsCard() {
    final h = _senderHabits!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hábitos y preferencias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          _habitRow('Limpieza', h.cleanlinessLevel, Icons.cleaning_services_outlined, Colors.blue),
          _habitRow('Ruido', h.noiseTolerance, Icons.volume_up_outlined, Colors.orange),
          _habitRow('Fiestas', h.partyFrequency, Icons.celebration_outlined, Colors.purple),
          _habitRow('Mascotas', h.petTolerance, Icons.pets_outlined, Colors.pink),
          _habitRow('Invitados', h.guestsTolerance, Icons.people_outlined, Colors.green),
          _boolRow('Tiene mascotas', h.pets),
        ],
      ),
    );
  }

  Widget _habitRow(String label, int value, IconData icon, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 10,
                    minHeight: 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$value/10',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _boolRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Text(
            value ? 'Sí' : 'No',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: value ? Colors.green[700] : Colors.red[700]),
          ),
        ],
      ),
    );
  }

  // ── Botón chat ───────────────────────────────────────────────────────────────

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _openChat,
        icon: const Icon(Icons.chat_bubble_rounded, size: 22),
        label: const Text(
          'Ir al chat',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }

  // ── Estado de error ─────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reintentar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
