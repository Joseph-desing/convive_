import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../widgets/admin/admin_ui.dart';
import '../config/supabase_provider.dart';
import '../models/index.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _birthdateController;
  bool _isEditing = false;
  Profile? _profile;
  DateTime? _selectedBirthDate;
  bool _loadError = false;
  bool _uploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _birthdateController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final authUser = SupabaseProvider.authService.getCurrentUser();
      print('DEBUG: authUser = $authUser');
      
      if (authUser == null) {
        print('DEBUG: No authenticated user found');
        setState(() {
          _loadError = true;
          _profile = Profile(userId: '', fullName: 'Administrador');
        });
        return;
      }
      
      print('DEBUG: Loading profile for user ${authUser.id}');
      final profile = await SupabaseProvider.databaseService.getProfile(authUser.id);
      print('DEBUG: Profile loaded: $profile');
      
      setState(() {
        if (profile != null) {
          _profile = profile;
          _nameController.text = profile.fullName ?? '';
          if (profile.birthDate != null) {
            _selectedBirthDate = profile.birthDate;
            _birthdateController.text = DateFormat('dd/MM/yyyy').format(profile.birthDate!);
          }
        } else {
          // Create empty profile if not found
          print('DEBUG: Profile is null, creating empty profile');
          _profile = Profile(
            userId: authUser.id,
            fullName: 'Administrador',
          );
          _nameController.text = 'Administrador';
        }
      });
    } catch (e) {
      print('ERROR cargando perfil: $e');
      setState(() {
        _loadError = true;
        _profile = Profile(userId: '', fullName: 'Administrador');
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    try {
      final authUser = SupabaseProvider.authService.getCurrentUser();
      if (authUser == null) return;

      final existingProfile =
          await SupabaseProvider.databaseService.getProfile(authUser.id);
      final updates = <String, dynamic>{
        'full_name': _nameController.text,
        if (_selectedBirthDate != null)
          'birth_date': _selectedBirthDate!.toIso8601String(),
      };

      final savedProfile = existingProfile == null
          ? await SupabaseProvider.databaseService.createProfile(
              Profile(
                userId: authUser.id,
                fullName: _nameController.text,
                birthDate: _selectedBirthDate,
                profileImageUrl: _profile?.profileImageUrl,
              ),
            )
          : existingProfile;

      if (existingProfile != null) {
        await SupabaseProvider.databaseService.updateProfile(
          existingProfile.id,
          updates,
        );
      }

      // Actualizar el objeto local
      setState(() {
        _profile = savedProfile.copyWith(
          fullName: _nameController.text,
          birthDate: _selectedBirthDate,
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      print('ERROR guardando perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _uploadingImage = true);

      final authUser = SupabaseProvider.authService.getCurrentUser();
      if (authUser == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      // Subir a Supabase Storage
      final imageUrl = await SupabaseProvider.storageService.uploadProfileImageXFile(
        userId: authUser.id,
        file: image,
      );
      final versionedImageUrl =
          '$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      final existingProfile =
          await SupabaseProvider.databaseService.getProfile(authUser.id);
      final savedProfile = existingProfile == null
          ? await SupabaseProvider.databaseService.createProfile(
              Profile(
                userId: authUser.id,
                fullName: _nameController.text.isNotEmpty
                    ? _nameController.text
                    : (_profile?.fullName ?? 'Administrador'),
                birthDate: _selectedBirthDate,
                profileImageUrl: versionedImageUrl,
              ),
            )
          : existingProfile;

      // Actualizar perfil en BD
      if (existingProfile != null) {
        await SupabaseProvider.databaseService.updateProfile(
          existingProfile.id,
          {'profile_image_url': versionedImageUrl},
        );
      }

      // Actualizar estado local
      setState(() {
        _profile = savedProfile.copyWith(profileImageUrl: versionedImageUrl);
        _uploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada correctamente')),
      );
    } catch (e) {
      print('ERROR subiendo foto: $e');
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir foto: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUi.background,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          
          return CustomScrollView(
            slivers: [
              // Header con fondo gradiente
              SliverAppBar(
                expandedHeight: 236,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                actions: [
                  IconButton(
                    icon: FaIcon(
                      _isEditing ? FontAwesomeIcons.check : FontAwesomeIcons.pen,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (_isEditing) {
                        await _saveProfileChanges();
                      }
                      setState(() => _isEditing = !_isEditing);
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.75),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.16),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _profile?.profileImageUrl != null && _profile!.profileImageUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: _profile!.profileImageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => 
                                            const FaIcon(FontAwesomeIcons.userTie, color: Colors.orange, size: 50),
                                        errorWidget: (context, url, error) => 
                                            const FaIcon(FontAwesomeIcons.userTie, color: Colors.orange, size: 50),
                                      ),
                                    )
                                  : const FaIcon(
                                      FontAwesomeIcons.userTie,
                                      color: Colors.orange,
                                      size: 50,
                                    ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _uploadingImage ? null : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: _uploadingImage
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const FaIcon(
                                            FontAwesomeIcons.camera,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profile?.fullName ?? 'Administrador',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Administrador',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Contenido
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _profile == null
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Información de Cuenta Editable
                              _buildEditableAccountSection(user),
                              const SizedBox(height: 28),

                              // Seguridad
                              _buildSecuritySection(context),
                        const SizedBox(height: 28),

                        // Botón Cerrar Sesión
                        _buildLogoutButton(context),
                        const SizedBox(height: 32),
                            ],
                          ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableAccountSection(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Cuenta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        
        if (!_isEditing)
          // Vista normal
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.65,
            children: [
              _buildInfoCard(
                icon: FontAwesomeIcons.envelope,
                label: 'Email',
                value: context.watch<AuthProvider>().currentUser?.email ?? 'Sin especificar',
                color: Colors.blue,
              ),
              _buildInfoCard(
                icon: FontAwesomeIcons.cakeCandles,
                label: 'Fecha de Nacimiento',
                value: _profile?.birthDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_profile!.birthDate!)
                    : 'No especificada',
                color: Colors.pink,
              ),
              _buildInfoCard(
                icon: FontAwesomeIcons.calendar,
                label: 'Registrado',
                value: _profile?.createdAt != null
                    ? DateFormat('MMMM yyyy', 'es_ES').format(_profile!.createdAt)
                    : 'No especificado',
                color: Colors.purple,
              ),
              _buildInfoCard(
                icon: FontAwesomeIcons.checkCircle,
                label: 'Estado',
                value: 'Activo',
                color: Colors.green,
              ),
            ],
          )
        else
          // Vista editable
          Container(
            decoration: AdminUi.panelDecoration(),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: AdminUi.inputDecoration(
                    hintText: 'Nombre completo',
                    icon: Icons.badge_outlined,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _birthdateController,
                  decoration: AdminUi.inputDecoration(
                    hintText: 'Fecha de nacimiento',
                    icon: Icons.calendar_today_outlined,
                  ).copyWith(
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AdminUi.muted,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      cancelText: 'CANCELAR',
                      confirmText: 'ACEPTAR',
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: AdminUi.ink,
                            ),
                            dialogBackgroundColor: Colors.white,
                            datePickerTheme: DatePickerThemeData(
                              backgroundColor: Colors.white,
                              headerBackgroundColor: AppColors.primary,
                              headerForegroundColor: Colors.white,
                              todayBorder: const BorderSide(
                                color: AppColors.primary,
                              ),
                              dayForegroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.white;
                                }
                                if (states.contains(MaterialState.disabled)) {
                                  return AdminUi.muted.withOpacity(0.45);
                                }
                                return AdminUi.ink;
                              }),
                              dayBackgroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppColors.primary;
                                }
                                return null;
                              }),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              cancelButtonStyle: TextButton.styleFrom(
                                foregroundColor: AdminUi.ink,
                                backgroundColor: const Color(0xFFF3F4F6),
                                minimumSize: const Size(96, 40),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                              confirmButtonStyle: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(96, 40),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedBirthDate = date;
                        _birthdateController.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AdminUi.panelDecoration(
                    borderColor: Colors.blue.shade200,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 11,
                                color: AdminUi.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'Sin especificar',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AdminUi.ink,
                              ),
                            ),
                          ],
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

  Widget _buildProfileCard(BuildContext context, user) {
    return SizedBox.shrink(); // Removido ya que ahora usamos SliverAppBar
  }

  Widget _buildAdminInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Cuenta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        
        // Grid de información
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.65,
          children: [
            _buildInfoCard(
              icon: FontAwesomeIcons.envelope,
              label: 'Email',
              value: 'admin@convive.com',
              color: Colors.blue,
            ),
            _buildInfoCard(
              icon: FontAwesomeIcons.shieldHalved,
              label: 'Nivel de Acceso',
              value: 'Full Control',
              color: Colors.green,
            ),
            _buildInfoCard(
              icon: FontAwesomeIcons.calendar,
              label: 'Registrado',
              value: 'Enero 2024',
              color: Colors.purple,
            ),
            _buildInfoCard(
              icon: FontAwesomeIcons.checkCircle,
              label: 'Estado',
              value: 'Activo',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FaIcon(icon, size: 10, color: color),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seguridad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildSecurityButton(
          context,
          icon: FontAwesomeIcons.lock,
          title: 'Cambiar Contraseña',
          subtitle: 'Actualiza tu contraseña regularmente',
          color: Colors.red,
          onPressed: () => context.push('/change-password'),
        ),
      ],
    );
  }

  Widget _buildSecurityButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          icon: FontAwesomeIcons.clock,
          label: 'Última acción',
          value: 'Hace 2 horas',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: FontAwesomeIcons.users,
          label: 'Usuarios modificados',
          value: '5 esta semana',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildActivityCard(
          icon: FontAwesomeIcons.comments,
          label: 'Feedback respondido',
          value: '12 pendientes',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: AdminUi.panelDecoration(
            borderColor: Colors.red.shade200,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: AdminUi.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Salir de la cuenta administrativa',
                      style: TextStyle(
                        color: AdminUi.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AdminUi.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.rightFromBracket,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AdminUi.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Seguro que quieres cerrar sesión?',
                style: TextStyle(
                  fontSize: 14,
                  color: AdminUi.muted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                      label: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminUi.ink,
                        backgroundColor: const Color(0xFFF3F4F6),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 14),
                      label: const Text('Salir'),
                      onPressed: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
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
}
