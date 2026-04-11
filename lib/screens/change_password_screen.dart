import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraseña actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DESCRIPCIÓN ---
                  const Text(
                    'Actualiza tu contraseña de forma segura',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- CONTRASEÑA ACTUAL ---
                  Text(
                    'Contraseña Actual',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    label: 'Contraseña actual',
                    showPassword: _showCurrentPassword,
                    onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Debes ingresar tu contraseña actual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- NUEVA CONTRASEÑA ---
                  Text(
                    'Nueva Contraseña',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    label: 'Mínimo 6 caracteres',
                    showPassword: _showNewPassword,
                    onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Ingresa una nueva contraseña';
                      if (value.length < 6)
                        return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- CONFIRMAR CONTRASEÑA ---
                  Text(
                    'Confirmar Contraseña',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Repite tu nueva contraseña',
                    showPassword: _showConfirmPassword,
                    onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Confirma tu nueva contraseña';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // --- BOTÓN GUARDAR ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Guardar Nueva Contraseña',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- AVISO DE SEGURIDAD ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tu contraseña se encripta de forma segura en nuestros servidores',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required Function() onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.primary,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
