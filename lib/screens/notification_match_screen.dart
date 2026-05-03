import 'package:flutter/material.dart';
import '../config/supabase_provider.dart';
import '../models/property.dart';
import '../models/profile.dart';
import '../models/habits.dart';
import '../models/match.dart';
import '../utils/colors.dart';
import 'chat_screen.dart';

/// Pantalla dedicada para ver detalles desde una notificación de match/like.
/// Muestra la vista correcta según el tipo:
///   - 'departamento' → características del departamento
///   - 'roommate' / 'profile' → perfil con hábitos del usuario
class NotificationMatchScreen extends StatefulWidget {
  final String senderUserId;
  final String? publicationType; // 'departamento' | 'roommate' | 'profile'
  final String? publicationId;   // ID de la propiedad o búsqueda

  const NotificationMatchScreen({
    Key? key,
    required this.senderUserId,
    this.publicationType,
    this.publicationId,
  }) : super(key: key);

  @override
  State<NotificationMatchScreen> createState() => _NotificationMatchScreenState();
}

class _NotificationMatchScreenState extends State<NotificationMatchScreen> {
  // Estado de carga general
  bool _loading = true;
  String? _error;

  // Datos del remitente
  Profile? _senderProfile;

  // Datos específicos según tipo
  Property? _property;
  Habits? _senderHabits;

  // Estado de botones — pre-computado en initState para evitar spinner infinito
  late Future<List<bool>> _buttonStateFuture;

  bool get _isDepartamento =>
      widget.publicationType == 'departamento' || widget.publicationType == 'property';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Cargar perfil del remitente siempre
      final profile = await SupabaseProvider.databaseService
          .getProfile(widget.senderUserId);

      Property? property;
      Habits? habits;

      if (_isDepartamento && widget.publicationId != null) {
        // Cargar propiedad
        property = await SupabaseProvider.databaseService
            .getProperty(widget.publicationId!);
      } else {
        // Cargar hábitos usando el servicio (incluye conversiones de tipos)
        habits = await SupabaseProvider.databaseService.getHabits(widget.senderUserId);
      }

