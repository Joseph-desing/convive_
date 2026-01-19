import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/property_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
class HomeScreen extends StatefulWidget {
  final String userName;
  
  const HomeScreen({Key? key, this.userName = 'Usuario'}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _currentCardIndex = 0;
  
  // Datos de ejemplo de propiedades
  final List<PropertyData> _properties = [
    PropertyData(
      id: '1',
      images: [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
        'https://images.unsplash.com/photo-1502672260066-6bc35f0af07e?w=800',
      ],
      title: 'Apartamento Moderno en La Mariscal',
      price: 450,
      location: 'La Mariscal, Quito',
      distance: 2.5,
      ownerName: 'María González',
      ownerAge: 24,
      ownerImage: 'https://i.pravatar.cc/150?img=5',
      compatibility: 92,
      isVerified: true,
      bedrooms: 2,
      amenities: ['WiFi', 'Amueblado', 'Cocina'],
      habits: HabitData(
        cleanliness: 9,
        noiseLevel: 7,
        socialLevel: 8,
      ),
    ),
    PropertyData(
      id: '2',
      images: [
        'https://images.unsplash.com/photo-1502672260066-6bc35f0af07e?w=800',
      ],
      title: 'Habitación Acogedora Centro Histórico',
      price: 320,
      location: 'Centro Histórico, Quito',
      distance: 3.8,
      ownerName: 'Carlos Ruiz',
      ownerAge: 26,
      ownerImage: 'https://i.pravatar.cc/150?img=12',
      compatibility: 87,
      isVerified: true,
      bedrooms: 1,
      amenities: ['Mascotas OK', 'Cocina compartida'],
      habits: HabitData(
        cleanliness: 8,
        noiseLevel: 6,
        socialLevel: 9,
      ),
    ),
    PropertyData(
      id: '3',
      images: [
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
      ],
      title: 'Departamento Luminoso en La Carolina',
      price: 520,
      location: 'La Carolina, Quito',
      distance: 1.2,
      ownerName: 'Ana Martínez',
      ownerAge: 23,
      ownerImage: 'https://i.pravatar.cc/150?img=9',
      compatibility: 95,
      isVerified: true,
      bedrooms: 2,
      amenities: ['WiFi', 'Gimnasio', 'Parqueadero'],
      habits: HabitData(
        cleanliness: 10,
        noiseLevel: 8,
        socialLevel: 7,
      ),
    ),
  ];

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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeSection() {
    if (_currentCardIndex >= _properties.length) {
      return _buildNoMoreCards();
    }

    return Stack(
      children: [
        // Cards stack
        for (int i = _properties.length - 1; i >= _currentCardIndex; i--)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: (i - _currentCardIndex) * 10.0,
                bottom: 100,
              ),
              child: PropertyCard(
                property: _properties[i],
                onSwipeLeft: () => _handleSwipe(false),
                onSwipeRight: () => _handleSwipe(true),
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
    return Center(
      child: Text(
        _currentIndex == 1 ? 'Matches' :
        _currentIndex == 2 ? 'Mensajes' : 'Perfil',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleSwipe(bool isLike) {
    setState(() {
      if (_currentCardIndex < _properties.length) {
        // Aquí irá la lógica de guardar el like/dislike
        print(isLike ? 'Like ❤️' : 'Dislike ✗');
        _currentCardIndex++;
      }
    });
  }

  void _handleSuperLike() {
    setState(() {
      if (_currentCardIndex < _properties.length) {
        print('Super Like ⭐');
        _currentCardIndex++;
      }
    });
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