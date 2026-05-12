import 'package:flutter/material.dart';

import '../config/supabase_provider.dart';
import '../models/profile.dart';
import '../models/property.dart';
import '../utils/colors.dart';

class MapPropertyPreviewScreen extends StatefulWidget {
  final Property property;

  const MapPropertyPreviewScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<MapPropertyPreviewScreen> createState() =>
      _MapPropertyPreviewScreenState();
}

class _MapPropertyPreviewScreenState extends State<MapPropertyPreviewScreen> {
  Profile? _ownerProfile;
  List<String> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseProvider.databaseService.getProfile(widget.property.ownerId),
        SupabaseProvider.databaseService.getPropertyImages(widget.property.id),
      ]);
      if (!mounted) return;
      setState(() {
        _ownerProfile = results[0] as Profile?;
        _images = List<String>.from(results[1] as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Departamento'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOwnerCard(),
            const SizedBox(height: 18),
            _buildImageGallery(),
            const SizedBox(height: 22),
            Text(
              p.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.bed_rounded,
                  label: '${p.bedrooms} hab',
                  color: AppColors.primary,
                ),
                _InfoChip(
                  icon: Icons.attach_money_rounded,
                  label: '\$${p.price.toStringAsFixed(0)}/mes',
                  color: Colors.green,
                ),
                _InfoChip(
                  icon: Icons.receipt_rounded,
                  label: p.includeAlicuota ? 'Incluye alicuota' : 'Sin alicuota',
                  color: p.includeAlicuota ? Colors.blue : Colors.grey,
                ),
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label:
                      '${p.availableFrom.day}/${p.availableFrom.month}/${p.availableFrom.year}',
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Descripcion',
              child: Text(
                p.description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _Section(
              title: 'Ubicacion',
              child: _LocationBox(
                address: p.address,
                coordinates:
                    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: _ownerProfile?.profileImageUrl != null
                ? NetworkImage(_ownerProfile!.profileImageUrl!)
                : null,
            child: _ownerProfile?.profileImageUrl == null
                ? Text(
                    (_ownerProfile?.fullName ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ownerProfile?.fullName ?? 'Propietario',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ownerProfile?.bio ?? 'Sin biografia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_loading) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_images.isEmpty) {
      return Container(
        height: 170,
        decoration: _cardDecoration(),
        child: const Center(
          child: Icon(Icons.apartment_rounded, size: 44, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: PageView.builder(
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _LocationBox extends StatelessWidget {
  final String address;
  final String coordinates;

  const _LocationBox({
    required this.address,
    required this.coordinates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            coordinates,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
