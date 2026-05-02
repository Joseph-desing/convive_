import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../utils/colors.dart';
import '../utils/theme_helper.dart';
import '../widgets/property_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'matches_screen.dart';
import 'complaints_screen.dart';
import 'notifications_screen.dart';
import 'map_posts_screen.dart';
import '../providers/property_provider.dart';
import '../providers/roommate_search_provider.dart';
import '../providers/auth_provider.dart';
import '../models/property.dart';
import '../models/roommate_search.dart';
import '../models/habits.dart';
import '../models/profile.dart';
import '../models/swipe.dart';
import '../models/match.dart';
import '../config/supabase_provider.dart';
import '../services/compatibility_service.dart';
import '../widgets/filter_sheet.dart';
import '../providers/notifications_provider.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  
  const HomeScreen({Key? key, this.userName = 'Usuario'}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _currentCardIndex = 0;
  int _currentRoommateCardIndex = 0;
  List<Property> _properties = [];
  List<RoommateSearch> _roommateSearches = [];
  bool _isLoading = true;
  String? _userFullName; // Nombre completo del perfil
  final Map<String, Profile> _profileCache = {};
  final Map<String, Habits> _habitsCache = {};
  final Map<String, List<String>> _propertyImagesCache = {};
  final Map<String, List<String>> _roommateImagesCache = {};
  TabController? _tabController;

  // Overlay de acción (estrella / corazón)
  bool _overlayVisible = false;
  IconData? _overlayIcon;
  Color _overlayColor = Colors.white;

  void _initializeTabController() {
    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  void _showActionOverlay(IconData icon, Color color, {int durationMs = 800}) {
    setState(() {
      _overlayIcon = icon;
      _overlayColor = color;
      _overlayVisible = true;
    });

    Future.delayed(Duration(milliseconds: durationMs), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<String> _getUserNameFuture() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      
      if (userId != null && userId.isNotEmpty) {
        final response = await SupabaseProvider.client
            .from('profiles')
            .select('full_name')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (response != null) {
          final fullName = response['full_name']?.toString() ?? '';
          if (fullName.isNotEmpty) {
            final nameParts = fullName.split(' ');
            return nameParts.first; // Retornar solo el primer nombre
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }
    
    return 'Usuario'; // Fallback
  }

  String _getUserDisplayName() {
    // Si ya cargamos el nombre del perfil, usarlo
    if (_userFullName != null && _userFullName!.isNotEmpty) {
      final nameParts = _userFullName!.split(' ');
      return nameParts.first; // Retornar solo el primer nombre
    }
    
    // Fallback al email
    try {
      final authProvider = context.read<AuthProvider>();
      final email = authProvider.currentUser?.email ?? '';
      if (email.isNotEmpty) {
        final namePart = email.split('@')[0];
        if (namePart.isNotEmpty) {
          return namePart[0].toUpperCase() + namePart.substring(1);
        }
      }
    } catch (e) {
      //
    }
    
    return 'Usuario';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile().then((_) {
      _loadData();
    });
    
    // Inicializar notificaciones en tiempo real
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationsProvider = context.read<NotificationsProvider>();
      notificationsProvider.loadNotifications();
      print('📬 Cargando notificaciones en HomeScreen...');
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      // Obtener userId directamente de Supabase (más confiable que AuthProvider que podría estar inicializando)
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      
      debugPrint('🔍 Buscando perfil para userId: $userId');
      
      if (userId != null && userId.isNotEmpty) {
        final response = await SupabaseProvider.client
            .from('profiles')
            .select('full_name')
            .eq('user_id', userId)
            .maybeSingle();
        
        debugPrint('📡 Response: $response');
        
        if (response != null && mounted) {
          final fullName = response['full_name']?.toString() ?? '';
          debugPrint('✅ Nombre del perfil cargado: "$fullName"');
          setState(() {
            _userFullName = fullName;
          });
        } else {
          debugPrint('⚠️ No se encontró perfil o está vacío');
        }
      } else {
        debugPrint('⚠️ UserId es null - Probablemente la sesión aún se está inicializando');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      final roommateProvider = Provider.of<RoommateSearchProvider>(context, listen: false);
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      
      await Future.wait([
        propertyProvider.loadProperties(excludeUserId: currentUserId),
        roommateProvider.fetchRoommateSearches(excludeUserId: currentUserId),
      ]);

      final ownerIds = <String>{
        ...propertyProvider.properties.map((p) => p.ownerId),
        ...roommateProvider.searches.map((s) => s.userId),
      }..removeWhere((id) => id.isEmpty);

      // Agregar usuario actual para calcular compatibilidad
      if (currentUserId != null) {
        ownerIds.add(currentUserId);
      }

      await _preloadProfiles(ownerIds);
      await _preloadHabits(ownerIds);
      await _preloadPropertyImages(propertyProvider.properties);
      await _preloadRoommateImages(roommateProvider.searches);
      
      setState(() {
        _properties = propertyProvider.properties;
        _roommateSearches = roommateProvider.searches;
        _isLoading = false;
        print('📊 Datos cargados: ${_properties.length} propiedades, ${_roommateSearches.length} búsquedas roommate');
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
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
      } catch (_) {
        // Si falla alguno, seguimos con el resto
      }
    }
  }

  Future<void> _preloadHabits(Set<String> userIds) async {
    for (final userId in userIds) {
      if (_habitsCache.containsKey(userId)) continue;
      try {
        final habits = await SupabaseProvider.databaseService.getHabits(userId);
        if (habits != null) {
          _habitsCache[userId] = habits;
        }
      } catch (_) {
        // Si falla alguno, seguimos con el resto
      }
    }
  }

  Future<void> _preloadPropertyImages(List<Property> properties) async {
    for (final prop in properties) {
      if (_propertyImagesCache.containsKey(prop.id)) continue;
      try {
        final urls =
            await SupabaseProvider.databaseService.getPropertyImages(prop.id);
        _propertyImagesCache[prop.id] = urls;
      } catch (_) {
        // Si falla alguno, seguimos con el resto
      }
    }
  }

  Future<void> _preloadRoommateImages(List<RoommateSearch> searches) async {
    for (final search in searches) {
      if (search.id == null) continue;
      if (_roommateImagesCache.containsKey(search.id)) continue;
      try {
        // Cargar desde tabla separada (como property_images)
        final urls = await SupabaseProvider.databaseService
            .getRoommateSearchImages(search.id!);
        print('🖼️ Imágenes cargadas para búsqueda ${search.id}: ${urls.length} imágenes');
        _roommateImagesCache[search.id!] = List<String>.from(urls);
      } catch (e) {
        print('❌ Error cargando imágenes para búsqueda ${search.id}: $e');
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _currentIndex == 0 
                    ? _buildSwipeSection() 
                    : _buildPlaceholder(),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                  if (index == 3) {
                    context.push('/chatbot');
                    return;
                  }

                  setState(() => _currentIndex = index);
              },
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
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: ThemeHelper.border(context).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'ConVive',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              FutureBuilder<String>(
                future: _getUserNameFuture(),
                builder: (context, snapshot) {
                  final displayName = snapshot.data ?? widget.userName;
                  return Text(
                    'Hola, $displayName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Tooltip(
                message: 'Filtros',
                child: IconButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<FilterSheetResult>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => FilterSheet(
                        initialShowProperties: true,
                        initialShowSearches: true,
                        initialOnlyMatches: false,
                        initialMinBedrooms: null,
                      ),
                    );
                    if (result != null) {
                      // Navigate to map to show filtered results
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapPostsScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.tune_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: ThemeHelper.secondaryBackground(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Notificaciones',
                child: Consumer<NotificationsProvider>(
                  builder: (context, notificationsProvider, _) {
                    final unreadCount = notificationsProvider.notifications
                        .where((n) => !n.isRead)
                        .length;
                    
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.notifications_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: ThemeHelper.secondaryBackground(context),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    _initializeTabController();
    
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apartment, size: 20),
                  const SizedBox(width: 8),
                  Text('Departamentos (${_properties.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text('Compañero/a (${_roommateSearches.length})'),
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
            controller: _tabController,
            children: [
              _buildPropertiesTab(),
              _buildRoommateSearchesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesTab() {
    if (_properties.isEmpty) {
      return _buildNoMoreCards();
    }

    final displayProperties = _properties.map((prop) => _convertToPropertyData(prop)).toList();

    if (_currentCardIndex >= displayProperties.length) {
      return _buildNoMoreCards();
    }

    final currentProperty = _properties[_currentCardIndex];

    return Stack(
      children: [
        // Cards stack
        for (int i = displayProperties.length - 1; i >= _currentCardIndex; i--)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: (i - _currentCardIndex) * 10.0,
                bottom: 100,
              ),
              child: PropertyCard(
                property: displayProperties[i],
                onSwipeLeft: () => _handleSwipeProperties(false),
                onSwipeRight: () => _handleSwipeProperties(true),
              ),
            ),
          ),
        
        // Overlay de acción
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _overlayVisible ? 1.0 : 0.0,
                child: AnimatedScale(
                  scale: _overlayVisible ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(_overlayIcon ?? Icons.star, color: _overlayColor, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Action buttons con referencia a propiedad actual
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: _buildActionButtonsForProperty(currentProperty),
        ),
      ],
    );
  }

  Widget _buildRoommateSearchesTab() {
    if (_roommateSearches.isEmpty) {
      return _buildNoMoreCards();
    }

    final displayRoommates = _roommateSearches.map((search) => _convertRoommateToPropertyData(search)).toList();

    if (_currentRoommateCardIndex >= displayRoommates.length) {
      return _buildNoMoreCards();
    }

    final currentRoommate = _roommateSearches[_currentRoommateCardIndex];

    return Stack(
      children: [
        // Cards stack
        for (int i = displayRoommates.length - 1; i >= _currentRoommateCardIndex; i--)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: (i - _currentRoommateCardIndex) * 10.0,
                bottom: 100,
              ),
              child: PropertyCard(
                property: displayRoommates[i],
                onSwipeLeft: () => _handleSwipeRoommates(false),
                onSwipeRight: () => _handleSwipeRoommates(true),
              ),
            ),
          ),
        
        // Overlay de acción
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _overlayVisible ? 1.0 : 0.0,
                child: AnimatedScale(
                  scale: _overlayVisible ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(_overlayIcon ?? Icons.star, color: _overlayColor, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Action buttons con referencia a roommate actual
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: _buildActionButtonsForRoommate(currentRoommate),
        ),
      ],
    );
  }

  Widget _buildActionButtonsForProperty(Property property) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.close_rounded,
          color: Colors.red,
          onPressed: () => _handleSwipeProperties(false),
        ),
        _buildActionButton(
          icon: Icons.location_on,
          color: Colors.blue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapPostsScreen(
                  initialLocation: LatLng(
                    property.latitude,
                    property.longitude,
                  ),
                  singleProperty: property,
                ),
              ),
            );
          },
          size: 70,
        ),
        _buildActionButton(
          icon: Icons.favorite_rounded,
          color: Colors.green,
          onPressed: () => _handleSwipeProperties(true),
        ),
      ],
    );
  }

  Widget _buildActionButtonsForRoommate(RoommateSearch roommate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.close_rounded,
          color: Colors.red,
          onPressed: () => _handleSwipeRoommates(false),
        ),
        _buildActionButton(
          icon: Icons.location_on,
          color: Colors.blue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapPostsScreen(
                  initialLocation: LatLng(
                    roommate.latitude ?? 0.0,
                    roommate.longitude ?? 0.0,
                  ),
                  singleRoommate: roommate,
                ),
              ),
            );
          },
          size: 70,
        ),
        _buildActionButton(
          icon: Icons.favorite_rounded,
          color: Colors.green,
          onPressed: () => _handleSwipeRoommates(true),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            color: color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNoMoreCards() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Has visto todas las opciones!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vuelve más tarde para ver nuevas opciones',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Resetear ambos índices
                _currentCardIndex = 0;
                _currentRoommateCardIndex = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Ver de nuevo',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    // Mostrar la pantalla de perfil cuando se selecciona
    if (_currentIndex == 4) {
      return const ProfileScreen();
    }
    
    // Mostrar la pantalla de quejas cuando se selecciona
    if (_currentIndex == 2) {
      return const ComplaintsScreen();
    }
    
    // Mostrar la pantalla de matches
    if (_currentIndex == 1) {
      return const MatchesScreen();
    }
    
    return const Center(
      child: Text(
        'Inicio',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleSwipeProperties(bool isLike) async {
    if (_currentCardIndex >= _properties.length) return;
    
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final property = _properties[_currentCardIndex];
    final targetUserId = property.ownerId;
    final contextType = 'property';
    final contextId = property.id;
    
    setState(() {
      _currentCardIndex++;
    });

    if (!isLike) {
      try {
        await SupabaseProvider.databaseService.createSwipe(
          Swipe(
            swiperId: currentUserId,
            targetUserId: targetUserId,
            direction: SwipeDirection.dislike,
          ),
        );
        print('👎 Dislike en propiedad guardado');
      } catch (e) {
        print('❌ Error guardando dislike: $e');
      }
      return;
    }

    // Like - solo guardar swipe y notificación (sin crear match automático)
    try {
      _showActionOverlay(Icons.favorite_rounded, Colors.green);

      await SupabaseProvider.databaseService.createSwipe(
        Swipe(
          swiperId: currentUserId,
          targetUserId: targetUserId,
          direction: SwipeDirection.like,
        ),
      );
      print('❤️ Like en propiedad guardado');

      // Crear notificación al propietario de la propiedad
      final senderProfile = _profileCache[currentUserId];
      await SupabaseProvider.databaseService.createNotification(
        recipientUserId: targetUserId,
        type: 'like',
        senderUserId: currentUserId,
        senderName: senderProfile?.fullName ?? 'Alguien',
        senderProfileImageUrl: senderProfile?.profileImageUrl,
        publicationId: contextId,
        publicationTitle: property.title,
        publicationType: 'departamento',
      );
      print('⏳ Like enviado - el match solo se crea cuando el otro usuario lo devuelve');
    } catch (e) {
      print('❌ Error en el proceso de like: $e');
    }
  }

  void _handleSwipeRoommates(bool isLike) async {
    if (_currentRoommateCardIndex >= _roommateSearches.length) return;
    
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final search = _roommateSearches[_currentRoommateCardIndex];
    final targetUserId = search.userId;
    final contextType = 'search';
    final contextId = search.id;
    
    // Validar que contextId no sea null
    if (contextId == null || contextId.isEmpty) {
      print('⚠️ ID de búsqueda inválido, no se puede procesar el swipe');
      setState(() {
        _currentRoommateCardIndex++;
      });
      return;
    }
    
    setState(() {
      _currentRoommateCardIndex++;
    });

    if (!isLike) {
      try {
        await SupabaseProvider.databaseService.createSwipe(
          Swipe(
            swiperId: currentUserId,
            targetUserId: targetUserId,
            direction: SwipeDirection.dislike,
          ),
        );
        print('👎 Dislike en búsqueda guardado');
      } catch (e) {
        print('❌ Error guardando dislike: $e');
      }
      return;
    }

    // Like - guardar y verificar si hay match
    try {
      _showActionOverlay(Icons.favorite_rounded, Colors.green);

      await SupabaseProvider.databaseService.createSwipe(
        Swipe(
          swiperId: currentUserId,
          targetUserId: targetUserId,
          direction: SwipeDirection.like,
        ),
      );
      print('❤️ Like en búsqueda guardado');

      // Crear notificación al dueño de la búsqueda
      final senderProfile = _profileCache[currentUserId];
      await SupabaseProvider.databaseService.createNotification(
        recipientUserId: targetUserId,
        type: 'like',
        senderUserId: currentUserId,
        senderName: senderProfile?.fullName ?? 'Alguien',
        senderProfileImageUrl: senderProfile?.profileImageUrl,
        publicationId: contextId,
        publicationTitle: search.title,
        publicationType: 'roommate',
      );
      print('⏳ Like enviado - el match solo se crea cuando el otro usuario lo devuelve');
    } catch (e) {
      print('❌ Error en el proceso de like: $e');
    }
  }

  PropertyData _convertToPropertyData(Property property) {
    try {
      final ownerProfile = _profileCache[property.ownerId];
      final fullName = ownerProfile?.fullName ?? 'Propietario';
      final ownerImage = ownerProfile?.profileImageUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=FF69B4&color=fff';
      final ownerName = fullName;
      final ownerAge = _calculateAge(ownerProfile?.birthDate);
      final verified = ownerProfile?.verified ?? property.isActive;

      final cachedImages = _propertyImagesCache[property.id];
      final imageList = (cachedImages != null && cachedImages.isNotEmpty)
          ? List<String>.from(cachedImages)
          : <String>['https://via.placeholder.com/800x600?text=Departamento'];

      // Calcular compatibilidad real
      final compatibility = _calculateCompatibility(property.ownerId);
      final propertyTitle = property.title;
      final propertyAddress = property.address;
      final propertyPrice = property.price;

      return PropertyData(
        id: property.id,
        images: imageList,
        title: propertyTitle,
        price: propertyPrice,
        location: propertyAddress,
        distance: 0.0, // TODO: Calcular distancia real
        ownerName: ownerName,
        ownerAge: ownerAge,
        ownerImage: ownerImage,
        compatibility: compatibility,
        isVerified: verified,
        bedrooms: 1,
        amenities: [],
        habits: _getHabitDataFromOwner(property.ownerId),
      );
    } catch (e) {
      print('❌ Error en _convertToPropertyData: $e');
      // Retornar PropertyData por defecto
      return PropertyData(
        id: 'error',
        images: ['https://via.placeholder.com/800x600?text=Error'],
        title: 'Error cargando propiedad',
        price: 0.0,
        location: 'Sin ubicación',
        distance: 0.0,
        ownerName: 'Error',
        ownerAge: 0,
        ownerImage: 'https://via.placeholder.com/200',
        compatibility: 0,
        isVerified: false,
        bedrooms: 1,
        amenities: [],
        habits: HabitData(cleanliness: 5, noiseLevel: 5, socialLevel: 5),
      );
    }
  }

  PropertyData _convertRoommateToPropertyData(RoommateSearch search) {
    try {
      final ownerProfile = _profileCache[search.userId];
      final fullName = ownerProfile?.fullName ?? 'Compañero/a';
      final ownerImage = ownerProfile?.profileImageUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=9C27B0&color=fff';
      final ownerName = fullName;
      final ownerAge = _calculateAge(ownerProfile?.birthDate);
      final verified = ownerProfile?.verified ?? (search.status.isNotEmpty);

      // Usar imágenes cacheadas de forma segura
      final searchId = search.id ?? '';
      final cachedImages = searchId.isNotEmpty ? _roommateImagesCache[searchId] : null;
      final imageList = (cachedImages != null && cachedImages.isNotEmpty)
          ? List<String>.from(cachedImages)
          : <String>['https://via.placeholder.com/800x600?text=Compañero'];

      // Calcular compatibilidad real
      final compatibility = _calculateCompatibility(search.userId);
      final searchTitle = search.title;
      final searchAddress = search.address;
      final searchBudget = search.budget;

      return PropertyData(
        id: searchId,
        images: imageList,
        title: searchTitle,
        price: searchBudget,
        location: searchAddress,
        distance: 0.0, // TODO: Calcular distancia real
        ownerName: ownerName,
        ownerAge: ownerAge,
        ownerImage: ownerImage,
        compatibility: compatibility,
        isVerified: verified,
        bedrooms: 1,
        amenities: search.habitsPreferences ?? [],
        habits: _getHabitDataFromOwner(search.userId),
      );
    } catch (e) {
      print('❌ Error en _convertRoommateToPropertyData: $e');
      // Retornar un PropertyData por defecto
      return PropertyData(
        id: 'error',
        images: ['https://via.placeholder.com/800x600?text=Error'],
        title: 'Error cargando búsqueda',
        price: 0.0,
        location: 'Sin ubicación',
        distance: 0.0,
        ownerName: 'Error',
        ownerAge: 0,
        ownerImage: 'https://via.placeholder.com/200',
        compatibility: 0,
        isVerified: false,
        bedrooms: 1,
        amenities: [],
        habits: HabitData(cleanliness: 5, noiseLevel: 5, socialLevel: 5),
      );
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

  int _calculateCompatibility(String otherUserId) {
    try {
      // Obtener hábitos del usuario actual
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      if (currentUserId == null) return 50; // Sin usuario, compatibilidad neutra

      final userHabits = _habitsCache[currentUserId];
      final otherHabits = _habitsCache[otherUserId];

      // Si no hay datos de hábitos, retornar compatibilidad neutra
      if (userHabits == null || otherHabits == null) {
        return 50;
      }

      // Calcular compatibilidad usando el servicio
      return CompatibilityService.calculateCompatibility(userHabits, otherHabits);
    } catch (e) {
      print('❌ Error calculando compatibilidad: $e');
      return 50; // Compatibilidad neutra en caso de error
    }
  }

  HabitData _getHabitDataFromOwner(String ownerId) {
    final habits = _habitsCache[ownerId];
    if (habits == null) {
      // Valores por defecto si no hay hábitos disponibles
      return HabitData(
        cleanliness: 5,
        noiseLevel: 5,
        socialLevel: 5,
      );
    }
    // Copias defensivas para evitar dartx_get en Flutter Web
    final cleanliness = habits.cleanlinessLevel;
    final noiseTolerance = habits.noiseTolerance;
    final partyFrequency = habits.partyFrequency;
    
    return HabitData(
      cleanliness: cleanliness,
      noiseLevel: 10 - noiseTolerance,
      socialLevel: partyFrequency,
    );
  }
}

// Modelos de datos
class PropertyData {
  final String id;
  final List<String> images;
  final String title;
  final double price;
  final String location;
  final double distance;
  final String ownerName;
  final int ownerAge;
  final String ownerImage;
  final int compatibility;
  final bool isVerified;
  final int bedrooms;
  final List<String> amenities;
  final HabitData habits;

  PropertyData({
    required this.id,
    required this.images,
    required this.title,
    required this.price,
    required this.location,
    required this.distance,
    required this.ownerName,
    required this.ownerAge,
    required this.ownerImage,
    required this.compatibility,
    required this.isVerified,
    required this.bedrooms,
    required this.amenities,
    required this.habits,
  });
}

class HabitData {
  final int cleanliness;
  final int noiseLevel;
  final int socialLevel;

  HabitData({
    required this.cleanliness,
    required this.noiseLevel,
    required this.socialLevel,
  });
}