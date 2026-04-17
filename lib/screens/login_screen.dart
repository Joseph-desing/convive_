import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart'; // Asegúrate de que esto exista
import '../providers/auth_provider.dart';
import '../models/user.dart'; // A veces no es necesario importar el modelo aquí si se usa el provider
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  // CONTROLADORES
  final _emailController = TextEditingController(); // FALTABA ESTE
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false; // Para evitar múltiples clics

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            // Centrado para mejor apariencia en tablets/web
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- LOGO DE LA APP ---
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
                    const SizedBox(height: 16),

                    // --- TÍTULO ---
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'ConVive',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? '¡Bienvenido de vuelta!' : 'Crea tu cuenta',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- CAMPOS DE TEXTO ---
                    if (!_isLogin) ...[
                      _buildTextField(
                          controller: _nameController,
                          label: 'Nombre completo',
                          hint: 'Juan Pérez',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'El nombre es obligatorio';
                            return null;
                          }),
                      const SizedBox(height: 14),
                    ],

                    _buildTextField(
                        controller: _emailController,
                        label: 'Correo electrónico',
                        hint: 'tu@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !value.contains('@'))
                            return 'Email inválido';
                          return null;
                        }),
                    const SizedBox(height: 14),

                    _buildTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.length < 6)
                            return 'Mínimo 6 caracteres';
                          return null;
                        }),
                    const SizedBox(height: 8),

                    // --- OLVIDÉ CONTRASEÑA ---
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // --- CHECKBOX TÉRMINOS ---
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) =>
                                setState(() => _acceptTerms = value!),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Acepto los ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'términos y condiciones',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _showTermsAndConditions,
                                    ),
                                    const TextSpan(
                                      text: ' y ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'política de privacidad',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = _showPrivacyPolicy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // --- BOTÓN PRINCIPAL ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
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
                                : Text(
                                    _isLogin
                                        ? 'Iniciar Sesión'
                                        : 'Crear Cuenta',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- SEPARADOR ---
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o continúa con',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- BOTÓN GOOGLE MEJORADO ---
                    _buildSocialButton(),

                    const SizedBox(height: 24),

                    // --- SWITCH LOGIN/REGISTRO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? '¿No tienes cuenta?'
                              : '¿Ya tienes cuenta?',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState
                                  ?.reset(); // Limpia errores al cambiar
                            });
                          },
                          child: Text(
                            _isLogin ? 'Regístrate' : 'Inicia sesión',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _onGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí usamos una imagen de red oficial para el logo
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.public, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuar con Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onGoogleSignIn() {
    final authProvider = context.read<AuthProvider>();
    authProvider.signInWithGoogle();
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    try {
      if (_isLogin) {
        // --- LOGICA LOGIN ---
        await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        if (!authProvider.isAuthenticated) {
          throw Exception("Error de autenticación");
        }

        if (!authProvider.isEmailVerified) {
          context.go('/email-verification?email=${Uri.encodeComponent(_emailController.text.trim())}');
          return;
        }
        
        // Si el email está verificado, ir al home
        context.go('/home');
      } else {
        // --- LOGICA REGISTRO ---
        // Aquí pasamos el nombre explícitamente
        if (kDebugMode) {
          print("Registrando usuario: ${_nameController.text.trim()}");
        }

        await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(), // <--- ESTO SE ENVÍA AQUÍ
          role: UserRole.student,
        );

        if (!mounted) return;

        context.go('/email-verification?email=${Uri.encodeComponent(_emailController.text.trim())}');
      }
    } catch (e) {
      if (!mounted) return;

      // --- MEJORAR MENSAJES DE ERROR ---
      String errorMessage = "Ocurrió un error";

      final errorStr = e.toString().toLowerCase();

      // Debug: mostrar el error completo para análisis
      if (kDebugMode) {
        print('Error capturado: $e');
        print('Error string: $errorStr');
      }

      // Detectar errores específicos
      if (errorStr.contains('invalid login') ||
          errorStr.contains('invalid password') ||
          errorStr.contains('invalid_credentials') ||
          errorStr.contains('invalid credentials')) {
        errorMessage = '❌ Contraseña incorrecta o email no registrado';
      } else if (errorStr.contains('email') && errorStr.contains('already')) {
        errorMessage = '⚠️ Este email ya está registrado';
      } else if (errorStr.contains('password')) {
        errorMessage = '🔐 La contraseña debe tener al menos 6 caracteres';
      } else if (errorStr.contains('network') || errorStr.contains('timeout')) {
        errorMessage = '🌐 Error de conexión. Verifica tu internet';
      } else if (errorStr.contains('user')) {
        errorMessage = '👤 Usuario no encontrado';
      } else if (errorStr.contains('already exists')) {
        errorMessage = '⚠️ Este email ya está registrado';
      } else if (authProvider.error != null &&
          authProvider.error!.isNotEmpty) {
        errorMessage = authProvider.error!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                // --- HEADER CON GRADIENTE (SIN PADDING HORIZONTAL) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 28),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ConVive - Plataforma de Compañeros de Vivienda',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- CONTENIDO EN FONDO BLANCO ---
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTermsSection(
                            icon: Icons.check_circle_outline,
                            title: '1. Aceptación de los Términos',
                            content:
                                'Al crear una cuenta en ConVive, aceptas estos términos en su totalidad. ConVive es una plataforma para conectar estudiantes y profesionales en búsqueda de compañeros/as de vivienda compatibles.',
                          ),
                          _buildTermsSection(
                            icon: Icons.smart_toy_outlined,
                            title: '2. Servicio de Compatibilidad IA',
                            content:
                                'ConVive utiliza algoritmos de inteligencia artificial para sugerirte compañeros/as de vivienda basados en tus hábitos de vida, preferencias y necesidades. Los matches no garantizan compatibilidad total.',
                          ),
                          _buildTermsSection(
                            icon: Icons.person_outline,
                            title: '3. Información de Perfil y Hábitos',
                            content:
                                'Eres responsable de proporcionar información honesta y precisa sobre tus hábitos. La desinformación puede resultar en la suspensión de tu cuenta.',
                          ),
                          _buildTermsSection(
                            icon: Icons.home_outlined,
                            title: '4. Propiedades y Publicaciones',
                            content:
                                'Si publicas una propiedad, garantizas que tienes derecho a ofrecerla. Las imágenes deben ser de la propiedad real y estar actualizadas.',
                          ),
                          _buildTermsSection(
                            icon: Icons.chat_outlined,
                            title: '5. Comunicación entre Usuarios',
                            content:
                                'Prohíbe acoso, spam, suplantación y compartir datos financieros. Cualquier violación puede resultar en baneo permanente.',
                          ),
                          _buildTermsSection(
                            icon: Icons.handshake_outlined,
                            title: '6. No Somos Agentes Inmobiliarios',
                            content:
                                'ConVive es únicamente una plataforma de conexión. Todas las negociaciones son responsabilidad de los usuarios.',
                          ),
                          _buildTermsSection(
                            icon: Icons.location_on_outlined,
                            title: '7. Ubicación y Privacidad',
                            content:
                                'Tu ubicación exacta nunca será compartida públicamente. Se usa solo para mostrar propiedades cercanas.',
                          ),
                          _buildTermsSection(
                            icon: Icons.block_outlined,
                            title: '8. Violaciones y Suspensión',
                            content:
                                'Podemos suspender o eliminar tu cuenta sin previo aviso si violas estos términos o realizas actividades ilícitas.',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- BOTÓN EN FONDO BLANCO ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                // --- HEADER CON GRADIENTE (SIN PADDING HORIZONTAL) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 28),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.security_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Política de Privacidad',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu privacidad es nuestra prioridad',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- CONTENIDO EN FONDO BLANCO ---
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTermsSection(
                            icon: Icons.data_saver_on_outlined,
                            title: '1. Datos que Recolectamos',
                            content:
                                'Nombre, correo, teléfono, foto, información de hábitos, preferencias de vivienda, ubicación, imágenes de propiedades e historial de interacciones.',
                          ),
                          _buildTermsSection(
                            icon: Icons.psychology_outlined,
                            title: '2. Hábitos de Vida y Compatibilidad',
                            content:
                                'La información sobre tus hábitos se utiliza únicamente para alimentar nuestro algoritmo IA. Solo es visible para potenciales matches compatibles.',
                          ),
                          _buildTermsSection(
                            icon: Icons.map_outlined,
                            title: '3. Ubicación y Mapas',
                            content:
                                'Tu ubicación exacta NO se comparte públicamente. Se usa solo para mostrar propiedades cercanas. Otros usuarios solo ven propiedades en el área.',
                          ),
                          _buildTermsSection(
                            icon: Icons.image_not_supported_outlined,
                            title: '4. Imágenes y Fotos',
                            content:
                                'Imágenes de perfil: visibles públicamente. Imágenes de propiedades: solo para usuarios interesados.',
                          ),
                          _buildTermsSection(
                            icon: Icons.mail_lock_outlined,
                            title: '5. Chat y Comunicaciones',
                            content:
                                'Mensajes almacenados encriptados. No accedemos a mensajes privados a menos que investiguemos fraude o acoso.',
                          ),
                          _buildTermsSection(
                            icon: Icons.share_outlined,
                            title: '6. Datos Compartidos',
                            content:
                                'Visibles solo entre usuarios de ConVive. NO vendemos datos. Se comparten solo si ley lo requiere.',
                          ),
                          _buildTermsSection(
                            icon: Icons.privacy_tip_outlined,
                            title: '7. Derechos del Usuario',
                            content:
                                'Derecho a: acceder datos, corregir información, eliminar cuenta (derecho al olvido), solicitar copia de datos.',
                          ),
                          _buildTermsSection(
                            icon: Icons.verified_user_outlined,
                            title: '8. Seguridad y Contacto',
                            content:
                                'Encriptación y protocolos de seguridad estándar. Consultas: privacy@convive.app',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- BOTÓN EN FONDO BLANCO ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

  Widget _buildTermsSection({
    required IconData icon,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.primary.withOpacity(0.3),
              width: 3,
            ),
          ),
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
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
}

