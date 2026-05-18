# 📱 ANÁLISIS DETALLADO - INSTALACIÓN APK ANDROID
**ConVive App | Fecha: 17 de mayo de 2026**

---

## 1. ESTADO GENERAL DEL PROYECTO ✅

Tu aplicación **ConVive** es un proyecto **Flutter completo y bien estructurado** con:
- ✅ Frontend multiplataforma (Android, iOS, Web, Linux, macOS, Windows)
- ✅ Backend FastAPI con IA (Groq)
- ✅ Base de datos Supabase con autenticación y realtime
- ✅ Todas las dependencias necesarias configuradas
- ✅ Estructura de carpetas Android lista

**Nivel de desarrollo:** MVP Funcional, listo para testing en dispositivo real

---

## 2. CHECKLIST - REQUISITOS PARA APK ✅✅

### 2.1 Flutter SDK & Herramientas
```
✅ Flutter SDK: Instalado en C:\Users\HP\Desktop\flutter
✅ Dart: Incluido con Flutter
✅ Android SDK: Configurado en C:\Users\HP\AppData\Local\Android\sdk
✅ local.properties: Configurado correctamente
✅ Gradle: Configurado en build.gradle.kts
✅ Java/Kotlin: Compilador JDK 17 configurado
```

**Verificación:** En terminal, ejecuta:
```bash
flutter doctor -v
```

Debe mostrar:
- [✓] Flutter (version X.X.X)
- [✓] Android toolchain
- [✓] Android SDK
- [✓] Connected devices (tu dispositivo Android)

---

### 2.2 Dependencias Flutter
**Estado:** ✅ TODAS INSTALADAS

Tu `pubspec.yaml` incluye:
```yaml
✅ flutter (SDK)
✅ provider (State management)
✅ go_router (Navegación)
✅ supabase_flutter (Backend)
✅ geolocator + geocoding (Ubicación)
✅ onesignal_flutter (Notificaciones)
✅ image_picker + file_picker (Archivos)
✅ google_sign_in (OAuth)
✅ flutter_map (Mapas)
✅ Todas las demás dependencias
```

**Verificación:** En terminal:
```bash
flutter pub get
```

---

### 2.3 Configuración Android ⚠️ REQUIERE AJUSTES

#### build.gradle.kts - Configuración encontrada:
```kotlin
✅ namespace = "com.example.convive_"
✅ compileSdk = flutter.compileSdkVersion
✅ minSdk = flutter.minSdkVersion
✅ targetSdk = flutter.targetSdkVersion
✅ Java Version 17
✅ Kotlin JVM Target 17
❌ PROBLEMA: Firma de APK solo con claves debug
```

**ACCIONES REQUERIDAS AHORA:**

#### ❌ PROBLEMA 1: Application ID es placeholder
**Archivo:** `android/app/build.gradle.kts` línea 16
```kotlin
// ACTUAL (NO USAR PARA PRODUCCIÓN):
applicationId = "com.example.convive_"

// DEBES CAMBIAR A:
applicationId = "com.tuempresa.convive"  // Ejemplo
// O si es personal:
applicationId = "com.tuapellido.convive"
```

**Impacto:** 
- Este ID debe ser **único en Google Play Store**
- Identifica tu app de forma permanente
- No puede cambiarse después de publicar

---

#### ❌ PROBLEMA 2: Firma de APK en MODO RELEASE
**Archivo:** `android/app/build.gradle.kts` líneas 31-36
```kotlin
// ACTUAL (INSEGURO):
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")  // ⚠️ INSEGURO
    }
}

// DEBE SER (SEGURO):
signingConfigs {
    release {
        keyAlias = "release-key"
        keyPassword = "tu-password"
        storeFile = file("../key.jks")  // Crear keystore
        storePassword = "tu-password"
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.release
    }
}
```

**¿Qué es un Keystore?** Archivo que contiene la firma criptográfica de tu app
- Necesario para publicar en Play Store
- Necesario para actualizar versiones
- Una app sin keystore NO se puede actualizar

---

### 2.4 AndroidManifest.xml ✅ BIEN CONFIGURADO

**Ubicación:** `android/app/src/main/AndroidManifest.xml`

**Configurado correctamente:**
```xml
✅ <application android:label="convive_">
✅ <activity> MainActivity
✅ android:exported="true" (requerido API 31+)
✅ <intent-filter> para MAIN/LAUNCHER
✅ Deep Links configurados:
   ✅ auth-callback
   ✅ reset-password
   ✅ login-callback
```

**Pero FALTA:** Permisos necesarios

---

### 2.5 ❌ PERMISOS FALTANTES EN AndroidManifest.xml

Tu app usa: **Geolocación, Cámara, Almacenamiento, Notificaciones**

**Debes agregar en AndroidManifest.xml (antes de `</manifest>`):**

