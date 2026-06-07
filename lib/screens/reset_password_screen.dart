import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/deep_link_redirect.dart'
    if (dart.library.html) '../utils/deep_link_redirect_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// PKCE code (legacy, solo funciona en mismo origen). Se mantiene por
  /// compatibilidad con deep links Android que aún manden `code`.
  final String resetToken;

  /// Token hash auto-contenido que NO requiere code_verifier PKCE.
  /// Este es el método principal para web.
  final String tokenHash;

  final String? email;

  /// Cuando el deep link trae error_code (ej: otp_expired), se muestra un
  /// mensaje claro en vez del formulario.
  final String errorCode;

  const ResetPasswordScreen({
    Key? key,
    required this.resetToken,
    this.tokenHash = '',
    this.email,
    this.errorCode = '',
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();

    // Log de diagnóstico
    print('🔍 ResetPasswordScreen initState');
    print('   TokenHash: ${widget.tokenHash.isNotEmpty ? '[present]' : '[empty]'}');
    print('   Code/resetToken: ${widget.resetToken.isNotEmpty ? '[present]' : '[empty]'}');
    print('   Email: ${widget.email ?? '[null]'}');
    print('   ErrorCode: ${widget.errorCode.isNotEmpty ? widget.errorCode : '[none]'}');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que haya al menos un token válido
    if (widget.tokenHash.isEmpty && widget.resetToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: Token de recuperación inválido o expirado'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPassword = _passwordController.text.trim();

      // ─── CASO 1: token_hash presente (método principal, funciona desde cualquier navegador) ───
      if (widget.tokenHash.isNotEmpty) {
        print('🔄 Verificando token_hash con verifyOTP...');

        final response = await SupabaseProvider.client.auth.verifyOTP(
          tokenHash: widget.tokenHash,
          type: OtpType.recovery,
        );

        if (response.session == null) {
          throw Exception(
            'No se pudo verificar el enlace de recuperación. '
            'Es posible que haya expirado.',
          );
        }

        print('✅ token_hash verificado, sesión de recuperación activa');
        print('🔄 Cambiando contraseña...');

        await SupabaseProvider.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        await SupabaseProvider.client.auth.signOut();
        print('✅ Contraseña actualizada y sesión cerrada');
      }
      // ─── CASO 2: Sesión ya activa (preexistente o SDK la creó automáticamente) ───
      else if (SupabaseProvider.client.auth.currentSession != null) {
        print('🔄 Sesión preexistente detectada, cambiando contraseña...');

        await SupabaseProvider.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        await SupabaseProvider.client.auth.signOut();
        print('✅ Contraseña actualizada con sesión preexistente');
      }
      // ─── CASO 3: Solo code PKCE sin sesión → ERROR claro ───
      else {
        print('❌ Solo code PKCE sin token_hash ni sesión activa');
        throw Exception(
          'pkce_verifier_missing: Este enlace de recuperación usa código PKCE '
          'que solo funciona en el mismo navegador donde se solicitó. '
          'Solicita un nuevo enlace de recuperación.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('✅ Contraseña cambiada correctamente. Abriendo la app...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Esperar que se vea el mensaje de éxito
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (kIsWeb) {
        // En web: redirigir el navegador al deep link del APK.
        redirectToDeepLink('com.example.convive_://login');
      } else {
        // En móvil: ir al login internamente.
        context.go('/login');
      }
    } catch (e) {
      print('❌ Error en _resetPassword: $e');

      final errorStr = e.toString().toLowerCase();
      String userMessage = 'Ocurrió un error. Por favor intenta de nuevo.';

      if (errorStr.contains('otp_expired') || errorStr.contains('expired')) {
        userMessage =
            '⏰ El enlace de recuperación ha expirado. Por favor solicita uno nuevo.';
      } else if (errorStr.contains('bad_code_verifier') ||
          errorStr.contains('code challenge') ||
          errorStr.contains('pkce_verifier_missing')) {
        userMessage =
            '🔗 Este enlace no puede usarse desde este navegador. '
            'Por favor solicita un nuevo enlace de recuperación.';
      } else if (errorStr.contains('invalid') || errorStr.contains('token')) {
        userMessage = '❌ El enlace de recuperación es inválido o ya fue usado.';
      } else if (errorStr.contains('password')) {
        userMessage =
            '🔐 La contraseña no cumple los requisitos (mínimo 6 caracteres).';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTokenValid =
        widget.tokenHash.isNotEmpty || widget.resetToken.isNotEmpty;
    final hasError = widget.errorCode.isNotEmpty;

    // Si viene con error_code (ej: otp_expired), mostrar pantalla de error dedicada
    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.go('/forgot-password'),
            color: AppColors.primary,
          ),
          title: const Text(
            'Enlace Expirado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.timer_off_outlined,
                            color: Colors.orange,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enlace expirado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'El enlace expiró o ya fue usado.\nSolicita uno nuevo desde \'Olvidé mi contraseña\'.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/forgot-password'),
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
                        child: const SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Solicitar nuevo enlace',
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
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
          color: AppColors.primary,
        ),
        title: const Text(
          'Restablecer Contraseña',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // TÍTULO
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Crear Nueva Contraseña',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ingresa una contraseña segura para tu cuenta',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // VALIDACIÓN DE TOKEN
                if (!isTokenValid)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_outlined,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Token inválido o expirado. Solicita un nuevo enlace.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.tokenHash.isNotEmpty
                                ? 'Link válido (token_hash). Ingresa tu nueva contraseña.'
                                : 'Link detectado. Ingresa tu nueva contraseña.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // FORM
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NUEVA CONTRASEÑA
                      const Text(
                        'Nueva Contraseña',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es requerida';
                          }
                          if (value.length < 6) {
                            return 'Debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu nueva contraseña',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.primary,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CONFIRMAR CONTRASEÑA
                      const Text(
                        'Confirmar Contraseña',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirma la contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Confirma tu contraseña',
                          hintStyle: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.primary,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
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
                        ),
                      ),
                      const SizedBox(height: 32),

                      // BOTÓN CAMBIAR CONTRASEÑA
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              (isTokenValid && !_isLoading)
                                  ? _resetPassword
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor:
                                Colors.grey.withOpacity(0.5),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: isTokenValid
                                  ? AppColors.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.withOpacity(0.5),
                                        Colors.grey.withOpacity(0.5),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Cambiar Contraseña',
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

                      // AVISO DE SEGURIDAD
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Este enlace expira en 24 horas por seguridad',
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
