# 🚀 GUÍA RÁPIDA: INSTALA TU APK EN ANDROID YA

## Pasos Inmediatos (Hazlo Ahora)

### PASO 1: Crear Keystore para firmar la app
Abre PowerShell en el proyecto y ejecuta:

```powershell
# Crear directorio
mkdir C:\Users\HP\.android -Force

# Generar keystore (copia todo esto junto)
keytool -genkey -v -keystore C:\Users\HP\.android\convive-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias convive-key

# Responde:
# What is your first and last name? Tu Nombre
# What is the name of your organizational unit? Desarrollo
# What is the name of your organization? ConVive
# What is the name of your City or Locality? Tu Ciudad
# What is the name of your State or Province? Tu Provincia
# What is the two-letter country code for this unit? AR (o tu país)
# Enter the password for this key in keystore: MiPassword123!
# Re-enter new password: MiPassword123!
```

✅ **Resultado:** Se crea `C:\Users\HP\.android\convive-release.jks`

---

### PASO 2: Actualizar build.gradle.kts

Abre: `android/app/build.gradle.kts`

**Busca esta sección (línea ~30):**
```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

**Reemplaza por esto:**
```kotlin
signingConfigs {
    release {
        keyAlias = "convive-key"
        keyPassword = "MiPassword123!"  // La que creaste en PASO 1
        storeFile = file("C:/Users/HP/.android/convive-release.jks")
        storePassword = "MiPassword123!"  // La que creaste en PASO 1
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.release
    }
}
```

---

### PASO 3: Cambiar Application ID

En el mismo archivo `android/app/build.gradle.kts`, busca:
```kotlin
applicationId = "com.example.convive_"
```

Reemplaza por:
```kotlin
applicationId = "com.convive.app"
```

*(O cualquier nombre único que prefieras, pero sin "com.example")*

---

### PASO 4: Agregar permisos a AndroidManifest.xml

Abre: `android/app/src/main/AndroidManifest.xml`

**Al final, ANTES de `</manifest>`, agrega:**

```xml
    <!-- Permisos necesarios para ConVive -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
</manifest>
```

---

### PASO 5: Limpiar y descargar dependencias

En PowerShell, en la raíz del proyecto:

```bash
flutter clean
flutter pub get
```

Espera a que termine (puede tardar 1-2 minutos)

---

### PASO 6: Verificar que todo funcione

```bash
flutter doctor -v
```

Busca que diga ✓ en:
- [✓] Flutter
- [✓] Android toolchain
- [✓] Android SDK
- [✓] Connected devices

---

### PASO 7: Conectar tu Android a la computadora

1. Conecta tu celular Android por USB
2. En el celular: Configuración > Aplicaciones y notificaciones > Información del teléfono
3. Toca "Número de compilación" 7 veces para habilitar "Modo de Desarrollador"
4. En Configuración > Sistema > Opciones de Desarrollador > Habilita "Depuración USB"
5. En tu computadora, autoriza el dispositivo (aparecerá un diálogo en el celular)

Verifica:
```bash
adb devices
```

Debe mostrar tu dispositivo como "device" (no "unauthorized")

---

### PASO 8: Generar APK Release

```bash
flutter build apk --release
```

Espera 2-5 minutos. Cuando termine, verás:
```
✅ Built build/app/outputs/apk/release/app-release.apk
```

---

### PASO 9: Instalar en tu dispositivo

Opción A - Automática:
```bash
flutter install
```

Opción B - Manual:
```bash
adb install build/app/outputs/apk/release/app-release.apk
```

---

### PASO 10: ¡Abre la app!

1. En tu celular, busca "ConVive"
2. Abre la app
3. ¡Prueba que funcione!

---

## ⚠️ Solución de Problemas

### "No device found"
```bash
adb devices  # ¿Aparece tu dispositivo?
# Si no:
adb kill-server
adb start-server
# Y reconnecta el USB
```

### "File not found: google-services.json"
- Si no usas Google Sign-In, ignora este error
- Si lo usas, descarga el archivo desde Firebase Console

### "Signing config not found"
- Verifica que copiaste correctamente el código en build.gradle.kts
- Verifica que la ruta del keystore sea correcta

### "App crashes on startup"
- Abre el log: `flutter logs`
- Busca el error
- Probablemente sea configuración de Supabase

### "Permission denied when opening app"
- El Android pedirá permisos en runtime
- Acepta todos los permisos

---

## 📋 Checklist Final

- [ ] Creé el keystore
- [ ] Actualicé build.gradle.kts con firma
- [ ] Cambié applicationId
- [ ] Agregué permisos a AndroidManifest.xml
- [ ] Ejecuté `flutter clean && flutter pub get`
- [ ] `flutter doctor -v` muestra todo OK
- [ ] Conecté mi dispositivo Android
- [ ] `adb devices` muestra mi dispositivo
- [ ] Ejecuté `flutter build apk --release`
- [ ] Instalé el APK con `flutter install`
- [ ] ¡La app abre en mi celular! 🎉

---

## 🎯 Resultado Esperado

Cuando abras la app en tu celular:
1. ✅ Ves la pantalla de login
2. ✅ Puedes registrarte con email
3. ✅ Recibes email de confirmación
4. ✅ Puedes loguearte
5. ✅ Ves la pantalla de perfil
6. ✅ La app funciona sin conexión al servidor local (excepto backend IA)

---

**¿Listo para empezar? 🚀**

Si tienes dudas en algún paso, pregunta específicamente qué paso no entiendes.
