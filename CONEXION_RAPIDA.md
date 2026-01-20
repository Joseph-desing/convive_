# ✅ CONECTAR SUPABASE - GUÍA RÁPIDA (3 PASOS)

## 🎯 OBJETIVO
Conectar tu Flutter app con tu proyecto Supabase para que funcione el backend.

---

## ⏱️ TIEMPO: 5 MINUTOS

### Paso 1️⃣: Obtener Credenciales (2 minutos)

```
1. Abre: https://supabase.com
2. Dashboard → Tu proyecto "ConVive"
3. Menú izquierdo: Settings
4. Settings → API
5. Copia dos valores:
   - Project URL (ej: https://xxxxx.supabase.co)
   - Anon Public Key (ej: eyJ...)
```

**¿Dónde están exactamente?**

En la pantalla de Settings → API verás:
```
Project URL: https://kvhwlbgkfjdshkf.supabase.co  ← COPIA ESTO
Anon Public Key: eyJhbGciOiJIUzI1NiIsInR5cCI6... ← COPIA ESTO
Service Role Key: eyJ... ← NO COPIES ESTO (es secreto)
```

---

### Paso 2️⃣: Pegar en Flutter (2 minutos)

Abre: `lib/config/app_config.dart`

**BUSCA:**
```dart
const String SUPABASE_URL = 'https://tu-proyecto.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...';
```

**REEMPLAZA CON:**
```dart
const String SUPABASE_URL = 'https://kvhwlbgkfjdshkf.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**Guarda el archivo (Ctrl+S)**

---

### Paso 3️⃣: Ejecutar Build Runner (1 minuto)

Terminal en la carpeta del proyecto:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Espera a ver: "Succeeded after XXX ms"

---

## 🚀 EJECUTAR

```bash
flutter run
```

---

## ✅ VERIFICAR QUE FUNCIONA

1. La app abre sin errores
2. Ve a LoginScreen
3. Haz click en "Registrarse"
4. Llena el formulario:
   - Email: test@example.com
   - Contraseña: Test123456
   - Nombre: Test User
5. Haz click "Crear Cuenta"

**Verifica en Supabase:**
- Ve a: https://supabase.com → Tu proyecto
- Authentication (menú izquierdo)
- Users
- **Deberías ver: test@example.com**

Si lo ves → ✅ **¡FUNCIONA!**
Si no lo ves → ❌ Ver troubleshooting abajo

---

## 🆘 TROUBLESHOOTING

### Si ves: "Cannot connect to Supabase"

**Solución:**
1. Abre `lib/config/app_config.dart`
2. Verifica que la URL empiece con `https://`
3. Verifica que termine con `.supabase.co`
4. Copia la Anon Key de NUEVO desde Supabase
5. Reemplaza en el código
6. Ejecuta `flutter run` de nuevo

### Si ves: "Invalid API key"

**Solución:**
1. Ve a Supabase → Settings → API
2. Regenera la clave
3. Copia la nueva
4. Reemplaza en `app_config.dart`
5. Ejecuta `flutter run`

### Si ves: "xxx.g.dart no existe"

**Solución:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Si sigue fallando:
```bash
rm -r .dart_tool/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📋 CHECKLIST

- [ ] Copié URL de Supabase
- [ ] Copié Anon Key de Supabase
- [ ] Reemplacé en `app_config.dart`
- [ ] Ejecuté `flutter pub run build_runner build`
- [ ] Ejecuté `flutter run`
- [ ] Creé usuario de prueba
- [ ] Lo veo en Supabase Authentication

Si todo está ✅, **¡YA ESTÁ CONECTADO!**

---

## 📚 DOCUMENTACIÓN COMPLETA

Para más detalles, ver:
- `CONECTAR_SUPABASE.md` - Guía completa con troubleshooting
- `COPIAR_CREDENCIALES.md` - Dónde buscar las credenciales
- `CREAR_TABLAS_SUPABASE.md` - Cómo crear las tablas

---

## 🎯 PRÓXIMO PASO

Una vez conectado:
1. Actualizar LoginScreen para usar AuthProvider
2. Actualizar HomeScreen para cargar propiedades
3. Probar swiping y matching
4. Probar chat en tiempo real

Ver: `INTEGRACION_DISENO.md`

---

**¡Eso es todo! Ya está funcionando. 🎉**
