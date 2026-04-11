import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/profile.dart';
import '../providers/matching_provider.dart';
import '../config/supabase_provider.dart';
import '../utils/colors.dart';
import '../screens/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Match> _matches = [];
  final Map<String, Profile> _profileCache = {};
  final Map<String, String> _userTypeCache = {}; // 'property' o 'search'
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _initializeTabController() {
    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      if (currentUserId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Cargar matches desde la base de datos
      final matchesData = await SupabaseProvider.databaseService.getUserMatches(currentUserId);
      
      // Precargar perfiles de los matches
      final userIds = matchesData.expand((m) => [m.userA, m.userB])
          .where((id) => id != currentUserId)
          .toSet();
      
      await _preloadProfiles(userIds);
      await _preloadUserTypes(userIds);
      
      if (mounted) {
        setState(() {
          _matches = matchesData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando matches: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadProfiles(Set<String> userIds) async {
    for (final userId in userIds) {
      if (_profileCache.containsKey(userId)) continue;
      try {
        final profile = await SupabaseProvider.databaseService.getProfile(userId);
        if (profile != null) {
          _profileCache[userId] = profile;
        }
      } catch (e) {
        print('⚠️ Error cargando perfil $userId: $e');
      }
    }
  }

  Future<void> _preloadUserTypes(Set<String> userIds) async {
    for (final userId in userIds) {
      if (_userTypeCache.containsKey(userId)) continue;
      try {
        // Verificar si tiene propiedades
        final properties = await SupabaseProvider.databaseService.getUserProperties(userId);
        if (properties.isNotEmpty) {
          _userTypeCache[userId] = 'property';
          continue;
        }

        // Si no tiene propiedades, verificar si tiene búsqueda de compañero/a
        final searches = await SupabaseProvider.databaseService.getUserRoommateSearches(userId);
        if (searches.isNotEmpty) {
          _userTypeCache[userId] = 'search';
          continue;
        }

        // Si no hay datos, marcar como desconocido
        _userTypeCache[userId] = 'unknown';
      } catch (e) {
        _userTypeCache[userId] = 'unknown'; // Evitar suposiciones si falla RLS
      }
    }
  }

  List<Match> _getCompaneroMatches() {
    // Filtra matches por contextType='property' (busca compañero/a para propiedad)
    // Si contextType no existe, usa fallback a userTypeCache
    return _matches.where((m) {
      if (m.contextType != null && m.contextType!.isNotEmpty) {
        return m.contextType == 'property';
      }
      // Fallback: si no hay contextType, usar userTypeCache
      final otherUserId = m.userA == SupabaseProvider.client.auth.currentUser?.id ? m.userB : m.userA;
      return _userTypeCache[otherUserId] == 'property';
    }).toList();
  }

  List<Match> _getDepartamentoMatches() {
    // Filtra matches por contextType='search' (busca departamento)
    // Si contextType no existe, usa fallback a userTypeCache
    return _matches.where((m) {
      if (m.contextType != null && m.contextType!.isNotEmpty) {
        return m.contextType == 'search';
      }
      // Fallback: si no hay contextType, usar userTypeCache
      final otherUserId = m.userA == SupabaseProvider.client.auth.currentUser?.id ? m.userB : m.userA;
      return _userTypeCache[otherUserId] == 'search';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    _initializeTabController();
    
    final companeroMatches = _getCompaneroMatches();
    final departamentoMatches = _getDepartamentoMatches();
    final totalMatches = companeroMatches.length + departamentoMatches.length;

    if (totalMatches == 0) {
      return _buildEmptyState();
    }

    final controller = _tabController!; // Garantizado no-null después de _initializeTabController()

    return Column(
      children: [
        TabBar(
          controller: controller,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text('Compañero/a (${companeroMatches.length})'),  
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apartment, size: 20),
                  const SizedBox(width: 8),
                  Text('Departamento (${departamentoMatches.length})'),
                ],
              ),
            ),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              companeroMatches.isEmpty
                  ? _buildEmptyTab('Aún no tienes matches de compañero/a')
                  : _buildMatchesListTab(companeroMatches),
              departamentoMatches.isEmpty
                  ? _buildEmptyTab('Aún no tienes matches de departamento')
                  : _buildMatchesListTab(departamentoMatches),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aún no tienes matches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Empieza a dar likes en el inicio para encontrar tu compañero/a ideal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Matches',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_matches.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Empieza a dar likes en el inicio para encontrar tu compañero/a ideal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesListTab(List<Match> matches) {
    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    final otherUserId = match.userA == currentUserId ? match.userB : match.userA;
    final otherProfile = _profileCache[otherUserId];
    
    final name = otherProfile?.fullName ?? 'Usuario';
    final imageUrl = otherProfile?.profileImageUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=9C27B0&color=fff';
    final age = _calculateAge(otherProfile?.birthDate);
    final bio = otherProfile?.bio ?? 'Sin descripción';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openChat(match),
          onLongPress: () => _confirmDeleteMatch(match),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar con badge de match
                Stack(
                  children: [
                    Hero(
                      tag: 'profile_${otherUserId}_${match.id}',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Información - Expanded para que ocupe espacio disponible
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$age',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Badges (wrap para evitar overflow en pantallas angostas)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Badge de compatibilidad
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${match.compatibilityScore.toInt()}% Match',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge de contexto (si existe)
                          if (match.contextType != null && match.contextType!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: match.contextType == 'property'
                                    ? Colors.blue.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    match.contextType == 'property'
                                        ? Icons.home
                                        : Icons.search,
                                    color: match.contextType == 'property'
                                        ? Colors.blue.shade700
                                        : Colors.orange.shade700,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      match.contextType == 'property'
                                          ? '📦 Busca compañero/a'
                                          : '🔍 Busca departamento',
                                      style: TextStyle(
                                        color: match.contextType == 'property'
                                            ? Colors.blue.shade700
                                            : Colors.orange.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Badge de tipo de búsqueda (solo si tenemos dato y no hay contexto)
                          if ((match.contextType == null || match.contextType!.isEmpty) &&
                              _userTypeCache[otherUserId] != null && _userTypeCache[otherUserId] != 'unknown')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _userTypeCache[otherUserId] == 'property'
                                    ? Colors.blue.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _userTypeCache[otherUserId] == 'property'
                                        ? Icons.home
                                        : Icons.search,
                                    color: _userTypeCache[otherUserId] == 'property'
                                        ? Colors.blue.shade700
                                        : Colors.orange.shade700,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _userTypeCache[otherUserId] == 'property'
                                          ? 'Busca compañero/a'
                                          : 'Busca depa',
                                      style: TextStyle(
                                        color: _userTypeCache[otherUserId] == 'property'
                                            ? Colors.blue.shade700
                                            : Colors.orange.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Botones de acciones: chat y eliminar - SizedBox para mantener ancho fijo
                SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _openChat(match),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _confirmDeleteMatch(match),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(matchId: match.id),
      ),
    );
  }

  Future<void> _confirmDeleteMatch(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conexión'),
        content: const Text('Esto borrará la conexión y el chat asociado. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseProvider.databaseService.deleteMatch(match.id);
      setState(() {
        _matches.removeWhere((m) => m.id == match.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conexión eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 25;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
