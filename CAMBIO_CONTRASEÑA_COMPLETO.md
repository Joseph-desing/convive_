# 🔐 SISTEMA COMPLETO DE CAMBIO DE CONTRASEÑA - ConVive

**Documento detallado sobre la implementación del flujo de cambio de contraseña**

Fecha: 28 de marzo de 2026  
Versión: 1.0

---

## 📑 TABLA DE CONTENIDOS

1. [Introducción](#introducción)
2. [Estructura de Carpetas y Archivos](#estructura-de-carpetas-y-archivos)
3. [Rutas de Navegación](#rutas-de-navegación)
4. [Flujos Completos](#flujos-completos)
5. [Archivos Modificados](#archivos-modificados)
6. [Detalles Técnicos](#detalles-técnicos)
7. [Configuración Nativa](#configuración-nativa)
8. [Debugging y Troubleshooting](#debugging-y-troubleshooting)

---

## Introducción

El sistema de cambio de contraseña de ConVive implementa **3 flujos diferentes**:

1. **Cambiar desde Settings** - Usuario autenticado cambia su contraseña actual
2. **Recuperar por Email** - Usuario olvida su contraseña y solicita reset
3. **Verificar OTP** - Alternative si el email no funciona (opcional)

Cada flujo tiene su propia pantalla, lógica y validaciones.

---

## Estructura de Carpetas y Archivos

### 📁 Estructura Completa del Proyecto

```
c:\Users\HP\Desktop\convive_\
│
├── 📂 lib/
│   │
│   ├── 📂 screens/                              ← PANTALLAS DE UI
│   │   ├── 📄 change_password_screen.dart       ✅ NUEVO - Cambiar desde Settings
│   │   ├── 📄 forgot_password_screen.dart       ✅ NUEVO - Solicitar reset
│   │   ├── 📄 reset_password_screen.dart        ✅ NUEVO - Cambiar desde email
│   │   ├── 📄 notifications_screen.dart         ✅ NUEVO - Centro de notificaciones
│   │   ├── 📄 settings_screen.dart              ✨ MODIFICADO - Abre change_password
│   │   ├── 📄 login_screen.dart                 ✨ MODIFICADO - Abre forgot_password
│   │   ├── 📄 home_screen.dart                  ✨ MODIFICADO - Botón notificaciones
│   │   ├── 📄 profile_screen.dart               ✨ MODIFICADO - Tema oscuro
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── email_verification_screen.dart
│   │   ├── matches_screen.dart
│   │   ├── messages_screen.dart
│   │   ├── create_roommate_search_screen.dart
│   │   └── create_property_screen.dart
│   │
│   ├── 📂 providers/                            ← LÓGICA DE ESTADO
│   │   ├── 📄 auth_provider.dart                ✨ MODIFICADO - 5 métodos nuevos
│   │   ├── theme_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── 📄 notifications_provider.dart       ✅ NUEVO
│   │   └── ...otros providers
│   │
│   ├── 📂 models/                               ← MODELOS DE DATOS
│   │   ├── 📄 notification.dart                 ✅ NUEVO
│   │   ├── profile.dart
│   │   ├── property.dart
│   │   ├── user.dart
│   │   └── index.dart                           ✨ MODIFICADO - export notification
│   │
│   ├── 📂 config/                               ← CONFIGURACIÓN
│   │   ├── supabase_provider.dart
│   │   ├── app_config.dart
│   │   └── ai_service_provider.dart
│   │
│   ├── 📂 utils/
│   │   ├── colors.dart
│   │   ├── app_dimensions.dart
│   │   └── app_strings.dart
│   │
│   └── 📄 main.dart                             ✨ MODIFICADO - GoRouter + Deep linking
│
├── 📂 ios/
│   └── Runner/
│       └── 📄 Info.plist                        ✨ MODIFICADO - URL schemes para deep linking
│
├── 📂 android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml          ⚠️ NECESITA modificación
│
├── pubspec.yaml                                 ✨ MODIFICADO - app_links: ^7.0.0
├── pubspec.lock                                 ✨ MODIFICADO
│
└── 📂 docs/
    ├── 📄 CAMBIO_CONTRASEÑA_COMPLETO.md       ✅ ESTE ARCHIVO
    ├── 📄 CONFIGURAR_SUPABASE_EMAIL.md
    ├── 📄 DEBUG_RESET_PASSWORD.md
    ├── 📄 SETUP_RESET_PASSWORD.md
    ├── 📄 SETUP_RESET_PASSWORD_FINAL.md
    ├── 📄 Herramientas_seleccionadas.md
    └── 📄 Librerias_seleccionadas.md
```

---

## Rutas de Navegación

### 📍 Rutas Definidas en GoRouter

```dart
// En lib/main.dart - _setupRouter() method

GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_) => SplashScreen()),
    GoRoute(path: '/login', builder: (_) => LoginScreen()),
    GoRoute(path: '/home', builder: (_) => HomeScreen()),
    GoRoute(path: '/welcome', builder: (_) => WelcomeScreen()),
    
    // ✅ NUEVAS RUTAS PARA CAMBIO DE CONTRASEÑA
    GoRoute(
      path: '/auth-callback',
      builder: (context, state) => ResetPasswordScreen(
        resetToken: token,
        email: email,
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(
        resetToken: token,
        email: email,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(),
    ),
  ],
)
```

### 🗺️ Mapa de Navegación

```
┌─────────────────────────────────────────────────────────┐
│                    ESTRUCTURA DE RUTAS                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  / (Splash)                                             │
│   ├─→ /login (Si no hay sesión)                        │
│   │    ├─→ /forgot-password (¿Olvidaste?)             │
│   │    │   └─→ /auth-callback/reset-password          │
│   │    │       (Desde deep link de email)             │
│   │    └─→ /home (Login exitoso)                      │
│   │                                                    │
│   └─→ /home (Si hay sesión)                            │
│        ├─→ /settings → Change Password                │
│        ├─→ /notifications                             │
│        └─→ /logout → /login                           │
│                                                        │
└─────────────────────────────────────────────────────────┘
```

---

## Flujos Completos

### 🔄 FLUJO 1: Cambiar Contraseña desde Settings

#### Paso 1: Usuario abre la app y va a Settings

**Archivo:** `lib/screens/home_screen.dart`

```dart
// El ícono de opciones abre un menú
IconButton(
  icon: Icon(Icons.more_vert),
  onPressed: () {
    // Abre menú con opciones incluyendo Settings
  },
)
```

#### Paso 2: Usuario presiona "Cambiar Contraseña"

**Archivo:** `lib/screens/settings_screen.dart` (línea ~300)

```dart
void _showChangePasswordDialog() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ChangePasswordScreen(),
    ),
  );
}

// En el ListTile correspondiente:
_buildSettingTile(
  context: context,
  icon: Icons.lock,
  title: 'Cambiar Contraseña',
  subtitle: 'Actualiza tu contraseña',
  onTap: () => _showChangePasswordDialog(),
)
```

#### Paso 3: ChangePasswordScreen se abre

**Archivo:** `lib/screens/change_password_screen.dart`

```dart
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

  // ... resto del código
}
```

**Pantalla mostrada:**

```
┌────────────────────────────────────────┐
│  ← Cambiar Contraseña        [Atrás]  │
├────────────────────────────────────────┤
│                                       │
│ Actualiza tu contraseña de forma     │
│ segura                               │
│                                       │
│ CONTRASEÑA ACTUAL                    │
│ ┌──────────────────────────────────┐ │
│ │ 🔒 Contraseña actual    [👁]     │ │
│ └──────────────────────────────────┘ │
│                                       │
│ NUEVA CONTRASEÑA                     │
│ ┌──────────────────────────────────┐ │
│ │ 🔒 Mínimo 6 caracteres  [👁]     │ │
│ └──────────────────────────────────┘ │
│                                       │
│ CONFIRMAR CONTRASEÑA                 │
│ ┌──────────────────────────────────┐ │
│ │ 🔒 Repite tu nueva contraseña[👁]│ │
│ └──────────────────────────────────┘ │
│                                       │
│ ┌──────────────────────────────────┐ │
│ │    Guardar Nueva Contraseña      │ │
│ └──────────────────────────────────┘ │
│                                       │
│ 🛡️ Tu contraseña se encripta de    │
│    forma segura en nuestros         │
│    servidores                       │
│                                       │
└────────────────────────────────────────┘
```

#### Paso 4: Usuario ingresa los datos

```dart
// Validaciones que ocurren EN TIEMPO REAL:

// Campo 1: Contraseña Actual
validator: (value) {
  if (value == null || value.isEmpty)
    return 'Debes ingresar tu contraseña actual';
  return null;
}

// Campo 2: Nueva Contraseña
validator: (value) {
  if (value == null || value.isEmpty)
    return 'Ingresa una nueva contraseña';
  if (value.length < 6)
    return 'Mínimo 6 caracteres';
  return null;
}

// Campo 3: Confirmar Contraseña
validator: (value) {
  if (value == null || value.isEmpty)
    return 'Confirma tu nueva contraseña';
  return null;
}
```

#### Paso 5: Usuario presiona "Guardar Nueva Contraseña"

**Archivo:** `lib/screens/change_password_screen.dart`

```dart
Future<void> _changePassword() async {
  // 1. Validar que el formulario sea válido
  if (!_formKey.currentState!.validate()) return;

  // 2. Validar que las contraseñas coincidan
  if (_newPasswordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Las contraseñas no coinciden'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // 3. Mostrar loading
  setState(() => _isLoading = true);

  try {
    // 4. Llamar al provider
    final authProvider = context.read<AuthProvider>();
    await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    // 5. Mostrar éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);  // Volver a Settings
    }
  } catch (e) {
    // 6. Mostrar error
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
```

#### Paso 6: AuthProvider procesa el cambio

**Archivo:** `lib/providers/auth_provider.dart`

```dart
/// Cambiar contraseña (usuario autenticado)
Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  // 1. Activar loading
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // 2. Verificar que hay usuario autenticado
    if (_currentUser?.email == null) {
      throw Exception('Email no disponible');
    }

    print('🔄 Verificando contraseña actual...');

    // 3. Re-autenticar con la contraseña actual
    // Esto verifica que la contraseña actual es correcta
    await SupabaseProvider.authService.signIn(
      email: _currentUser!.email,
      password: currentPassword,
    );

    print('✅ Contraseña actual verificada');

    // 4. Si la verificación funciona, cambiar la contraseña
    print('🔄 Actualizando contraseña nueva...');
    await SupabaseProvider.authService.updatePassword(newPassword);

    print('✅ Contraseña actualizada exitosamente');
    _error = null;
    
  } catch (e) {
    print('❌ Error: $e');
    _error = e.toString();
    rethrow;  // Re-lanzar para que ChangePasswordScreen lo capture
  } finally {
    // 5. Desactivar loading
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace Supabase:**
```
1. Recibe: email + currentPassword + newPassword
2. Verifica que el email y contraseña actual sean correctos
3. Si sí → Actualiza la contraseña en la base de datos
4. Responde: { success: true } o { error: mensaje }
5. El usuario mantiene su sesión activa
```

#### Paso 7: Resultado

✅ **Éxito:**
```
SnackBar: "✅ Contraseña actualizada correctamente"
        ↓
Vuelve automáticamente a SettingsScreen
        ↓
Usuario puede ver la sesión activada con nueva contraseña
```

❌ **Error (Ejemplos):**
```
"Contraseña incorrecta o email no registrado"
"La contraseña debe tener al menos 6 caracteres"
"Error de conexión. Verifica tu internet"
```

---

### 🔄 FLUJO 2: Recuperar por Email (¿Olvidaste tu Contraseña?)

#### Paso 1: Usuario en Login presiona "¿Olvidaste tu contraseña?"

**Archivo:** `lib/screens/login_screen.dart` (línea ~148)

```dart
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
      style: TextStyle(color: AppColors.primary),
    ),
  ),
)
```

#### Paso 2: ForgotPasswordScreen se abre

**Archivo:** `lib/screens/forgot_password_screen.dart`

```dart
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

  // ... resto del código
}
```

**Pantalla mostrada (Inicial):**

```
┌──────────────────────────────────────────┐
│                                         │
│            🔐 ConVive Logo              │
│                                         │
│     Recuperar Contraseña                │
│                                         │
│  Ingresa tu email y te enviaremos un    │
│  enlace para restablecer tu contraseña  │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ 📧 tu@email.com                    │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │ Enviar Enlace de Recuperación      │ │
│  └────────────────────────────────────┘ │
│                                         │
│        ← Volver al Login                │
│        ¿No recuerdas tu email?          │
│                                         │
└──────────────────────────────────────────┘
```

#### Paso 3: Usuario ingresa email y presiona botón

```dart
Future<void> _sendResetEmail() async {
  // 1. Validar que el formulario sea válido
  if (!_formKey.currentState!.validate()) return;

  // 2. Activar loading
  setState(() => _isLoading = true);

  try {
    // 3. Obtener el provider de autenticación
    final authProvider = context.read<AuthProvider>();
    
    // 4. Llamar al método de reset
    await authProvider.resetPassword(_emailController.text.trim());

    // 5. Mostrar que fue exitoso
    if (mounted) {
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    }
  } catch (e) {
    // 6. Mostrar error
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
```

#### Paso 4: AuthProvider envía email a Supabase

**Archivo:** `lib/providers/auth_provider.dart`

```dart
/// Reestablecer contraseña
Future<void> resetPassword(String email) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    print('🔄 Enviando email de recuperación a: $email');
    
    // CLAVE: Especificar el redirect_to (deep link)
    await SupabaseProvider.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.example.convive://reset-password',
    );

    print('✅ Email de recuperación enviado');
  } catch (e) {
    print('❌ Error enviando email: $e');
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace Supabase:**

```
1. Recibe: email + redirectTo='com.example.convive://reset-password'
2. Verifica que el email exista en la base de datos
3. Si existe:
   a. Genera un token ÚNICO y seguro (válido 24 horas)
   b. Crea URL: https://tuproyecto.supabase.co/auth/v1/verify?
      token=TOKEN_SECRETO&type=recovery&redirect_to=com.example.convive://reset-password
   c. Envía email con link y botón "Cambiar Contraseña"
4. Si no existe:
   - Algunos backends envían un email diciendo "no existe"
   - Otros no dicen nada por seguridad
```

#### Paso 5: Pantalla actualizada (Email enviado)

```
┌──────────────────────────────────────────┐
│                                         │
│         ✅ ¡Correo Enviado!             │
│                                         │
│     Se ha enviado un enlace de          │
│     recuperación a:                     │
│                                         │
│     usuario@example.com                 │
│                                         │
│  Por favor revisa tu bandeja de         │
│  entrada y sigue las instrucciones.     │
│  Si no ves el email, verifica tu        │
│  carpeta de spam.                       │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │    Volver al Login                 │ │
│  └────────────────────────────────────┘ │
│                                         │
└──────────────────────────────────────────┘
```

#### Paso 6: Usuario recibe email

**Email enviado por Supabase:**

```
De: noreply@supabase.io
Para: usuario@example.com
Asunto: Restablecer tu contraseña ConVive

┌────────────────────────────────────────────┐
│                                           │
│           ConVive - Restablecer           │
│          Contraseña de Cuenta             │
│                                           │
│  ¡Hola!                                   │
│                                           │
│  Recibimos una solicitud para restablecer │
│  la contraseña de tu cuenta ConVive.      │
│                                           │
│  Si fuiste tú, haz clic en el botón de   │
│  abajo para crear una nueva contraseña   │
│  segura.                                  │
│                                           │
│  ┌────────────────────────────────────┐  │
│  │  🔄 Cambiar Contraseña            │  │
│  │  (URL con token)                  │  │
│  └────────────────────────────────────┘  │
│                                           │
│  ⏰ Este enlace expirará en 24 horas     │
│                                           │
│  O copia y pega esta URL en tu navegador: │
│  https://tuproyecto.supabase.co/auth/... │
│                                           │
│  ¿No solicitaste este cambio?            │
│  Si no fuiste tú, ignora este email.     │
│                                           │
│  © 2026 ConVive. Todos los derechos.     │
│                                           │
└────────────────────────────────────────────┘
```

#### Paso 7: Usuario hace clic en "Cambiar Contraseña"

```
El navegador abre la URL:
https://tuproyecto.supabase.co/auth/v1/verify?
  token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  type=recovery
  redirect_to=com.example.convive://reset-password
```

#### Paso 8: Deep Link abre la app automáticamente

**Archivo:** `lib/main.dart` (línea ~45-85)

```dart
class _ConViveAppState extends State<ConViveApp> {
  late final AppLinks _appLinks;
  late final StreamSubscription<Uri> _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _router = _setupRouter();
    _setupDeepLinkListener();  // ← IMPORTANTE
  }

  void _setupDeepLinkListener() {
    _appLinks = AppLinks();
    
    // Escuchar deep links cuando la app está abierta
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('🔗 Deep link recibido: $uri');
        print('🔗 Scheme: ${uri.scheme}');
        print('🔗 Host: ${uri.host}');
        print('🔗 Path: ${uri.path}');
        print('🔗 Query Parameters: ${uri.queryParameters}');
        print('🔗 Fragment: ${uri.fragment}');

        // Si es un reset password
        if (uri.host == 'auth-callback' || uri.path.contains('auth-callback')) {
          // Intentar obtener el token del fragment (donde Supabase lo pone)
          String token = '';
          String type = '';
          String email = '';

          // Primero buscar en query parameters (fallback)
          if (uri.queryParameters.containsKey('token')) {
            token = uri.queryParameters['token'] ?? '';
            type = uri.queryParameters['type'] ?? '';
            email = uri.queryParameters['email'] ?? '';
          }
          // Si no, buscar en el fragment (donde Supabase lo envía realmente)
          else if (uri.fragment.isNotEmpty) {
            final fragmentParams = Uri.parse('http://example.com?${uri.fragment}').queryParameters;
            token = fragmentParams['access_token'] ?? '';
            type = fragmentParams['type'] ?? '';
            email = fragmentParams['email'] ?? '';
          }

          print('📝 Token extraído: $token');
          print('📝 Type: $type');
          print('📝 Email: $email');

          if (token.isNotEmpty) {
            // Navegar a ResetPasswordScreen
            context.push('/reset-password?token=$token&email=$email');
          }
        }
      },
      onError: (err) {
        print('❌ Error en deep link: $err');
      },
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
    super.dispose();
  }
}
```

**Qué pasa aquí:**

```
1. Usuario hace clic en email → Abre navegador
2. Navegador va a: supabase.co/auth/v1/verify?token=XXX&...
3. Supabase verifica el token es válido
4. Si es válido → Redirige a: com.example.convive://reset-password?token=XXX
5. Sistema operativo detecta scheme "com.example.convive"
6. Abre la app ConVive automáticamente
7. Deep link listener en main.dart recibe la URI
8. Extrae el token de la URI
9. Navega a ResetPasswordScreen con el token
```

#### Paso 9: GoRouter atrapa la ruta y abre ResetPasswordScreen

**Archivo:** `lib/main.dart` (línea ~120-200)

```dart
GoRouter _setupRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ... otras rutas
      
      // 🔐 RUTA DE RECUPERACIÓN DE CONTRASEÑA (desde el email)
      GoRoute(
        path: '/auth-callback',
        builder: (context, state) {
          // Debug: Mostrar toda la URI
          print('🔍 URI Completa: ${state.uri}');
          print('🔍 Query Parameters: ${state.uri.queryParameters}');
          print('🔍 Fragment: ${state.uri.fragment}');
          
          // Capturar parámetros de la URL (primero query, luego fragment)
          String token = '';
          String type = '';
          String email = '';

          // Buscar en query parameters
          if (state.uri.queryParameters.containsKey('token')) {
            token = state.uri.queryParameters['token'] ?? '';
            type = state.uri.queryParameters['type'] ?? '';
            email = state.uri.queryParameters['email'] ?? '';
          }
          // Si no, buscar en el fragment (donde Supabase lo envía)
          else if (state.uri.fragment.isNotEmpty) {
            final fragmentParams = Uri.parse('http://example.com?${state.uri.fragment}').queryParameters;
            token = fragmentParams['access_token'] ?? '';
            type = fragmentParams['type'] ?? '';
            email = fragmentParams['email'] ?? '';
          }

          print('📝 Token: $token');
          print('📝 Type: $type');
          print('📝 Email: $email');

          // Si es recuperación de contraseña
          if (type == 'recovery' && token.isNotEmpty) {
            return ResetPasswordScreen(
              resetToken: token,
              email: email,
            );
          }

          // Si no hay tipo pero hay token, asumir que es recuperación
          if (token.isNotEmpty) {
            return ResetPasswordScreen(
              resetToken: token,
              email: email,
            );
          }

          // Fallback: mostrar error en ResetPasswordScreen
          return const ResetPasswordScreen(
            resetToken: '',
            email: null,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          // Buscar parámetros en query (fallback)
          String token = state.uri.queryParameters['token'] ?? '';
          String email = state.uri.queryParameters['email'] ?? '';

          // Si no hay en query, buscar en fragment
          if (token.isEmpty && state.uri.fragment.isNotEmpty) {
            final fragmentParams = Uri.parse('http://example.com?${state.uri.fragment}').queryParameters;
            token = fragmentParams['access_token'] ?? '';
            email = fragmentParams['email'] ?? '';
          }

          return ResetPasswordScreen(
            resetToken: token,
            email: email,
          );
        },
      ),
    ],
  );
}
```

#### Paso 10: ResetPasswordScreen se abre directamente

**Archivo:** `lib/screens/reset_password_screen.dart`

```dart
class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;    // Token de Supabase
  final String? email;        // Email del usuario

  const ResetPasswordScreen({
    Key? key,
    required this.resetToken,
    this.email,
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
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ... resto del código
}
```

**Pantalla mostrada:**

```
┌──────────────────────────────────────────┐
│  ← Restablecer Contraseña        [Atrás]│
├──────────────────────────────────────────┤
│                                         │
│     Crear Nueva Contraseña              │
│                                         │
│  Ingresa una contraseña segura          │
│  para tu cuenta                         │
│                                         │
│  NUEVA CONTRASEÑA                       │
│  ┌────────────────────────────────────┐ │
│  │ 🔒 Ingresa nueva contraseña [👁]  │ │
│  └────────────────────────────────────┘ │
│                                         │
│  CONFIRMAR CONTRASEÑA                   │
│  ┌────────────────────────────────────┐ │
│  │ 🔒 Confirma tu contraseña   [👁]  │ │
│  └────────────────────────────────────┘ │
│                                         │
│  ┌────────────────────────────────────┐ │
│  │   Cambiar Contraseña               │ │
│  └────────────────────────────────────┘ │
│                                         │
└──────────────────────────────────────────┘
```

#### Paso 11: Usuario ingresa nueva contraseña

```dart
// Validaciones:

// Campo 1: Nueva Contraseña
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es requerida';
  }
  if (value.length < 6) {
    return 'Debe tener al menos 6 caracteres';
  }
  return null;
}

// Campo 2: Confirmar Contraseña
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Por favor confirma la contraseña';
  }
  if (value != _passwordController.text) {
    return 'Las contraseñas no coinciden';
  }
  return null;
}
```

#### Paso 12: Usuario presiona "Cambiar Contraseña"

```dart
Future<void> _resetPassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    print('🔄 Actualizando contraseña...');

    // Usar el token para actualizar la contraseña
    await SupabaseProvider.client.auth.updateUser(
      UserAttributes(
        password: _passwordController.text.trim(),
      ),
    );

    print('✅ Contraseña actualizada exitosamente');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Contraseña cambiada correctamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Volver al login después de 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (_) => false,
      );
    }
  } catch (e) {
    print('❌ Error: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

#### Paso 13: Supabase actualiza la contraseña

```
Solicitud: 
  PUT /auth/v1/user
  Headers: Authorization: Bearer TOKEN
  Body: { password: "Nueva1234" }

Respuesta:
  {
    "id": "usuario-id",
    "email": "usuario@example.com",
    "password": "ENCRIPTADA",
    "updated_at": "2026-03-28T10:30:00Z"
  }
```

#### Paso 14: Éxito - Vuelve al Login

```
✅ "Contraseña cambiada correctamente"
        ↓
Espera 2 segundos
        ↓
Navega a /login automáticamente
        ↓
Usuario inicia sesión con:
   Email: usuario@example.com
   Contraseña: (la nueva)
```

---

## Archivos Modificados

### 📄 1. `lib/main.dart` - GoRouter + Deep Linking

**Cambios principales:**

```dart
// ANTES:
class ConViveApp extends StatelessWidget {
  const ConViveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthGate(),
      routes: { /* rutas simples */ },
    );
  }
}

// DESPUÉS:
class ConViveApp extends StatefulWidget {
  const ConViveApp({Key? key}) : super(key: key);

  @override
  State<ConViveApp> createState() => _ConViveAppState();
}

class _ConViveAppState extends State<ConViveApp> {
  late final GoRouter _router;
  late final AppLinks _appLinks;
  late final StreamSubscription<Uri> _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _router = _setupRouter();
    _setupDeepLinkListener();  // ← NUEVO
  }

  void _setupDeepLinkListener() {
    // Escuchar deep links
  }

  GoRouter _setupRouter() {
    return GoRouter(
      routes: [
        // Todas las rutas incluyendo /reset-password
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ...
      child: MaterialApp.router(  // ← CAMBIO: MaterialApp → MaterialApp.router
        routerConfig: _router,
      ),
    );
  }
}
```

**Lo que se agregó:**
- Importación: `import 'package:app_links/app_links.dart';`
- Importación: `import 'package:go_router/go_router.dart';`
- Importación: `import 'screens/reset_password_screen.dart';`
- Importación: `import 'screens/forgot_password_screen.dart';`
- Conversión a StatefulWidget
- Método `_setupDeepLinkListener()`
- Método `_setupRouter()` con GoRouter
- Cambio a MaterialApp.router

---

### 📄 2. `lib/screens/settings_screen.dart` - Abre ChangePasswordScreen

**Cambio principal:**

```dart
// ANTES:
void _showChangePasswordDialog() {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  const confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: currentPasswordController, ...),
          TextField(controller: newPasswordController, ...),
          TextField(controller: confirmPasswordController, ...),
        ],
      ),
      actions: [ /* acciones */ ],
    ),
  );
}

