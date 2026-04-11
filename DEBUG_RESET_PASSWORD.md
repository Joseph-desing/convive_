# 🔧 Debugging: Reset Password - Página Vacía

## ❌ Problema
Cuando haces clic en "Cambiar Contraseña" desde el email, se abre una **página vacía**.

---

## ✅ Solución: Identificar el Problema

### PASO 1: Ver los logs en Flutter

1. Abre tu app en el emulador/dispositivo
2. Abre la **consola de Flutter** (en terminal/VS Code)
3. Solicita un reset de contraseña (Forgot Password → ingresa email)
4. Revisa el email y **haz clic en el botón "Cambiar Contraseña"**
5. **Mira los logs en la consola** (busca líneas que empiecen con 🔍 o 📝)

Deberías ver algo como:
```
🔍 URI Completa: com.example.convive://auth-callback?token=xxxxx&type=recovery&email=user@example.com
🔍 Query Parameters: {token: xxxxx, type: recovery, email: user@example.com}
📝 Token: xxxxx
📝 Type: recovery
📝 Email: user@example.com
```

---

## 🐛 Casos Posibles

### Caso 1: No hay parámetros (vacío)
```
🔍 URI Completa: com.example.convive://auth-callback
🔍 Query Parameters: {}
📝 Token: (vacío)
📝 Type: (vacío)
```

**Solución:**
- El scheme en AndroidManifest/Info.plist no coincide
- El Redirect URL en Supabase están mal configuradas
- El deep link no está registrado correctamente

### Caso 2: Hay parámetros, pero la pantalla de reset aparece vacía
```
🔍 URI Completa: com.example.convive://auth-callback?token=xxxxx&type=recovery
📝 Token: xxxxx
📝 Type: recovery
```

**Solución:**
- El ResetPasswordScreen recibe el token
- Pero no se está mostrando del todo
- **Mira si hay un error en la consola de Flutter**

### Cas 3: El navegador abre pero no hace deep link
```
Se abre el navegador pero no vuelve a la app
```

**Solución:**
- El scheme `com.example.convive` no está registrado en Android/iOS
- Revisa AndroidManifest.xml y Info.plist

---

## 🔍 Checklist de Debugging

### Android (`android/app/src/main/AndroidManifest.xml`)

Verifica que tengasesto en la MainActivity:

```xml
<activity android:name=".MainActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
    
    <!-- ✅ NECESARIO PARA DEEP LINKS -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.example.convive" android:host="auth-callback" />
    </intent-filter>
</activity>
```

### iOS (`ios/Runner/Info.plist`)

Verifica que tengas esto:

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

### Supabase (`Project Settings → Auth → URL Configuration`)

Verifica que tengas:
```
com.example.convive://auth-callback
```

---

## 🧪 Test Manual

Para probar sin esperar email:

1. Abre una terminal en tu PC
2. Ejecuta esto (reemplaza `tuproyecto` con tu proyecto Supabase):

```bash
# Para Android (en emulador/dispositivo):
adb shell am start -W -a android.intent.action.VIEW -d "com.example.convive://auth-callback?token=test_token&type=recovery&email=test@example.com" com.example.convive

# Para iOS (en simulador):
xcrun simctl openurl booted "com.example.convive://auth-callback?token=test_token&type=recovery&email=test@example.com"
```

¿Llega a la pantalla de reset? ¿Qué dice la consola?

---

## 📋 Próximo Paso

1. **Ejecuta tu app ahora**
2. **Solicita un reset de contraseña**
3. **Abre el email y haz clic**
4. **Copia los logs de la consola de Flutter**
5. **Comparte conmigo qué ves en los logs**

Con eso podré saber exactamente dónde está el problema. 🔍
