import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final notificationsProvider = Provider.of<NotificationsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSection(
              title: 'Notificaciones',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Recibir notificaciones de la app',
                  value: notificationsProvider.notificationsEnabled,
                  onChanged: (value) {
                    notificationsProvider.setNotificationsEnabled(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Apariencia',
              children: [
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Modo oscuro',
                  subtitle: 'Activar tema oscuro',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setDarkMode(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Cuenta',
              children: [
                _buildOptionTile(
                  icon: Icons.lock_outline,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualiza tu contraseña',
                  onTap: () => _showChangePasswordDialog(),
                ),
                const Divider(height: 1),
                _buildOptionTile(
                  icon: Icons.delete_outline,
                  title: 'Eliminar cuenta',
                  subtitle: 'Borrar permanentemente tu cuenta',
                  onTap: () => _showDeleteAccountDialog(),
                  textColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? AppColors.primary : (isDark ? Colors.grey[600] : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled 
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark ? Colors.grey[600] : Colors.grey),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled 
              ? (isDark ? Colors.grey[400] : Colors.grey[600])
              : (isDark ? Colors.grey[700] : Colors.grey[400]),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(LocaleProvider localeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) {
                localeProvider.setLocale(const Locale('es'));
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _showDeleteAccountDialog() async {
    // Mostrar loading mientras se verifica
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final userId = SupabaseProvider.client.auth.currentUser?.id;
      if (userId == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: usuario no identificado')),
        );
        return;
      }

      // Verificar si puede eliminar la cuenta
      final result = await SupabaseProvider.databaseService.canDeleteAccount(userId);
      final canDelete = result['can_delete'] as bool;
      final reasons = result['reasons'] as List<String>;

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (!canDelete) {
        // Mostrar diálogo de bloqueo
        _showAccountBlockedDialog(reasons);
      } else {
        // Mostrar diálogo de confirmación
        _showDeleteAccountConfirmationDialog();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAccountBlockedDialog(List<String> reasons) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.orange[700],
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No puedes eliminar\ntu cuenta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                  'Lo sentimos, encontramos actividad asociada a tu perfil:',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB84D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final reason in reasons) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.orange[700],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (reason != reasons.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Antes de eliminar tu cuenta, debes:',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Eliminar tus publicaciones de departamentos\n'
                '• Cancelar tus búsquedas de compañero/a\n'
                '• Resolver tus quejas y reportes\n'
                '• Finalizar tus conversaciones activas',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.6,
                ),
              ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar cuenta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y perderás todos tus datos.',
          style: TextStyle(
            color: isDark ? Colors.grey[200] : Colors.grey[800],
            height: 1.5,
          ),
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
                  content: Text('Por favor contacta al soporte para eliminar tu cuenta'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
  }
}
