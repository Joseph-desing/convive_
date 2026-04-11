# 🔐 Configuración de Reset Password y Deep Linking

## Problema: Token Expirado en Email

El problema que estabas viendo (`otp_expired`) ocurre porque:
1. El usuario hace clic en el email
2. El navegador intenta verificar el token en Supabase
3. El token ya ha expirado (timeout de 1 hora por defecto)

## Solución: Deep Linking Nativo + Supabase

### 1️⃣ Configurar Supabase Auth Template

En **Supabase Dashboard → Authentication → Email Templates**:

#### Password Reset Email Template
Reemplaza el contenido con:

```html
<h2>{{ .SiteURL }}</h2>

<p>Hola,</p>
<p>Solicitaste restablecer tu contraseña de ConVive.</p>
<p>Haz clic en el botón de abajo para crear una nueva contraseña:</p>

<a href="{{ .ConfirmationURL }}">Cambiar Contraseña</a>

<p>Este enlace expirará en 24 horas.</p>
<p>Si no solicitaste este cambio, ignora este email.</p>
```

#### URL de Redireccionamiento en Supabase
- **Redirect URL (Auth → Settings → Redirect URLs)**:
  ```
  com.example.convive://auth-callback
  ```

---

### 2️⃣ Configurar Android Deep Linking

Abre `android/app/src/main/AndroidManifest.xml` y modifica la activity principal:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop">
    
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
    
    <!-- Deep Link Intent Filter -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.example.convive" android:host="auth-callback" />
    </intent-filter>
</activity>
```

---

### 3️⃣ Configurar iOS Deep Linking

1. Abre `ios/Runner/Info.plist` y agregar:

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

2. Abre `ios/Runner.xcodeproj/project.pbxproj` en Xcode y verifica que el **Bundle ID** sea correcto.

---

### 4️⃣ Configurar Flutter GoRouter

✅ **YA ESTÁ CONFIGURADO** en `lib/main.dart`:

```dart
GoRoute(
  path: '/auth-callback',
  builder: (context, state) {
    final token = state.queryParameters['token'] ?? '';
    final type = state.queryParameters['type'] ?? '';
    final email = state.queryParameters['email'] ?? '';

    if (type == 'recovery') {
      return ResetPasswordScreen(
        resetToken: token,
        email: email,
      );
    }
    return const LoginScreen();
  },
),
```

---

### 5️⃣ Actualizar el Tiempo de Expiración del Token

En Supabase, puedes aumentar el tiempo de expiración del token de reset:

**Supabase Dashboard → Project Settings → Auth → OTP Expiry Duration**
- Por defecto: 3600 segundos (1 hora)
- **Recomendado**: 86400 segundos (24 horas)

---

## 🧪 Cómo Probar

### Opción 1: Enviar Email Real
1. Abre la app
2. Ve a **Forgot Password**
3. Ingresa tu email
4. Revisa tu bandeja de entrada
5. Haz clic en **"Cambiar Contraseña"**

### Opción 2: Testing en Development
```dart
// En auth_provider.dart puedes mockear el token:
final mockToken = 'mock_token_12345';
final mockEmail = 'test@example.com';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ResetPasswordScreen(
      resetToken: mockToken,
      email: mockEmail,
    ),
  ),
);
```

---

## 📧 Flujo Completo

```
1. Usuario solicita reset → forgot_password_screen.dart
   ↓
2. Backend envía email con link a: com.example.convive://auth-callback?token=X&type=recovery&email=Y
   ↓
3. Usuario hace clic en el email
   ↓
4. Deep link abre la app y GoRouter captura los parámetros
   ↓
5. Se navega a ResetPasswordScreen con token y email
   ↓
6. Usuario ingresa nueva contraseña
   ↓
7. Se llama a resetPasswordWithToken() en auth_provider
   ↓
8. Si es exitoso → Mostrar "Contraseña Cambiada" y redirigir a login
   ↓
9. Si token expiró → Mostrar error y opción de solicitar nuevo email
```

---

## 🐛 Troubleshooting

### "Token Expirado"
- Verifica que el tiempo en el servidor y en tu dispositivo sea correcto
- Aumenta el OTP Expiry Duration en Supabase
- Asegúrate de que el link se abre inmediatamente después de recibir el email

### "Link Inválido"
- Verifica el scheme en Android/iOS matches con `com.example.convive://`
- Comprueba que LaunchMode en AndroidManifest sea `singleTop`
- Revisa que Info.plist en iOS tenga los URL schemes correctos

### "No se abre la App"
- Asegúrate de que el deep link scheme esté registrado
- En Android: `adb shell am start -W -a android.intent.action.VIEW -d "com.example.convive://auth-callback?token=test" com.example.convive`
- En iOS: Prueba manualmente en Safari

---

## ✅ Próximos Pasos

1. Configura el scheme en Supabase (Redirect URL)
2. Actualiza Android/iOS manifest/info.plist
3. Aumenta el OTP Expiry Duration a 24 horas
4. Prueba el flujo completo
5. Verifica que el email template sea correcto

¡Listo! 🎉
