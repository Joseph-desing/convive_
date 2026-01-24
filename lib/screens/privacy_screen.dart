import 'package:flutter/material.dart';
import '../utils/colors.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileVisible = true;
  bool _showEmail = false;
  bool _showPhone = false;
  bool _allowMessages = true;
  bool _showOnlineStatus = true;
  String _whoCanSeeProfile = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacidad',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSection(
              title: 'Visibilidad del perfil',
              children: [
                _buildSwitchTile(
                  icon: Icons.visibility_outlined,
                  title: 'Perfil visible',
                  subtitle: 'Otros usuarios pueden ver tu perfil',
                  value: _profileVisible,
                  onChanged: (value) {
                    setState(() => _profileVisible = value);
                  },
                ),
                const Divider(height: 1),
                _buildOptionTile(
                  icon: Icons.people_outline,
                  title: 'Quién puede ver mi perfil',
                  subtitle: _whoCanSeeProfile,
                  onTap: () => _showVisibilityDialog(),
                  enabled: _profileVisible,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Información de contacto',
              children: [
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Mostrar email',
                  subtitle: 'Visible en tu perfil público',
                  value: _showEmail,
                  onChanged: (value) {
                    setState(() => _showEmail = value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.phone_outlined,
                  title: 'Mostrar teléfono',
                  subtitle: 'Visible en tu perfil público',
                  value: _showPhone,
                  onChanged: (value) {
                    setState(() => _showPhone = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Comunicación',
              children: [
                _buildSwitchTile(
                  icon: Icons.message_outlined,
                  title: 'Permitir mensajes',
                  subtitle: 'Otros usuarios pueden contactarte',
                  value: _allowMessages,
                  onChanged: (value) {
                    setState(() => _allowMessages = value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.circle,
                  title: 'Mostrar estado en línea',
                  subtitle: 'Otros ven cuando estás activo',
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() => _showOnlineStatus = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Datos y seguridad',
              children: [
                _buildActionTile(
                  icon: Icons.download_outlined,
                  title: 'Descargar mis datos',
                  subtitle: 'Obtén una copia de tu información',
                  onTap: () => _showDownloadDataDialog(),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.block_outlined,
                  title: 'Usuarios bloqueados',
                  subtitle: 'Ver y gestionar usuarios bloqueados',
                  onTap: () => _showBlockedUsersDialog(),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  icon: Icons.security_outlined,
                  title: 'Actividad de la cuenta',
                  subtitle: 'Revisa inicios de sesión y actividad',
                  onTap: () => _showAccountActivityDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled ? Colors.grey[400] : Colors.grey[300],
      ),
      onTap: enabled ? onTap : null,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu privacidad es importante. Controla qué información compartes y con quién.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visibilidad del perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Todos'),
              subtitle: const Text('Cualquiera puede ver tu perfil'),
              value: 'Todos',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() => _whoCanSeeProfile = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('Solo estudiantes verificados'),
              subtitle: const Text('Solo usuarios con verificación'),
              value: 'Verificados',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() => _whoCanSeeProfile = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('Nadie'),
              subtitle: const Text('Perfil oculto para todos'),
              value: 'Nadie',
              groupValue: _whoCanSeeProfile,
              onChanged: (value) {
                setState(() => _whoCanSeeProfile = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descargar datos'),
        content: const Text(
          'Recibirás un email con un enlace para descargar todos tus datos en formato JSON. Puede tardar hasta 48 horas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitud enviada. Recibirás un email pronto.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  void _showBlockedUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuarios bloqueados'),
        content: const Text('No tienes usuarios bloqueados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAccountActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actividad de la cuenta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActivityItem(
                'Último inicio de sesión',
                'Hoy, 10:30 AM',
                'Windows • Chrome',
              ),
              const Divider(),
              _buildActivityItem(
                'Inicio de sesión anterior',
                'Ayer, 8:15 PM',
                'Android • App móvil',
              ),
              const Divider(),
              _buildActivityItem(
                'Cambio de contraseña',
                'Hace 3 semanas',
                'Windows • Chrome',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, String device) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            device,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
