import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import '../utils/colors.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';
import 'complete_profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_screen.dart';
import 'edit_habits_screen.dart';
import 'my_publications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  User? _user;
  Habits? _habits;
  bool _isLoading = false;
  bool _uploadingImage = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_profile == null) return;
    final authUser = SupabaseProvider.authService.getCurrentUser();
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para actualizar tu foto')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await SupabaseProvider.storageService.uploadProfileImageXFile(
        userId: authUser.id,
        file: image,
      );

      await SupabaseProvider.databaseService.updateProfile(
        _profile!.id,
        {'profile_image_url': url},
      );

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo foto: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener usuario actual autenticado
      final authUser = SupabaseProvider.authService.getCurrentUser();
      
      if (authUser == null) {
        setState(() {
          _error = 'No hay usuario autenticado. Por favor inicia sesión.';
          _isLoading = false;
        });
        return;
      }

      // Cargar datos del usuario desde Supabase
      final user = await SupabaseProvider.databaseService.getUser(authUser.id);
      final profile = await SupabaseProvider.databaseService.getProfile(authUser.id);
      final habits = await SupabaseProvider.databaseService.getHabits(authUser.id);

      setState(() {
        _user = user;
        _profile = profile;
        _habits = habits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await SupabaseProvider.authService.signOut();
        if (mounted) {
          // Navegar a la pantalla de login o inicio
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar perfil',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return _buildProfileContent(_profile, _user, _habits);
  }

  Widget _buildProfileContent(Profile? profile, User? user, Habits? habits) {
    if (profile == null) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        _buildHeader(profile),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileInfo(profile, user),
              const SizedBox(height: 16),
              _buildPremiumSection(user),
              const SizedBox(height: 16),
              _buildHabitsSection(habits),
              const SizedBox(height: 16),
              _buildSettingsSection(),
              const SizedBox(height: 100), // Espacio para bottom nav
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Profile profile) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo siempre en gradiente (sin ocupar la foto completa)
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            // Gradiente oscuro en la parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            _buildAvatar(profile),
            // Badge de verificación
            if (profile.verified)
              const Positioned(
                top: 60,
                right: 20,
                child: Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (_uploadingImage)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined),
          tooltip: 'Cambiar foto',
          onPressed: _uploadingImage ? null : _pickAndUploadProfileImage,
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _profile == null
              ? null
              : () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CompleteProfileScreen(
                        userId: _profile!.userId,
                        email: _user?.email ?? '',
                        existingProfile: _profile!,
                        existingHabits: _habits,
                        isEdit: true,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    // Pequeña espera para asegurar que Supabase procese
                    await Future.delayed(const Duration(milliseconds: 300));
                    await _loadUserData();
                  }
                },
        ),
      ],
    );
  }

  Widget _buildAvatar(Profile profile) {
    final hasImage = profile.profileImageUrl != null;
    final width = MediaQuery.of(context).size.width;
    final avatarSize = width * 0.45; // responsive
    final clampedSize = avatarSize.clamp(140.0, 220.0);
    
    // Agregar timestamp para evitar caché de imagen
    final imageUrl = hasImage 
        ? '${profile.profileImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}'
        : null;
    
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          width: clampedSize,
          height: clampedSize,
          child: CircleAvatar(
            backgroundColor: AppColors.primary,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: hasImage
                ? null
                : Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(Profile profile, User? user) {
    final age = profile.birthDate != null
        ? DateTime.now().year - profile.birthDate!.year
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (age != null)
                      Text(
                        '$age años',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (user != null)
                _buildRoleBadge(user.role),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              profile.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            user?.email ?? 'No disponible',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.cake_outlined,
            'Fecha de nacimiento',
            profile.birthDate != null
                ? '${profile.birthDate!.day}/${profile.birthDate!.month}/${profile.birthDate!.year}'
                : 'No especificado',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.wc_outlined,
            'Género',
            _getGenderText(profile.gender),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSection(Habits? habits) {
    if (habits == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mis Hábitos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primary,
                tooltip: 'Editar hábitos',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditHabitsScreen(
                        habits: _habits!,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    await _loadUserData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHabitSlider(
            'Nivel de limpieza',
            habits.cleanlinessLevel,
            Icons.cleaning_services_outlined,
          ),
          const SizedBox(height: 16),
          _buildHabitSlider(
            'Tolerancia al ruido',
            habits.noiseTolerance,
            Icons.volume_up_outlined,
          ),
          const SizedBox(height: 16),
          _buildHabitSlider(
            'Frecuencia de fiestas (días/semana)',
            habits.partyFrequency,
            Icons.celebration_outlined,
          ),
          const SizedBox(height: 16),
          _buildHabitSlider(
            'Tolerancia a invitados',
            habits.guestsTolerance,
            Icons.people_outline,
          ),
          const SizedBox(height: 16),
          _buildHabitSlider(
            'Tiempo en casa',
            habits.timeAtHome,
            Icons.home_outlined,
          ),
          const SizedBox(height: 16),
          _buildHabitSlider(
            'Nivel de responsabilidad',
            habits.responsibilityLevel,
            Icons.verified_user_outlined,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoChip(
            Icons.bedtime_outlined,
            'Horario de sueño',
            '${_formatHour(habits.sleepStart)} - ${_formatHour(habits.sleepEnd)}',
          ),
          const SizedBox(height: 12),
          _buildInfoChip(
            Icons.work_outline,
            'Modo de trabajo',
            _getWorkModeText(habits.workMode),
          ),
          if (habits.pets) ...[
            const SizedBox(height: 12),
            _buildInfoChip(
              Icons.pets_outlined,
              'Tiene mascotas',
              'Sí',
            ),
          ],
          const SizedBox(height: 12),
          _buildHabitSlider(
            'Tolerancia a mascotas',
            habits.petTolerance,
            Icons.pets_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.publish_outlined,
            title: 'Mis publicaciones',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyPublicationsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsTile(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Ayuda y soporte',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacidad',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            onTap: () => _handleLogout(),
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    String text;
    Color color;

    switch (role) {
      case UserRole.student:
        text = 'Estudiante';
        color = AppColors.primary;
        break;
      case UserRole.non_student:
        text = 'Profesional';
        color = Colors.blue;
        break;
      case UserRole.admin:
        text = 'Admin';
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitSlider(String label, int value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value/10',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 10,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(
              value >= 7 ? Colors.green : value >= 4 ? Colors.orange : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? AppColors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No hay perfil disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Completa tu perfil para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _navigateToCompleteProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Crear Perfil',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCompleteProfile() {
    final authUser = SupabaseProvider.authService.getCurrentUser();
    
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No hay usuario autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompleteProfileScreen(
          userId: authUser.id,
          email: authUser.email ?? '',
        ),
      ),
    ).then((_) {
      // Recargar los datos después de completar el perfil
      _loadUserData();
    });
  }

  Widget _buildPremiumSection(User? user) {
    final isPremium = user?.role == 'premium' || user?.role == 'premium+';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFB800),
                ]
              : [
                  AppColors.primary,
                  const Color(0xFFFF1493),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'ConVive Premium+' : 'Hazte Premium+',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isPremium
                            ? 'Disfrutando beneficios exclusivos'
                            : 'Destaca y encuentra más rápido',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPremiumBenefit(
              Icons.star,
              'Publicaciones destacadas',
              'Aparece primero en búsquedas',
            ),
            const SizedBox(height: 12),
            _buildPremiumBenefit(
              Icons.chat,
              'Chats ilimitados',
              'Sin límites de conversaciones',
            ),
            const SizedBox(height: 12),
            _buildPremiumBenefit(
              Icons.visibility,
              'Ver quién te vio',
              'Conoce quién visitó tu perfil',
            ),
            const SizedBox(height: 12),
            _buildPremiumBenefit(
              Icons.flash_on,
              'Match prioritario',
              'Conecta más rápido con roommates',
            ),
            const SizedBox(height: 12),
            _buildPremiumBenefit(
              Icons.block,
              'Sin anuncios',
              'Experiencia limpia y fluida',
            ),
            const SizedBox(height: 20),
            if (!isPremium)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showPremiumDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'Actualizar a Premium+',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Suscripción activa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefit(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                const Color(0xFFFF1493).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ConVive Premium+',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encuentra tu roommate ideal más rápido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildPriceOption(
                '\$9.99',
                'Mensual',
                'Cancela cuando quieras',
                false,
              ),
              const SizedBox(height: 12),
              _buildPriceOption(
                '\$49.99',
                'Anual',
                'Ahorra 58% - \$4.16/mes',
                true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processPremiumPurchase();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Suscribirme',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceOption(
    String price,
    String period,
    String description,
    bool recommended,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? AppColors.primary.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: recommended ? AppColors.primary : AppColors.borderColor,
          width: recommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      period,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: recommended ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: recommended ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _processPremiumPurchase() {
    // Aquí iría la lógica de pago con Stripe/PayPal/etc
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 ¡Bienvenido a Premium+!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getGenderText(Gender? gender) {
    if (gender == null) return 'No especificado';
    switch (gender) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Femenino';
      case Gender.other:
        return 'Otro';
    }
  }

  String _getWorkModeText(WorkMode? workMode) {
    if (workMode == null) return 'No especificado';
    switch (workMode) {
      case WorkMode.remote:
        return 'Remoto';
      case WorkMode.office:
        return 'Presencial';
      case WorkMode.hybrid:
        return 'Híbrido';
    }
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}