// DESPUÉS:
void _showChangePasswordDialog() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ChangePasswordScreen(),  // ← PANTALLA COMPLETA
    ),
  );
}
```

**Lo que se agregó:**
- Importación: `import 'change_password_screen.dart';`
- Cambio a navegación standard (push)
- Eliminación del AlertDialog inline

---

### 📄 3. `lib/screens/login_screen.dart` - Abre ForgotPasswordScreen

**Cambio principal:**

```dart
// ANTES:
TextButton(
  onPressed: () async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo primero')));
      return;
    }
    final auth = context.read<AuthProvider>();
    await auth.resetPassword(_emailController.text);
    // ... mostrar snackbar
  },
  child: const Text('¿Olvidaste tu contraseña?'),
)

// DESPUÉS:
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),  // ← PANTALLA NUEVA
      ),
    );
  },
  child: const Text('¿Olvidaste tu contraseña?'),
)
```

**Lo que se agregó:**
- Importación: `import 'forgot_password_screen.dart';`
- Cambio a navegación a pantalla completa
- Mejor manejo de errores en los catch blocks

---

### 📄 4. `lib/providers/auth_provider.dart` - 5 Métodos Nuevos

**Métodos agregados:**

#### Método 1: `resetPassword()`
```dart
Future<void> resetPassword(String email) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    print('🔄 Enviando email de recuperación a: $email');
    
    await SupabaseProvider.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.example.convive://reset-password',
    );

    print('✅ Email de recuperación enviado');
  } catch (e) {
    print('❌ Error enviando email: $e');
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace:**
- Solicita a Supabase que envíe un email de reset
- Incluye el deep link `com.example.convive://reset-password`
- Supabase genera un token y lo mete en la URL del email

#### Método 2: `changePassword()`
```dart
Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    if (_currentUser?.email == null) {
      throw Exception('Email no disponible');
    }

    await SupabaseProvider.authService.signIn(
      email: _currentUser!.email,
      password: currentPassword,
    );

    await SupabaseProvider.authService.updatePassword(newPassword);
    _error = null;
  } catch (e) {
    _error = e.toString();
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace:**
- Re-autentica al usuario con la contraseña actual (verifica que sea correcta)
- Si es correcto, actualiza a la nueva contraseña
- Mantiene la sesión activa

#### Método 3: `resetPasswordWithToken()`
```dart
Future<void> resetPasswordWithToken({
  required String email,
  required String newPassword,
  required String resetToken,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    if (resetToken.isEmpty) {
      throw Exception('El token de recuperación está vacío');
    }

    print('🔄 Intentando cambiar contraseña con token...');

    try {
      await SupabaseProvider.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      print('✅ Contraseña actualizada exitosamente');
    } catch (updateError) {
      print('⚠️ Error directo: $updateError');
      
      try {
        print('🔄 Intentando verificar como OTP...');
        final response = await SupabaseProvider.client.auth.verifyOTP(
          email: email,
          token: resetToken,
          type: OtpType.recovery,
        );

        if (response.session != null) {
          print('✅ OTP verificado');
          
          await SupabaseProvider.client.auth.updateUser(
            UserAttributes(password: newPassword),
          );
          
          print('✅ Contraseña actualizada');
        } else {
          throw Exception('No se pudo verificar el OTP');
        }
      } catch (otpError) {
        print('❌ Error con OTP: $otpError');
        throw otpError;
      }
    }

    await SupabaseProvider.client.auth.signOut();
    _currentUser = null;

    _error = null;
  } catch (e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('otp_expired') || errorStr.contains('expired')) {
      _error = 'El token de recuperación ha expirado. Por favor solicita uno nuevo.';
    } else if (errorStr.contains('invalid')) {
      _error = 'El token de recuperación es inválido.';
    } else if (errorStr.contains('password')) {
      _error = 'La contraseña no cumple los requisitos mínimos (mín. 6 caracteres)';
    } else {
      _error = e.toString();
    }
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace:**
- Intenta cambiar la contraseña usando el token del email
- Manejo de dos casos: direct update y OTP verification
- Manejo específico de errores (token expirado, inválido, etc.)

#### Método 4: `verifyRecoveryCode()`
```dart
Future<void> verifyRecoveryCode({
  required String email,
  required String code,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    print('🔄 Verificando código OTP...');

    final response = await SupabaseProvider.client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );

    if (response.session == null) {
      throw Exception('No se pudo verificar el código. Por favor intenta de nuevo.');
    }

    print('✅ Código OTP verificado correctamente');
  } catch (e) {
    final errorStr = e.toString().toLowerCase();
    print('❌ Error verificando OTP: $e');
    
    if (errorStr.contains('otp_expired') || errorStr.contains('expired')) {
      _error = 'El código ha expirado. Por favor solicita uno nuevo.';
    } else if (errorStr.contains('invalid') || errorStr.contains('incorrect')) {
      _error = 'El código es incorrecto. Por favor verifica y intenta de nuevo.';
    } else {
      _error = e.toString();
    }
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace:**
- Verifica que un código OTP sea válido
- Si lo es, abre una sesión temporal

#### Método 5: `resetPasswordWithCode()`
```dart
Future<void> resetPasswordWithCode({
  required String email,
  required String code,
  required String newPassword,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    print('🔄 Cambiando contraseña...');

    final response = await SupabaseProvider.client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );

    if (response.session == null) {
      throw Exception('No se pudo verificar el código de recuperación');
    }

    await SupabaseProvider.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    print('✅ Contraseña cambiada exitosamente');

    await SupabaseProvider.client.auth.signOut();
    _currentUser = null;

    _error = null;
  } catch (e) {
    final errorStr = e.toString().toLowerCase();
    print('❌ Error cambiando contraseña: $e');

    if (errorStr.contains('otp_expired') || errorStr.contains('expired')) {
      _error = 'El código ha expirado. Por favor solicita uno nuevo.';
    } else if (errorStr.contains('invalid')) {
      _error = 'El código es inválido. Por favor verifica y intenta de nuevo.';
    } else if (errorStr.contains('password')) {
      _error = 'La contraseña debe tener al menos 6 caracteres.';
    } else {
      _error = e.toString();
    }
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Qué hace:**
- Verifica un código OTP y cambia la contraseña en una operación
- Cierra sesión automáticamente al terminar

---

### 📄 5. `lib/screens/change_password_screen.dart` - ARCHIVO NUEVO

```dart
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
    // ... código de validación y cambio
  }

  @override
  Widget build(BuildContext context) {
    // ... construcción de UI
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required Function() onToggle,
    required String? Function(String?) validator,
  }) {
    // ... construcción del campo
  }
}
```

---

### 📄 6. `lib/screens/forgot_password_screen.dart` - ARCHIVO NUEVO

```dart
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

  // ... métodos para abrir WhatsApp, email, etc.
  
  Future<void> _sendResetEmail() async {
    // ... código de envío
  }

  @override
  Widget build(BuildContext context) {
    // ... construcción de UI con 2 pantallas (antes y después de enviar)
  }
}
```

---

### 📄 7. `lib/screens/reset_password_screen.dart` - ARCHIVO NUEVO

```dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;
  final String? email;

  const ResetPasswordScreen({
    Key? key,
    required this.resetToken,
    this.email,
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
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // ... código de cambio
  }

  @override
  Widget build(BuildContext context) {
    // ... construcción de UI
  }
}
```

---

### 📄 8. `ios/Runner/Info.plist` - Deep Linking

**Cambio:**

```xml
<!-- ANTES: Sin CFBundleURLTypes -->

<!-- DESPUÉS: Agregado -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.convive</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.example.convive</string>
    </array>
  </dict>
</array>
```

**Qué hace:**
- Registra el scheme `com.example.convive://` para que iOS lo reconozca
- Permite que URLs como `com.example.convive://reset-password` abran la app

---

### 📄 9. `pubspec.yaml` - Nueva Dependencia

**Cambio:**

```yaml
dependencies:
  # ... otras dependencias

  # Google Oauth
  google_sign_in: ^7.2.0
  app_links: ^7.0.0  # ← NUEVA

dev_dependencies:
  # ...
```

---

### 📄 10. `lib/models/notification.dart` - ARCHIVO NUEVO

```dart
class Notification {
  final String id;
  final String? title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? senderUserId;
  final String? publicationId;

  Notification({...});

  factory Notification.fromJson(Map<String, dynamic> json) {...}
  Map<String, dynamic> toJson() {...}
}
```

---

### 📄 11. `lib/providers/notifications_provider.dart` - ARCHIVO NUEVO

```dart
class NotificationsProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  Future<void> loadNotifications() async {...}
  Future<void> markAsRead(String notificationId) async {...}
  Future<void> markAllAsRead() async {...}
  Future<void> deleteNotification(String notificationId) async {...}
}
```

---

### 📄 12. `lib/screens/notifications_screen.dart` - ARCHIVO NUEVO

```dart
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... UI de notificaciones
    );
  }
}
```

---

## Detalles Técnicos

### 🔐 Seguridad de Tokens

**Cómo Supabase genera tokens:**

```
1. Usuario solicita reset: resetPassword(email)
2. Supabase genera JWT token con:
   {
     "iss": "https://tuproyecto.supabase.co",
     "sub": "usuario-id",
     "aud": "authenticated",
     "exp": 1711606800,  (24 horas después)
     "type": "recovery",
     "email": "usuario@example.com"
   }
3. Encripta el token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
4. Lo coloca en la URL: https://...?token=ENCRYPTED&type=recovery
5. Usuario abre URL → Supabase verifica el token
6. Si es válido → Redirige a deep link con parámetros
```

**Validaciones que hace Supabase:**

```
✅ Token no expirado (< 24 horas)
✅ Firma del token es correcta (no fue modificado)
✅ Email en token coincide con usuario
✅ No se ha usado ya el token
✅ Usuario no cambió email desde solicitud
```

### 🔗 Deep Linking - Flujo Técnico

```
1. Email con URL: https://supabase.co/auth/v1/verify?token=XXX&redirect_to=com.example.convive://reset-password

2. Usuario hace clic → Abre navegador
   - URL: https://supabase.co/auth/v1/verify
   - Parámetros: token=XXX, type=recovery, redirect_to=...

3. Servidor de Supabase:
   - Verifica token
   - Si válido → Status 307 (redirect)
   - Location: com.example.convive://reset-password?access_token=XXX&type=recovery&expires_in=3600

4. Navegador detecta scheme desconocido (com.example.convive)
   - Busca app que entienda este scheme
   - Encuentra ConVive app (registrada en Info.plist)
   - Se la pasa: com.example.convive://reset-password?access_token=XXX&...

5. Sistema operativo abre app
   - Pasa la URL al app

6. Flutter app (main.dart) recibe la URI
   - AppLinks escucha: _appLinks.uriLinkStream
   - Extrae parámetros de fragment y query
   - Navega a ResetPasswordScreen

7. GoRouter atrapa la ruta /reset-password
   - Lee parámetros
   - Abre ResetPasswordScreen con token y email
```

### 📊 Estados de Carga y Errores

```dart
// En todos los providers:

_isLoading = true;        // Mostrar spinner
_error = null;            // Limpiar erro anterior
notifyListeners();        // Actualizar UI

try {
  // Operación
} catch (e) {
  _error = e.toString();  // Capturar error
  // O manejo specifico de errores
  if (errorStr.contains('invalid')) {
    _error = 'Mensaje legible al usuario';
  }
  rethrow;                // Re-lanzar para pantalla
} finally {
  _isLoading = false;     // Quitar spinner
  notifyListeners();      // Actualizar UI
}
```

---

## Configuración Nativa

### iOS - Info.plist

**Valor:** `com.example.convive://`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.convive</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.example.convive</string>
    </array>
  </dict>
</array>
```

### Android - AndroidManifest.xml

**NECESITA SER MODIFICADO - Agregar a MainActivity:**

```xml
<activity
  android:name=".MainActivity"
  android:exported="true"
  android:launchMode="singleTop">
  
  <intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LAUNCHER" />
  </intent-filter>
  
  <!-- ✅ AGREGAR ESTO PARA DEEP LINKS -->
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.example.convive" android:host="reset-password" />
    <data android:scheme="com.example.convive" android:host="auth-callback" />
  </intent-filter>
</activity>
```

### Supabase - URL Configuration

**Agregar en Project Settings → Auth → Redirect URLs:**

```
com.example.convive://reset-password
com.example.convive://auth-callback
```

---

## Debugging y Troubleshooting

### 📋 Checklist de Verificación

```
✅ En iOS:
  [ ] Info.plist tiene CFBundleURLSchemes
  [ ] Scheme es "com.example.convive"
  [ ] CFBundleURLTypes está bien formado

✅ En Android:
  [ ] AndroidManifest.xml tiene intent-filter con deep link
  [ ] launchMode es "singleTop"
  [ ] Parámetros coinciden (scheme = com.example.convive)

✅ En Supabase:
  [ ] Redirect URLs contiene com.example.convive://reset-password
  [ ] Template de email existe
  [ ] OTP expiry está a 86400 segundos (24 horas)

✅ En Flutter:
  [ ] main.dart tiene GoRouter configurado
  [ ] AppLinks está importado y configurado
  [ ] _setupDeepLinkListener() se llama en initState
  [ ] Rutas /reset-password y /auth-callback existen

✅ En pubspec.yaml:
  [ ] app_links: ^7.0.0 está en dependencies
  [ ] go_router: existe
```

### 🐛 Errores Comunes

**Error: Deep link no abre la app**

```
Posibles causas:
1. Scheme en Info.plist/AndroidManifest no coincide
2. App no está compilada con cambios
3. URL tiene parámetros incorrectos

Solución:
1. flutter clean
2. flutter pub get
3. flutter run (sin cache)
```

**Error: Token expirado**

```
Posible causa:
- Usuario abrió email después de 24 horas
- Supabase expiró el token

Solución:
- Solicitar nuevo email de reset
- Aumentar OTP expiry en Supabase (máx 86400 segundos = 24 horas)
```

**Error: ResetPasswordScreen aparece vacía**

```
Posible causa:
- Token no se está extrayendo correctamente de URI
- Fragment vs Query parameters

Solución:
Ver logs en Flutter console:
  print('🔗 Deep link recibido: $uri');
  print('🔗 Query Parameters: ${uri.queryParameters}');
  print('🔗 Fragment: ${uri.fragment}');
```

**Error: "Contraseña incorrecta o email no registrado"**

```
En changePassword():
- Significa que la contraseña actual es INCORRECTA
- Usuario debe intentar de nuevo con contraseña correcta

Solución:
- Usuario presiona "¿Olvidaste tu contraseña?"
- Solicita reset
- Abre link del email
- Cambia contraseña
```

### 🔍 Logs de Debug

**Para ver qué está pasando, búsca estos logs:**

```
// Deep linking
🔗 Deep link recibido: ...
🔗 Query Parameters: ...

// Cambio de contraseña
🔄 Verificando contraseña actual...
✅ Contraseña actual verificada
🔄 Actualizando contraseña nueva...
✅ Contraseña actualizada exitosamente

// Reset por email
🔄 Enviando email de recuperación a: ...
✅ Email de recuperación enviado

// Reset desde email
📝 Token: ...
📝 Type: recovery
🔄 Actualizando contraseña...
✅ Contraseña actualizada exitosamente
```

---

## Resumen Visual Final

```
                       FLUJOS DE CAMBIO DE CONTRASEÑA
                       
     ┌─────────────────────────────────────────────────┐
     │                                                 │
     │           OPCIÓN 1                              │
     │      (Usuario autenticado)                       │
     │                                                 │
     │  Home → Settings → Change Password              │
     │    ↓                                             │
     │  ChangePasswordScreen                           │
     │    ↓ Ingresa                                     │
     │  - Contraseña actual                            │
     │  - Nueva                                        │
     │  - Confirmar                                    │
     │    ↓                                             │
     │  changePassword() en AuthProvider               │
     │    ↓ Verifica                                    │
     │  - Re-auth con contraseña actual                │
     │  - Update a new password                        │
     │    ↓                                             │
     │  ✅ Éxito → Volver a Settings                   │
     │                                                 │
     └─────────────────────────────────────────────────┘

     ┌─────────────────────────────────────────────────┐
     │                                                 │
     │           OPCIÓN 2                              │
     │      (Usuario olvizo)                           │
     │                                                 │
     │  Login → ¿Olvidaste? →ForgotPasswordScreen     │
     │    ↓ Ingresa email                              │
     │  resetPassword(email) → 📧 Email enviado        │
     │    ↓                                             │
     │  Usuario abre email → Hace clic en botón        │
     │    ↓                                             │
     │  Deep Link: com.example.convive://reset...      │
     │    ↓                                             │
     │  iOS/Android detecta y abre app                 │
     │    ↓                                             │
     │  GoRouter captura /reset-password ruta          │
     │    ↓                                             │
     │  ResetPasswordScreen (con token)                │
     │    ↓                                             │
     │  Ingresa nueva contraseña                       │
     │    ↓                                             │
     │  Supabase cambia con token                      │
     │    ↓                                             │
     │  ✅ Éxito → Volver al Login                     │
     │    ↓                                             │
     │  Usuario inicia con nueva contraseña            │
     │                                                 │
     └─────────────────────────────────────────────────┘
```

---

## Referencias Rápidas

- **GoRouter Docs:** https://pub.dev/packages/go_router
- **AppLinks Docs:** https://pub.dev/packages/app_links
- **Supabase Auth:** https://supabase.com/docs/guides/auth
- **Deep Linking (iOS):** https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-communicate
- **Deep Linking (Android):** https://developer.android.com/training/app-links

---

**FIN DEL DOCUMENTO**

Fecha de creación: 28 de marzo de 2026  
Última actualización: 28 de marzo de 2026  
Versión: 1.0  
Autor: Desarrollo ConVive
