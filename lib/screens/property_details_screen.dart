import 'package:flutter/material.dart';
import '../models/property.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../models/match.dart';
import 'chat_screen.dart';
import '../models/profile.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  Profile? _ownerProfile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    try {
      final profile = await SupabaseProvider.databaseService.getProfile(widget.property.ownerId);
      if (mounted) setState(() { _ownerProfile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _openChatWithOwner() async {
    final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para enviar mensajes')));
      return;
    }

    // Revisar si ya existe match en contexto de esta propiedad
    try {
      final existing = await SupabaseProvider.databaseService.getExistingMatch(currentUserId, widget.property.ownerId, 'property', widget.property.id);
      Match match;
      if (existing != null) {
        match = existing;
      } else {
        // Crear match (compatibility 0 por defecto)
        final m = Match(userA: currentUserId, userB: widget.property.ownerId, compatibilityScore: 0.0, contextType: 'property', contextId: widget.property.id);
        match = await SupabaseProvider.databaseService.createMatch(m);
      }

      // Navegar al chat
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: match.id)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propiedad'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text('${p.bedrooms} hab')),
                const SizedBox(width: 8),
                Chip(label: Text('\$${p.price.toStringAsFixed(2)}')),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: _ownerProfile?.profileImageUrl != null ? NetworkImage(_ownerProfile!.profileImageUrl!) : null,
                  child: _ownerProfile?.profileImageUrl == null ? Text((_ownerProfile?.fullName ?? 'U').substring(0,1).toUpperCase()) : null,
                ),
                title: Text(_ownerProfile?.fullName ?? 'Propietario'),
                subtitle: Text(p.address),
                trailing: ElevatedButton.icon(
                  onPressed: _openChatWithOwner,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Mensaje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Dirección', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(p.address),
            const SizedBox(height: 8),
            Text('Coordenadas: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