      if (mounted) {
        setState(() {
          _senderProfile = profile;
          _property = property;
          _senderHabits = habits;
          _loading = false;
        });
        // Pre-computar estado de botones DESPUÉS de cargar datos
        _buttonStateFuture =
            Future.wait([_hasExistingMatch(), _hasIncomingLike()]);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando información: $e';
          _loading = false;
        });
      }
    }
  }

  // ─── Contexto del match ────────────────────────────────────────────────────

  String get _contextType {
    if (_isDepartamento) return 'property';
    if (widget.publicationType == 'roommate') return 'search';
    return 'profile';
  }

  String get _contextId =>
      (widget.publicationId != null && widget.publicationId!.isNotEmpty)
          ? widget.publicationId!
          : widget.senderUserId;

  String get _notifPubType {
    if (_contextType == 'property') return 'departamento';
    if (_contextType == 'search') return 'roommate';
    return 'profile';
  }

  // ─── Lógica de match ───────────────────────────────────────────────────────

  Future<bool> _hasIncomingLike() async {
    final me = SupabaseProvider.client.auth.currentUser?.id;
    if (me == null) return false;
    try {
      final result = await SupabaseProvider.client
          .from('swipes')
          .select()
          .eq('swiper_id', widget.senderUserId)
          .eq('target_user_id', me)
          .eq('direction', 'like')
          .maybeSingle()
          .timeout(const Duration(seconds: 6));
      return result != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasExistingMatch() async {
    final me = SupabaseProvider.client.auth.currentUser?.id;
    if (me == null) return false;
    try {
      final m = await SupabaseProvider.databaseService
          .getExistingMatch(me, widget.senderUserId, _contextType, _contextId)
          .timeout(const Duration(seconds: 6));
      return m != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _returnMatch() async {
    final me = SupabaseProvider.client.auth.currentUser?.id;
    if (me == null) return;

    try {
      final myProfile = await SupabaseProvider.databaseService.getProfile(me);

      // Crear match con contexto correcto
      await SupabaseProvider.databaseService.createMatch(Match(
        userA: me,
        userB: widget.senderUserId,
        compatibilityScore: 75.0,
        contextType: _contextType,
        contextId: _contextId,
      ));

      // Limpiar notificaciones antiguas y crear nueva
      await SupabaseProvider.databaseService.deleteMatchNotificationsFrom(
        recipientUserId: widget.senderUserId,
        senderUserId: me,
      );
      await SupabaseProvider.databaseService.createNotification(
        recipientUserId: widget.senderUserId,
        type: 'match_confirmed',
        senderUserId: me,
        senderName: myProfile?.fullName ?? 'Alguien',
        senderProfileImageUrl: myProfile?.profileImageUrl,
        publicationId: _contextId,
        publicationTitle: _isDepartamento
            ? (_property?.title ?? 'Departamento')
            : (myProfile?.fullName ?? 'Alguien'),
        publicationType: _notifPubType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Match confirmado! Ya puedes enviar mensajes')),
        );
        // Refrescar botones
        setState(() {
          _buttonStateFuture =
              Future.wait([_hasExistingMatch(), _hasIncomingLike()]);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openChat() async {
    final me = SupabaseProvider.client.auth.currentUser?.id;
    if (me == null) return;
    try {
      final m = await SupabaseProvider.databaseService
          .getExistingMatch(me, widget.senderUserId, _contextType, _contextId);
      if (m == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Confirma el match primero')),
          );
        }
        return;
      }
      if (mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatScreen(matchId: m.id)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo abrir chat: $e')));
      }
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text(_isDepartamento ? 'Departamento' : 'Perfil'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tarjeta del remitente ──
                      _buildSenderCard(),
                      const SizedBox(height: 16),
                      // ── Botón de acción ──
                      _buildActionButton(),
                      const SizedBox(height: 24),
                      // ── Contenido principal ──
                      _isDepartamento
                          ? _buildPropertyContent()
                          : _buildRoommateContent(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSenderCard() {
    final name = _senderProfile?.fullName ?? 'Usuario';
    final imageUrl = _senderProfile?.profileImageUrl;
    final bio = _senderProfile?.bio ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return FutureBuilder<List<bool>>(
      future: _buttonStateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.grey),
              ),
            ),
          );
        }

        final hasIncomingLike = snapshot.data?[1] ?? false;

        // Solo mostrar "Devolver match" si hay un like entrante sin confirmar
        if (hasIncomingLike) {
          return _actionBtn(
            label: 'Devolver match',
            icon: Icons.favorite_rounded,
            color: Colors.green,
            onTap: _returnMatch,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  // ── Departamento ────────────────────────────────────────────────────────────

  Widget _buildPropertyContent() {
    final p = _property;
    if (p == null) {
      return const Center(child: Text('No se pudo cargar la propiedad'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(p.title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 14),

        // Badges
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _badge('${p.bedrooms} hab.', Icons.bed_rounded, Colors.pink),
            _badge('\$${p.price.toStringAsFixed(0)}/mes',
                Icons.attach_money_rounded, Colors.green),
            _badge(
                p.includeAlicuota ? 'Incluye alícuota' : 'Sin alícuota',
                Icons.receipt_rounded,
                p.includeAlicuota ? Colors.blue : Colors.grey),
          ],
        ),
        const SizedBox(height: 20),

        // Descripción
        _sectionTitle('Descripción'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(p.description,
              style: TextStyle(
                  fontSize: 15, color: Colors.grey[800], height: 1.6)),
        ),
        const SizedBox(height: 20),

        // Detalles
        _sectionTitle('Detalles del departamento'),
        const SizedBox(height: 8),
        _detailRow(Icons.bed_rounded, 'Habitaciones', '${p.bedrooms}'),
        _detailRow(Icons.monetization_on_outlined, 'Precio mensual',
            '\$${p.price.toStringAsFixed(2)}'),
        _detailRow(Icons.calendar_today_rounded, 'Disponible desde',
            '${p.availableFrom.day}/${p.availableFrom.month}/${p.availableFrom.year}'),
        const SizedBox(height: 20),

        // Ubicación
        _sectionTitle('Ubicación'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.blue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(p.address,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Roommate ────────────────────────────────────────────────────────────────

  Widget _buildRoommateContent() {
    final bio = _senderProfile?.bio ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bio.isNotEmpty) ...[
          _sectionTitle('Acerca de'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(bio,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[800], height: 1.6)),
          ),
          const SizedBox(height: 20),
        ],
        if (_senderHabits != null) ...[
          _sectionTitle('Hábitos y Preferencias'),
          const SizedBox(height: 12),
          _habitBar('Limpieza', _senderHabits!.cleanlinessLevel,
              Icons.cleaning_services_outlined, Colors.blue),
          const SizedBox(height: 10),
          _habitBar('Tolerancia al ruido', _senderHabits!.noiseTolerance,
              Icons.volume_up_outlined, Colors.orange),
          const SizedBox(height: 10),
          _habitBar('Fiestas por semana', _senderHabits!.partyFrequency,
              Icons.celebration_outlined, Colors.purple),
          const SizedBox(height: 10),
          _habitBar('Tolerancia a mascotas', _senderHabits!.petTolerance,
              Icons.pets_outlined, Colors.pink),
          const SizedBox(height: 10),
          _habitBar('Tolerancia a invitados', _senderHabits!.guestsTolerance,
              Icons.people_outlined, Colors.green),
          const SizedBox(height: 10),
          _habitBar('Frecuencia de alcohol', _senderHabits!.alcoholFrequency,
              Icons.local_bar_outlined, Colors.red),
          const SizedBox(height: 10),
          _habitBar('Tiempo en casa', _senderHabits!.timeAtHome,
              Icons.home_outlined, Colors.teal),
          const SizedBox(height: 10),
          _boolHabit('Tiene mascotas', _senderHabits!.pets),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Text('Este usuario aún no cargó sus hábitos',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Widgets helpers ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)));

  Widget _badge(String label, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
      );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _habitBar(String label, int value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value / 10,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$value/10',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );

  Widget _boolHabit(String label, bool value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value
              ? Colors.green.withValues(alpha: 0.05)
              : Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(value ? Icons.check_circle : Icons.cancel,
                color: value ? Colors.green : Colors.red, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600))),
            Text(value ? 'Sí' : 'No',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: value ? Colors.green[700] : Colors.red[700])),
          ],
        ),
      );
}
