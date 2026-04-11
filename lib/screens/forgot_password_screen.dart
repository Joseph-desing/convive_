import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final whatsappUrl = Uri.parse(
      'https://wa.me/5491234567890?text=Hola%20ConVive,%20no%20recuerdo%20mi%20email%20and%20necesito%20ayuda%20para%20acceder%20a%20mi%20cuenta',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  Future<void> _openEmail() async {
    final emailUrl = Uri(
      scheme: 'mailto',
      path: 'soporte@convive.com',
      queryParameters: {
        'subject': 'No recuerdo mi email de ConVive',
        'body':
            'Hola, no recuerdo el email con el que me registré en ConVive. ¿Podrías ayudarme?',
      },
    );

    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el cliente de email')),
        );
      }
    }
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TÍTULO ---
              const Text(
                '¿Necesitas ayuda?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige una de nuestras opciones de soporte',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // --- OPCIÓN 1: EMAIL ---
              _buildSupportOption(
                icon: Icons.mail_outline,
                title: 'Enviar Email',
                subtitle: 'soporte@convive.com',
                onTap: _openEmail,
              ),
              const SizedBox(height: 12),

              // --- OPCIÓN 2: WHATSAPP ---
              _buildSupportOption(
                icon: Icons.chat_bubble_outline,
                title: 'Contactar por WhatsApp',
                subtitle: '+54 9 1234 567890',
                onTap: _openWhatsApp,
              ),
              const SizedBox(height: 12),

              // --- OPCIÓN 3: FAQ ---
              _buildSupportOption(
                icon: Icons.help_outline,
                title: 'Ver Preguntas Frecuentes',
                subtitle: 'Resolvemos dudas comunes',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),

              // --- AVISO ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nuestro equipo responde en menos de 24 horas',
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
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // --- LOGO ---
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo2.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- TÍTULO ---
                if (!_emailSent) ...[
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Recuperar Contraseña',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      '¡Correo Enviado!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // --- FORM O SUCCESS MESSAGE ---
                if (!_emailSent) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // --- EMAIL FIELD ---
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El email es requerido';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor ingresa un email válido';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'tu@email.com',
                            hintStyle: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- ENVIAR BOTÓN ---
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendResetEmail,
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
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        'Enviar Enlace de Recuperación',
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
                      ],
                    ),
                  ),
                ] else ...[
                  // --- SUCCESS MESSAGE ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Revisa tu correo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se ha enviado un enlace de recuperación a:\n${_emailController.text}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Por favor revisa tu bandeja de entrada y sigue las instrucciones. Si no ves el email, verifica tu carpeta de spam.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- BOTÓN VOLVER AL LOGIN ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Volver al Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // --- VOLVER AL LOGIN (Siempre visible) ---
                if (!_emailSent)
                  Column(
                    children: [
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '← Volver al Login',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _showSupportOptions,
                          child: const Text(
                            '¿No recuerdas tu email?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