```xml
<!-- Ubicación -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Cámara (para image_picker) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Almacenamiento (para file_picker) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Internet (muy importante para Supabase, API) -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Notificaciones (OneSignal) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Conectividad -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

### 2.6 Configuración Gradle ✅

**Archivo:** `android/gradle.properties`
```
✅ org.gradle.jvmargs=-Xmx8G (Memoria suficiente)
✅ android.useAndroidX=true (Dependencias modernas)
```

**Archivo:** `android/build.gradle.kts`
```
✅ Repositorios: google(), mavenCentral()
✅ Plugins configurados
✅ Build directory personalizado
```

---

### 2.7 Requisitos de Sistema ✅ VERIFICADOS

```
✅ SDK compileSdkVersion: 34+ (Android 14)
✅ minSdkVersion: 21 (Android 5.0 - muy compatible)
✅ targetSdkVersion: 34 (Android 14 - muy actualizado)
✅ NDK Version: Configurado por Flutter
✅ Java 17: Instalado y configurado
✅ Kotlin: Compilador moderno
```

---

## 3. DEPENDENCIAS CRÍTICAS PARA ANDROID

Tu `pubspec.yaml` usa librerías que necesitan permisos o configuración especial:

### 3.1 geolocator + geocoding 🌍
- **Qué hace:** Obtiene ubicación GPS
- **Permisos necesarios:** 
  - `ACCESS_FINE_LOCATION` (GPS exacto)
  - `ACCESS_COARSE_LOCATION` (ubicación aproximada)
- **Platform-specific:**
  - ✅ Android: Requiere en AndroidManifest
  - ⚠️ Necesita `requestPermissions()` en runtime (Android 6+)

### 3.2 image_picker 📷
- **Qué hace:** Accede a cámara y galería
- **Permisos necesarios:**
  - `CAMERA` (para cámara)
  - `READ_EXTERNAL_STORAGE` (para galería)
- **Platform-specific:** ✅ Ya configurado en pubspec

### 3.3 file_picker 📁
- **Qué hace:** Accede a almacenamiento (para PDF de verificación)
- **Permisos:** `READ_EXTERNAL_STORAGE`

### 3.4 onesignal_flutter 🔔
- **Qué hace:** Notificaciones push
- **Permisos:** `POST_NOTIFICATIONS` (Android 13+)
- **Configuración especial:** Necesita Google Services

### 3.5 supabase_flutter 🔐
- **Qué hace:** Conecta con Supabase
- **Necesita:** `INTERNET` (crítico)
- **Configuración:** URL de Supabase en code

### 3.6 google_sign_in 🔑
- **Qué hace:** OAuth con Google
- **Necesita:** Google Services JSON
- **Archivo:** `android/app/google-services.json`

---

## 4. CHECKLIST PRE-BUILD APK 📋

Antes de generar el APK, verifica:

```bash
# 1. Instalar dependencias
flutter clean
flutter pub get

# 2. Verificar diagnóstico
flutter doctor -v

# 3. Conectar dispositivo Android
adb devices

# 4. Test en desarrollo (opcional pero recomendado)
flutter run -d android

# 5. Build APK para testing
flutter build apk --debug

# 6. Build APK para producción
flutter build apk --release

# 7. Build App Bundle (recomendado para Play Store)
flutter build appbundle --release
```

---

## 5. ARCHIVOS QUE NECESITAS CREAR/MODIFICAR

### 5.1 URGENTE: Crear Keystore para firma

En terminal (PowerShell en tu Windows):
```powershell
# 1. Crear directorio para keystore
mkdir C:\Users\HP\.android

# 2. Generar keystore
keytool -genkey -v -keystore C:\Users\HP\.android\convive-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias convive-key

# Responde las preguntas:
# Full Name: Tu Nombre
# Organization: ConVive o tu empresa
# City: Tu ciudad
# State: Tu región
# Country Code: Ej: AR (Argentina)
# keystore password: Ej: MiPassword123! (GUARDA ESTO)
# key password: (Presiona Enter para usar el mismo)
```

### 5.2 IMPORTANTE: Configurar keystore en build.gradle.kts

```kotlin
android {
    ...
    
    signingConfigs {
        release {
            keyAlias = "convive-key"
            keyPassword = "TU_CONTRASEÑA_AQUÍ"
            storeFile = file("C:/Users/HP/.android/convive-release.jks")
            storePassword = "TU_CONTRASEÑA_AQUÍ"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
        }
    }
}
```

### 5.3 ACTUALIZAR: ApplicationId

En `android/app/build.gradle.kts`:
```kotlin
applicationId = "com.miempresa.convive"  // Cambia esto
```

### 5.4 ACTUALIZAR: AndroidManifest.xml

Agregar permisos (ver sección 2.5)

### 5.5 OPCIONAL: Google Services (si usas Google Sign-In)

Descargar `google-services.json` desde Firebase Console:
- Ubicar en: `android/app/google-services.json`

---

## 6. PASOS FINALES PARA INSTALAR APK

### Opción A: Test en tu dispositivo Android (DESARROLLO)
```bash
# 1. Conectar dispositivo USB
# 2. Activar "Depuración USB" en Configuración > Desarrollador
# 3. Ejecutar
flutter run -d android

