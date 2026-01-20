# 🔗 CONECTAR FLUTTER CON SUPABASE - Guía Paso a Paso

## ✅ REQUISITOS PREVIOS

- [ ] Proyecto Supabase creado
- [ ] Tablas creadas (SQL ejecutado)
- [ ] Flutter pub get ejecutado

---

## 📋 PASO 1: Obtener Credenciales de Supabase

### 1.1 Abre Supabase
```
https://supabase.com → Dashboard → Tu Proyecto
```

### 1.2 Ve a Configuración (Settings)
```
Menú izquierdo → Configuración (o Settings) → API
```

### 1.3 Copia Tus Credenciales

Verás dos valores:

**1. Project URL**
```
Búscalo en: Settings → API → Project URL
Ejemplo: https://xxxxx.supabase.co
Selecciona TODO y cópialo
```

**2. Anon Public Key**
```
Búscalo en: Settings → API → Anon Public Key
Ejemplo: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Selecciona TODO y cópialo
```

---

## 📋 PASO 2: Pega las Credenciales en Flutter

### 2.1 Abre este archivo
```
lib/config/app_config.dart
```

### 2.2 Busca esto
```dart
const String SUPABASE_URL = 'https://tu-proyecto.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...tu-clave...';
```

### 2.3 Reemplaza con tus valores

**ANTES:**
```dart
const String SUPABASE_URL = 'https://xxxxx.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...';
```

**DESPUÉS (tu proyecto):**
```dart
const String SUPABASE_URL = 'https://kvhwlbgkfjdshkf.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2aHdsYmdra2ZqZHNoayIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzAzMDAwMDAwLCJleHAiOjE5MzAwMDAwMDB9...';
```

**⚠️ IMPORTANTE:**
- ✅ URL termina con `.supabase.co`
- ✅ ANON_KEY es muy largo (no importa)
- ✅ Ambos deben estar entre comillas simples `'...'`

---

## 📋 PASO 3: Ejecutar build_runner

Este paso genera el código para que los modelos funcionen:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Espera a ver:**
```
[INFO] Building with these concrete examples:
[INFO]  - habits|lib/models/habits.g.dart
[INFO]  - property|lib/models/property.g.dart
[INFO]  - user|lib/models/user.g.dart
... (y más)
[INFO] Succeeded after XXX ms
```

---

## 📋 PASO 4: Ejecutar la App

```bash
flutter run
```

Selecciona el dispositivo/emulador y espera a que compile.

---

## ✅ PASO 5: Probar la Conexión

### 5.1 Abre la app
La app debería abrir sin errores de Supabase

### 5.2 Ve a LoginScreen
Toca el botón "Registrarse" (Sign Up)

### 5.3 Intenta registrarte
```
Email: test@example.com
Contraseña: Test123456
Nombre: Test User
```

### 5.4 Haz click en "Crear Cuenta"

### 5.5 Verifica en Supabase

**En Supabase Dashboard:**
1. Ve a **Authentication** (menú izquierdo)
2. Haz click en **Users**
3. Deberías ver tu usuario: `test@example.com`

**Si lo ves:**
✅ **¡La conexión funciona!**

**Si NO lo ves:**
❌ Ve a "Troubleshooting" más abajo

---

## 🔍 VERIFICACIÓN DETALLADA

### Ver que los datos se guardan

1. En Supabase → **Authentication** → **Users**
   - Deberías ver: `test@example.com`

2. En Supabase → **SQL Editor** → **New Query**
   - Ejecuta:
   ```sql
   SELECT * FROM users LIMIT 1;
   SELECT * FROM profiles LIMIT 1;
   SELECT * FROM habits LIMIT 1;
   ```
   - Deberías ver los datos del usuario que creaste

---

## 🛑 TROUBLESHOOTING

### ❌ Error: "Cannot connect to Supabase"

**Síntoma:**
```
MissingPluginException: No implementation found
```

**Causa:** Credenciales incorrectas

**Solución:**
1. Abre `lib/config/app_config.dart`
2. Copia las credenciales de Supabase DE NUEVO
3. Asegúrate que:
   - URL empiece con `https://`
   - URL termine con `.supabase.co`
   - ANON_KEY sea el valor completo (muy largo)
4. Guarda el archivo
5. Ejecuta `flutter run` de nuevo

---

### ❌ Error: "Invalid API key"

**Síntoma:**
```
PostgrestException: 401 Unauthorized
```

**Causa:** ANON_KEY incorrecta o vencida

**Solución:**
1. Ve a Supabase → Settings → API
2. Regenera la clave (si está comprometida)
3. Copia la nueva
4. Reemplaza en `app_config.dart`
5. Ejecuta `flutter run`

---

