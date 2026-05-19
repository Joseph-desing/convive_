import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../screens/home_screen.dart';

class PropertyCard extends StatefulWidget {
  final PropertyData property;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  }) : super(key: key);

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  int _currentImageIndex = 0;
  Offset _position = Offset.zero;
  bool _isDragging = false;
  double _angle = 0;
  Timer? _autoSlideTimer;

  List<String> get _images => widget.property.images.isNotEmpty
      ? widget.property.images
      : ['https://via.placeholder.com/800x600?text=Sin+imagen'];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (!mounted) return;
    final imageCount = _images.length;
    if (imageCount < 2) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _isDragging) return;
      setState(() {
        final count = _images.length;
        if (count > 1) {
          _currentImageIndex = (_currentImageIndex + 1) % count;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onPanStart: (_) {
        setState(() => _isDragging = true);
      },
      onPanUpdate: (details) {
        setState(() {
          _position += details.delta;
          _angle = _position.dx / screenSize.width * 0.5;
        });
      },
      onPanEnd: (_) {
        setState(() => _isDragging = false);

        final threshold = screenSize.width * 0.3;

        if (_position.dx > threshold) {
          widget.onSwipeRight();
        } else if (_position.dx < -threshold) {
          widget.onSwipeLeft();
        } else {
          setState(() {
            _position = Offset.zero;
            _angle = 0;
          });
        }
      },
      child: Transform.translate(
        offset: _position,
        child: Transform.rotate(
          angle: _angle,
          child: Card(
            elevation: _isDragging ? 15 : 10,
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                _buildCardContent(),
                _buildSwipeIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    if (_currentImageIndex >= _images.length) {
      _currentImageIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final compact = height < 430;
        final medium = height < 540;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Expanded(
                flex: compact ? 4 : 5,
                child: _buildImageSection(
                  compact: compact,
                  ownerAvatarSize: compact ? 42 : 50,
                  ownerNameSize: compact ? 14 : 16,
                ),
              ),
              Expanded(
                flex: compact ? 5 : (medium ? 5 : 4),
                child: _buildDetailsSection(
                  compact: compact,
                  chipLimit: compact ? 2 : (medium ? 3 : 4),
                  horizontalPadding: compact ? 14 : 18,
                  topPadding: compact ? 12 : 16,
                  bottomPadding: compact ? 10 : (medium ? 12 : 16),
                  titleSize: compact ? 17 : 19,
                  priceSize: compact ? 20 : 23,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection({
    required bool compact,
    required double ownerAvatarSize,
    required double ownerNameSize,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _nextImage,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_images[_currentImageIndex]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: compact ? 92 : 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? 12 : 16,
          right: compact ? 12 : 16,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.pink.shade600,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.shade600.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: compact ? 16 : 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.property.compatibility}% Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.property.images.length > 1)
          Positioned(
            top: compact ? 12 : 16,
            left: compact ? 12 : 16,
            right: compact ? 70 : 80,
            child: Row(
              children: List.generate(
                _images.length,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: compact ? 12 : 16,
          left: compact ? 12 : 16,
          right: compact ? 12 : 16,
          child: Row(
            children: [
              Container(
                width: ownerAvatarSize,
                height: ownerAvatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(widget.property.ownerImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.property.ownerName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: ownerNameSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.property.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${widget.property.ownerAge} anos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection({
    required bool compact,
    required int chipLimit,
    required double horizontalPadding,
    required double topPadding,
    required double bottomPadding,
    required double titleSize,
    required double priceSize,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.property.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(widget.property.price),
                      style: TextStyle(
                        fontSize: priceSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/mes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.property.location} - ${widget.property.distance} km',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDetailChip(
                  '${widget.property.bedrooms} dormitorio${widget.property.bedrooms == 1 ? '' : 's'}',
                  Icons.bed_rounded,
                  compact: compact,
                ),
                ...widget.property.amenities.take(chipLimit).map((amenity) {
                  return _buildDetailChip(
                    amenity,
                    Icons.check_rounded,
                    compact: compact,
                  );
                }),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 2 : 4,
              ),
              child: Row(
                children: [
                  _buildHabitIndicator(
                    'Limpieza',
                    widget.property.habits.cleanliness,
                    Icons.cleaning_services_rounded,
                    compact: compact,
                  ),
                  const SizedBox(width: 8),
                  _buildHabitIndicator(
                    'Ruido',
                    widget.property.habits.noiseLevel,
                    Icons.volume_up_rounded,
                    compact: compact,
                  ),
                  const SizedBox(width: 8),
                  _buildHabitIndicator(
                    'Social',
                    widget.property.habits.socialLevel,
                    Icons.people_rounded,
                    compact: compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitIndicator(
    String label,
    int value,
    IconData icon, {
    bool compact = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 6 : 8,
          horizontal: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 16 : 20, color: AppColors.primary),
            SizedBox(height: compact ? 3 : 5),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 2 : 3),
            Text(
              '$value/10',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final hasDecimals = price % 1 != 0;
    return '\$${hasDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0)}';
  }

  Widget _buildDetailChip(
    String label,
    IconData icon, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    if (_position.dx == 0) return const SizedBox.shrink();

    final isRight = _position.dx > 0;
    final opacity = (_position.dx.abs() / 100).clamp(0.0, 1.0);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color:
              (isRight ? Colors.green : Colors.red).withOpacity(opacity * 0.3),
        ),
        child: Center(
          child: Transform.rotate(
            angle: isRight ? -0.5 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isRight ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isRight ? 'LIKE' : 'NOPE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _nextImage() {
    if (!mounted) return;
    final count = _images.length;
    if (count > 1) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % count;
      });
    }
  }
}