# Instala automáticamente y abre la app
```

### Opción B: Build APK Debug (más rápido)
```bash
flutter build apk --debug
# Genera: build/app/outputs/apk/debug/app-debug.apk

# Instalar manualmente
adb install build/app/outputs/apk/debug/app-debug.apk
```

### Opción C: Build APK Release (para Play Store)
```bash
# Primero configurar keystore (ver 5.1)
flutter build apk --release
# Genera: build/app/outputs/apk/release/app-release.apk

# Instalar
adb install build/app/outputs/apk/release/app-release.apk
```

### Opción D: Build App Bundle (RECOMENDADO para Play Store)
```bash
flutter build appbundle --release
# Genera: build/app/outputs/bundle/release/app-release.aab
# Subir a Google Play Console
```

---

## 7. PROBLEMAS POTENCIALES Y SOLUCIONES

| Problema | Causa | Solución |
|----------|-------|----------|
| "AndroidManifest.xml not found" | Ruta incorrecta | `flutter clean && flutter pub get` |
| Error de permisos en runtime | Faltan permisos | Agregar a AndroidManifest.xml |
| "No signature found" | Keystore no configurado | Ver sección 5.1 y 5.2 |
| "Application ID duplicado" | Ya existe en Play Store | Cambiar `applicationId` en build.gradle.kts |
| App cierra al iniciar | Supabase URL incorrecta | Verificar en `lib/services/supabase_auth_service.dart` |
| Geolocación no funciona | Permiso de runtime no otorgado | Usar `geolocator.requestPermission()` |
| Notificaciones no llegan | OneSignal no configurado | Configurar OneSignal App ID |
| Login con Google falla | google-services.json falta | Descargar de Firebase Console |

---

## 8. RECOMENDACIONES IMPORTANTES ⚠️

### 8.1 Antes de Play Store
```
❌ NO: Publicar con debug signing config
❌ NO: Usar "com.example" en production
❌ NO: Olvidar la contraseña del keystore
❌ NO: Cambiar keystore después de publicar versión 1.0

✅ SÍ: Crear keystore nuevo y seguro
✅ SÍ: Guardar contraseña en lugar seguro
✅ SÍ: Hacer build APK de prueba primero
✅ SÍ: Test en dispositivo real antes de publicar
```

### 8.2 Configuración de Supabase
Asegúrate que en tu código tengäs:
```dart
// lib/services/supabase_auth_service.dart
const String supabaseUrl = 'https://tu-proyecto.supabase.co';
const String supabaseAnonKey = 'tu-anon-key';

// Sin estos, la app no funcionará
```

### 8.3 Backend Groq
Si usas chatbot:
```env
# backend/.env
GROQ_API_KEY=gsk_... (tu API key)
GROQ_MODEL=llama-3.1-70b-versatile
```

---

## 9. VERSIONES Y NÚMEROS

**Versión actual en pubspec.yaml:**
```yaml
version: 1.0.0+1
```

**Significado:**
- `1.0.0` = Versión semántica (para usuarios)
- `+1` = Build number (para Play Store)

**Para actualizar:**
```yaml
version: 1.0.1+2  # Nuevo parche, build 2
version: 1.1.0+3  # Nueva feature, build 3
version: 2.0.0+4  # Breaking change, build 4
```

---

## 10. RESUMEN FINAL ✅

| Aspecto | Estado | Acción |
|---------|--------|--------|
| Estructura Flutter | ✅ OK | Ninguna |
| Dependencias | ✅ OK | `flutter pub get` |
| Android SDK | ✅ OK | Ninguna |
| gradle.properties | ✅ OK | Ninguna |
| build.gradle.kts | ⚠️ Incompleto | Agregar firma release |
| AndroidManifest.xml | ⚠️ Incompleto | Agregar permisos |
| Application ID | ❌ Placeholder | Cambiar a único |
| Keystore | ❌ Falta | Crear nuevo |
| Supabase Config | ✅ (asumir) | Verificar URLs |
| Google Services | ❌ Falta | Descargar si usas Google Sign-In |

---

## 11. PRÓXIMOS PASOS ORDENADOS 📋

1. **Ahora:** Crear keystore (sección 5.1)
2. **Ahora:** Actualizar ApplicationId (sección 5.3)
3. **Ahora:** Agregar permisos en AndroidManifest.xml (sección 2.5)
4. **Ahora:** Configurar firma en build.gradle.kts (sección 5.2)
5. **Luego:** `flutter clean && flutter pub get`
6. **Luego:** `flutter doctor -v` para verificar
7. **Luego:** Conectar dispositivo Android
8. **Luego:** `flutter run -d android` (test)
9. **Luego:** `flutter build apk --release` (generar APK)
10. **Finalmente:** Instalar APK en dispositivo

---

**¿Necesitas ayuda con alguno de estos pasos? 🙋**