### ❌ Error: "xxx.g.dart no encontrado"

**Síntoma:**
```
Error: The file 'lib/models/user.g.dart' does not exist
```

**Causa:** Build runner no se ejecutó o falló

**Solución:**
```bash
# Opción 1: Build de nuevo
flutter pub run build_runner build --delete-conflicting-outputs

# Opción 2: Si persiste, limpia todo
rm -r .dart_tool/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### ❌ Error: "Network error"

**Síntoma:**
```
SocketException: Failed host lookup
```

**Causa:** Sin internet o URL incorrecta

**Solución:**
1. Verifica que tengas internet
2. En emulador Android, la URL debe ser:
   ```dart
   const String SUPABASE_URL = 'http://10.0.2.2:3000'; // Si es local
   // O tu URL real de Supabase (https://xxxxx.supabase.co)
   ```
3. En emulador iOS:
   ```dart
   const String SUPABASE_URL = 'http://localhost:3000'; // Si es local
   ```

---

### ❌ Error: "User already exists"

**Síntoma:**
```
AuthException: User already registered
```

**Causa:** Intentaste registrarte con el mismo email

**Solución:**
- Usa un email diferente la próxima vez
- O ve a Supabase → Authentication → Selecciona usuario → Delete

---

### ❌ Error: "RLS policy violation"

**Síntoma:**
```
PostgrestException: new row violates row-level security policy
```

**Causa:** Las políticas RLS están rechazando la operación

**Solución:**
1. Asegúrate que estés autenticado
2. Verifica que los datos sean válidos
3. En desarrollo, puedes desactivar RLS temporalmente:
   ```sql
   ALTER TABLE users DISABLE ROW LEVEL SECURITY;
   ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
   -- ... etc
   ```

---

## 📝 INFORMACIÓN A TENER A MANO

### URL de Supabase
```
Formato: https://xxxxx.supabase.co
Ubicación: Settings → API → Project URL
```

### ANON KEY
```
Formato: eyJhbGciOi...
Ubicación: Settings → API → Anon Public Key
Longitud: Muy largo (no importa el número exacto)
```

### DATABASE PASSWORD
```
Ubicación: Settings → Database → Database Password
IMPORTANTE: NO lo uses en la app, solo para admin
```

---

## 🔐 SEGURIDAD

### ✅ HACED ESTO:
- ✅ Usa credenciales en `app_config.dart` (desarrollo)
- ✅ Para producción, usa variables de entorno
- ✅ El ANON_KEY es público, no pasa nada
- ✅ El DATABASE_PASSWORD es secreto, no lo uses en app

### ❌ NO HAGAS ESTO:
- ❌ No subas `app_config.dart` a GitHub público
- ❌ No compartas el DATABASE_PASSWORD
- ❌ No uses credenciales diferentes en cada dispositivo
- ❌ No pongas la contraseña de admin en la app

---

## 🔄 FLUJO COMPLETO DE CONEXIÓN

```
1. Obtener credenciales de Supabase ✅
   ↓
2. Pegar en app_config.dart ✅
   ↓
3. Ejecutar build_runner ✅
   ↓
4. flutter run ✅
   ↓
5. Probar registro/login ✅
   ↓
6. Ver datos en Supabase ✅
   ↓
7. ¡LISTO! Ya está conectado 🎉
```

---

## 📊 VERIFICACIÓN FINAL

Ejecuta esta checklist para confirmar:

- [ ] Tengo URL de Supabase (https://xxxxx.supabase.co)
- [ ] Tengo ANON_KEY (eyJ...)
- [ ] Reemplacé en `app_config.dart`
- [ ] Ejecuté `flutter pub run build_runner build`
- [ ] Ejecuté `flutter run` sin errores
- [ ] Creé usuario de prueba
- [ ] Lo veo en Supabase → Authentication → Users
- [ ] Puedo hacer login

Si todo está marcado ✅, **¡LA CONEXIÓN ESTÁ FUNCIONANDO!**

---

## 🚀 PRÓXIMO PASO

Una vez conectado:

1. **Actualizar LoginScreen** para usar AuthProvider
2. **Actualizar HomeScreen** para cargar propiedades
3. **Probar swiping y matching**
4. **Probar chat en tiempo real**

Ver: `INTEGRACION_DISENO.md` para estos pasos

---

## 📞 RESUMEN RÁPIDO

```
¿Qué necesito?
→ URL y ANON_KEY de Supabase

¿Dónde los pongo?
→ lib/config/app_config.dart

¿Cómo compruebo que funciona?
→ Crea usuario, míralo en Supabase Authentication

¿Si falla?
→ Ver Troubleshooting arriba
```

**¡Eso es todo! Ya está conectado. 🔗**
