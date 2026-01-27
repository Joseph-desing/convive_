import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../widgets/property_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'create_roommate_search_screen.dart';
import 'create_property_screen.dart';
import 'messages_screen.dart';
import 'matches_screen.dart';
import '../providers/property_provider.dart';
import '../providers/roommate_search_provider.dart';
import '../models/property.dart';
import '../models/roommate_search.dart';
import '../models/habits.dart';
import '../models/profile.dart';
import '../models/swipe.dart';
import '../models/match.dart';
import '../config/supabase_provider.dart';
import '../services/compatibility_service.dart';
import '../widgets/filter_sheet.dart';
import 'map_posts_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  
  const HomeScreen({Key? key, this.userName = 'Usuario'}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _currentCardIndex = 0;
  List<Property> _properties = [];
  List<RoommateSearch> _roommateSearches = [];
  bool _isLoading = true;
  final Map<String, Profile> _profileCache = {};
  final Map<String, Habits> _habitsCache = {};
  final Map<String, List<String>> _propertyImagesCache = {};
  final Map<String, List<String>> _roommateImagesCache = {};

  // Overlay de acción (estrella / corazón)
  bool _overlayVisible = false;
  IconData? _overlayIcon;
  Color _overlayColor = Colors.white;

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
  void initState() {
    super.initState();
    _loadData();
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
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          
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
              Text(
                'Hola, ${widget.userName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Tooltip(
                message: 'Publicar',
                child: IconButton(
                  onPressed: () {
                    _showPublishMenu(context);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                    backgroundColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Notificaciones',
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeSection() {
    // Mostrar loading mientras carga
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    // Combinar propiedades y búsquedas de roommate
    final List<PropertyData> displayProperties = [];
    
    // Agregar propiedades
    displayProperties.addAll(
      _properties.map((prop) => _convertToPropertyData(prop)).toList()
    );
    
    // Agregar búsquedas de roommate
    displayProperties.addAll(
      _roommateSearches.map((search) => _convertRoommateToPropertyData(search)).toList()
    );

    if (_currentCardIndex >= displayProperties.length) {
      return _buildNoMoreCards();
    }

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
                onSwipeLeft: () => _handleSwipe(false),
                onSwipeRight: () => _handleSwipe(true),
              ),
            ),
          ),
        
        // Overlay de acción (estrella/corazón)
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

        // Action buttons
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close_rounded,
            color: Colors.red,
            onPressed: () => _handleSwipe(false),
          ),
          _buildActionButton(
            icon: Icons.star_rounded,
            color: AppColors.primary,
            onPressed: () => _handleSuperLike(),
            size: 70,
          ),
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: Colors.green,
            onPressed: () => _handleSwipe(true),
          ),
        ],
      ),
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
            '¡Has visto todas las propiedades!',
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
              setState(() => _currentCardIndex = 0);
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
    if (_currentIndex == 3) {
      return const ProfileScreen();
    }
    
    // Mostrar la pantalla de mensajes cuando se selecciona
    if (_currentIndex == 2) {
      return const MessagesScreen();
    }
    
    // Mostrar la pantalla de matches
    if (_currentIndex == 1) {
      return const MatchesScreen();
    }
    
    return const Center(
      child: Text(
        'Perfil',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleSwipe(bool isLike) async {
    if (_currentCardIndex >= _getAllProperties().length) return;
    
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final allProperties = _getAllProperties();
    final currentProperty = allProperties[_currentCardIndex];
    
    // Obtener targetUserId buscando en properties o roommate searches
    String? targetUserId;
    String? contextType;
    String? contextId;
    
    // Buscar en properties
    final property = _properties.where((p) => p.id == currentProperty.id).firstOrNull;
    if (property != null) {
      targetUserId = property.ownerId;
      contextType = 'property';
      contextId = property.id;
      print('🏠 Contexto detectado: PROPERTY (${property.id})');
    } else {
      // Buscar en roommate searches
      final search = _roommateSearches.where((r) => r.id == currentProperty.id).firstOrNull;
      if (search != null) {
        targetUserId = search.userId;
        contextType = 'roommate_search';
        contextId = search.id;
        print('🔍 Contexto detectado: ROOMMATE_SEARCH (${search.id})');
      }
    }
    
    if (targetUserId == null) {
      print('❌ No se pudo determinar el targetUserId');
      return;
    }
    
    setState(() {
      _currentCardIndex++;
    });

    if (!isLike) {
      // Solo guardar el dislike sin verificar match
      try {
        await SupabaseProvider.databaseService.createSwipe(
          Swipe(
            swiperId: currentUserId,
            targetUserId: targetUserId,
            direction: SwipeDirection.dislike,
          ),
        );
        print('👎 Dislike guardado');
      } catch (e) {
        print('❌ Error guardando dislike: $e');
      }
      return;
    }

    // Like - guardar y verificar si hay match
    try {
      // Mostrar corazón como feedback inmediato
      _showActionOverlay(Icons.favorite_rounded, Colors.green);

      // Guardar el swipe
      await SupabaseProvider.databaseService.createSwipe(
        Swipe(
          swiperId: currentUserId,
          targetUserId: targetUserId,
          direction: SwipeDirection.like,
        ),
      );
      print('❤️ Like guardado');

      // Crear match incluso si solo tú diste like (mostrar conexión al receptor)
      final existingMatch = await SupabaseProvider.databaseService
          .getExistingMatch(currentUserId, targetUserId, contextType, contextId);

      if (existingMatch == null) {
        print('🎉 ¡MATCH/CONEXIÓN CREADA!');

        // Calcular compatibilidad
        final compatibility = _calculateCompatibility(targetUserId);

        // Crear el match con contexto
        final match = await SupabaseProvider.databaseService.createMatch(
          Match(
            userA: currentUserId,
            userB: targetUserId,
            compatibilityScore: compatibility.toDouble(),
            contextType: contextType ?? 'general',
            contextId: contextId,
          ),
        );

        // Crear chat automáticamente
        try {
          await SupabaseProvider.messagesService.getOrCreateChat(match.id);
          print('✅ Chat creado automáticamente');
        } catch (e) {
          print('⚠️ Error creando chat: $e');
        }

        // No mostrar diálogo
      } else {
        print('ℹ️ Match ya existente, no se duplica');
      }
    } catch (e) {
      print('❌ Error en el proceso de like: $e');
    }
  }

  List<PropertyData> _getAllProperties() {
    final List<PropertyData> all = [];
    all.addAll(_properties.map((p) => _convertToPropertyData(p)));
    all.addAll(_roommateSearches.map((r) => _convertRoommateToPropertyData(r)));
    print('📋 _getAllProperties: ${_properties.length} propiedades + ${_roommateSearches.length} roommate = ${all.length} total');
    return all;
  }

  void _showMatchDialog(String otherUserId, int compatibility) {
    final otherProfile = _profileCache[otherUserId];
    final name = otherProfile?.fullName ?? 'Usuario';
    final imageUrl = otherProfile?.profileImageUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=9C27B0&color=fff';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final maxH = MediaQuery.of(context).size.height * 0.85;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: SizedBox(
            height: maxH,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Conexión encontrada!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tú y $name son compatibles para compartir depa o habitación',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$compatibility% Compatible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Seguir viendo',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _currentIndex = 1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Ver match',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSuperLike() {
    () async {
      if (_currentCardIndex >= _getAllProperties().length) return;

      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final allProperties = _getAllProperties();
      final currentProperty = allProperties[_currentCardIndex];

      String? targetUserId;
      String? contextType;
      String? contextId;

      final property = _properties.where((p) => p.id == currentProperty.id).firstOrNull;
      if (property != null) {
        targetUserId = property.ownerId;
        contextType = 'property';
        contextId = property.id;
      } else {
        final search = _roommateSearches.where((r) => r.id == currentProperty.id).firstOrNull;
        if (search != null) {
          targetUserId = search.userId;
          contextType = 'roommate_search';
          contextId = search.id;
        }
      }

      if (targetUserId == null) return;

      setState(() => _currentCardIndex++);

      // Mostrar estrella como feedback inmediato
      _showActionOverlay(Icons.star_rounded, AppColors.primary);

      try {
        // Guardar super-like (se almacena como 'like' en la tabla)
        await SupabaseProvider.databaseService.createSuperLike(currentUserId, targetUserId);
        print('⭐ Super-like enviado');

        // Verificar si el otro ya te había dado like
        final otherLiked = await SupabaseProvider.databaseService.hasSwipedLikeOrSuper(targetUserId, currentUserId);

        if (otherLiked) {
          final existingMatch = await SupabaseProvider.databaseService
              .getExistingMatch(currentUserId, targetUserId, contextType, contextId);

          if (existingMatch == null) {
            final compatibility = _calculateCompatibility(targetUserId);
            final match = await SupabaseProvider.databaseService.createMatch(
              Match(
                userA: currentUserId,
                userB: targetUserId,
                compatibilityScore: compatibility.toDouble(),
                contextType: contextType ?? 'general',
                contextId: contextId,
              ),
            );

            // Crear chat y enviar mensaje automático
            try {
              final chat = await SupabaseProvider.messagesService.getOrCreateChat(match.id);
              await SupabaseProvider.messagesService.sendMessage(
                chatId: chat.id,
                senderId: currentUserId,
                content: 'Estoy muy interesado/a',
              );
              print('✉️ Mensaje automático enviado tras super-like + match');
            } catch (e) {
              print('⚠️ Error creando chat/enviando mensaje automático: $e');
            }

            _showMatchDialog(targetUserId, _calculateCompatibility(targetUserId));
          } else {
            print('ℹ️ Match ya existente tras super-like');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Has enviado un Super-like ⭐'),
            duration: Duration(seconds: 2),
          ));
        }
      } catch (e) {
        print('❌ Error en super-like: $e');
      }
    }();
  }

  PropertyData _convertToPropertyData(Property property) {
    final ownerProfile = _profileCache[property.ownerId];
    final ownerImage = ownerProfile?.profileImageUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(ownerProfile?.fullName ?? 'Usuario')}&background=FF69B4&color=fff';
    final ownerName = ownerProfile?.fullName ?? 'Propietario';
    final ownerAge = _calculateAge(ownerProfile?.birthDate);
    final verified = ownerProfile?.verified ?? property.isActive;

    final cachedImages = _propertyImagesCache[property.id];
    final imageList = (cachedImages != null && cachedImages.isNotEmpty)
        ? List<String>.from(cachedImages)
        : <String>['https://via.placeholder.com/800x600?text=${Uri.encodeComponent(property.title)}'];

    // Calcular compatibilidad real
    final compatibility = _calculateCompatibility(property.ownerId);

    return PropertyData(
      id: property.id,
      images: imageList,
      title: property.title,
      price: property.price,
      location: property.address,
      distance: 0.0, // TODO: Calcular distancia real
      ownerName: ownerName,
      ownerAge: ownerAge,
      ownerImage: ownerImage,
      compatibility: compatibility,
      isVerified: verified,
      bedrooms: 1, // TODO: Agregar a modelo Property
      amenities: [], // TODO: Agregar a modelo Property
      habits: _getHabitDataFromOwner(property.ownerId),
    );
  }

  PropertyData _convertRoommateToPropertyData(RoommateSearch search) {
    final ownerProfile = _profileCache[search.userId];
    final ownerImage = ownerProfile?.profileImageUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(ownerProfile?.fullName ?? 'User')}&background=9C27B0&color=fff';
    final ownerName = ownerProfile?.fullName ?? 'Buscando Compañero/a';
    final ownerAge = _calculateAge(ownerProfile?.birthDate);
    final verified = ownerProfile?.verified ?? search.status == 'active';

    // Usar imágenes cacheadas con copia defensiva para evitar dartx_get
    final cachedImages = search.id != null ? _roommateImagesCache[search.id] : null;
    final imageList = (cachedImages != null && cachedImages.isNotEmpty)
        ? List<String>.from(cachedImages)
        : <String>['https://via.placeholder.com/800x600?text=${Uri.encodeComponent(search.title)}'];

    // Calcular compatibilidad real
    final compatibility = _calculateCompatibility(search.userId);

    return PropertyData(
      id: search.id ?? '',
      images: imageList,
      title: search.title,
      price: search.budget,
      location: search.address,
      distance: 0.0, // TODO: Calcular distancia real
      ownerName: ownerName,
      ownerAge: ownerAge,
      ownerImage: ownerImage,
      compatibility: compatibility,
      isVerified: verified,
      bedrooms: 1,
      amenities: search.habitsPreferences,
      habits: _getHabitDataFromOwner(search.userId),
    );
  }

  void _showPublishMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Qué quieres publicar?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              context,
              icon: Icons.home_work,
              title: 'Publicar Propiedad',
              description: 'Tengo un cuarto para alquilar',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePropertyScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              context,
              icon: Icons.group_add,
              title: 'Buscar Roommate',
              description: 'Necesito un compañero/a',
              gradient: AppColors.primaryGradient,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRoommateSearchScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
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