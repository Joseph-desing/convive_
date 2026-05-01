import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
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
    if (_profile == null) return;
    
    try {
      final updates = <String, dynamic>{
        'full_name': _nameController.text,
        if (_selectedBirthDate != null)
          'birth_date': _selectedBirthDate!.toIso8601String(),
      };
      
      await SupabaseProvider.databaseService.updateProfile(_profile!.id, updates);
      
      // Actualizar el objeto local
      setState(() {
        _profile = _profile!.copyWith(
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
    if (_profile == null) return;

    try {
      setState(() => _uploadingImage = true);

      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      // Subir a Supabase Storage
      final imageUrl = await SupabaseProvider.storageService.uploadProfileImageXFile(
        userId: _profile!.userId,
        file: image,
      );

      // Actualizar perfil en BD
      await SupabaseProvider.databaseService.updateProfile(
        _profile!.id,
        {'profile_image_url': imageUrl},
      );

      // Actualizar estado local
      setState(() {
        _profile = _profile!.copyWith(profileImageUrl: imageUrl);
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
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          
          return CustomScrollView(
            slivers: [
              // Header con fondo gradiente
              SliverAppBar(
                expandedHeight: 220,
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
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
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
                                      color: Colors.white,
                                      shape: BoxShape.circle,
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
                                                Colors.orange,
                                              ),
                                            ),
                                          )
                                        : const FaIcon(
                                            FontAwesomeIcons.camera,
                                            color: Colors.orange,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                            'Administrador Verificado',
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

                        // Actividad Reciente
                        _buildActivityStatsSection(),
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
            childAspectRatio: 2.2,
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
          Column(
            children: [
              // Nombre
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre Completo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Fecha de Nacimiento
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de Nacimiento',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextField(
                      controller: _birthdateController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        hintText: 'DD/MM/YYYY',
                      ),
                      style: const TextStyle(fontSize: 14),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedBirthDate ?? DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedBirthDate = date;
                            _birthdateController.text = DateFormat('dd/MM/yyyy').format(date);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Email (read-only)
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Sin especificar',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
          childAspectRatio: 2.2,
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
        mainAxisAlignment: MainAxisAlignment.start,
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
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
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
    return SizedBox(
      width: double.infinity,
      child: Material(
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.rightFromBracket,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.rightFromBracket,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cerrar Sesión'),
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
