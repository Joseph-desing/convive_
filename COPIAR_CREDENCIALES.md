# 📸 DÓNDE COPIAR LAS CREDENCIALES - Con Capturas de Texto

## 🔴 PASO 1: Ve a tu Proyecto en Supabase

```
1. Abre: https://supabase.com
2. Inicia sesión con tu cuenta
3. Haz click en tu proyecto "ConVive"
```

---

## 🟠 PASO 2: Ve a Settings (Configuración)

### En el menú izquierdo, busca:
```
┌─────────────────────┐
│ Supabase           │
├─────────────────────┤
│ 📊 Analytics        │
│ 🔐 Authentication   │
│ 🗄️ SQL Editor       │
│ 📁 Storage          │
│ ⚙️ Settings         │ ← AQUÍ
└─────────────────────┘
```

---

## 🟡 PASO 3: Dentro de Settings, ve a API

```
Settings (Configuración)
├─ Información General
├─ Database
├─ API                     ← AQUÍ
├─ Auth
├─ Facturación
└─ ...
```

---

## 🟢 PASO 4: Copia las Credenciales

Verás algo así:

```
┌─────────────────────────────────────────────────────┐
│ API Settings                                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Project URL:                                        │
│ ┌─────────────────────────────────────────────────┐ │
│ │ https://kvhwlbgkfjdshkf.supabase.co             │ │
│ │ [Copy button]                                   │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ Anon Public Key:                                    │
│ ┌─────────────────────────────────────────────────┐ │
│ │ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...       │ │
│ │ [Copy button]                                   │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ Service Role Key (Secreto - NO uses esto):         │
│ ┌─────────────────────────────────────────────────┐ │
│ │ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...       │ │
│ │ [Copy button]                                   │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### ✅ Copia ESTOS DOS:
1. **Project URL** → Ejemplo: `https://kvhwlbgkfjdshkf.supabase.co`
2. **Anon Public Key** → Ejemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### ❌ NO copies:
- ❌ Service Role Key (es secreto)

---

## 🔵 PASO 5: Abre Flutter Code

Abre tu proyecto en VS Code:

```
c:\Users\HP\Desktop\convive_\
├── lib\
│   ├── config\
│   │   └── app_config.dart    ← AQUÍ
│   └── ...
```

---

## 🟣 PASO 6: Reemplaza las Credenciales

Abre: `lib/config/app_config.dart`

### BUSCA ESTO:
```dart
// ============ CONFIGURACIÓN DE SUPABASE ============
const String SUPABASE_URL = 'https://tu-proyecto.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...';
```

### REEMPLAZA CON TUS VALORES:

```dart
// ============ CONFIGURACIÓN DE SUPABASE ============
// Copiar de: https://supabase.com → Tu proyecto → Settings → API

const String SUPABASE_URL = 'https://kvhwlbgkfjdshkf.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2aHdsYmdra2ZqZHNoayIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzAzMDAwMDAwLCJleHAiOjE5MzAwMDAwMDB9';
```

---

## 📝 VERIFICACIÓN

Asegúrate que:

- ✅ `SUPABASE_URL` empieza con `https://`
- ✅ `SUPABASE_URL` termina con `.supabase.co`
- ✅ `SUPABASE_ANON_KEY` es muy largo (está bien, es normal)
- ✅ Ambos están entre comillas simples `'...'`

---

## 🎯 RESULTADO FINAL

Tu archivo debería verse así:

```dart
class AppConfig {
  // ============ CONFIGURACIÓN DE SUPABASE ============
  
  static const String supabaseUrl = 'https://kvhwlbgkfjdshkf.supabase.co';
  
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2aHdsYmdra2ZqZHNoayIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzAzMDAwMDAwLCJleHAiOjE5MzAwMDAwMDB9';
  
  // ============ CONFIGURACIÓN DE IA ============
  
  static const String aiServiceUrl = 'http://localhost:8000';
  
  // ... resto de config
}
```

---

## ⚡ PRÓXIMO: Build Runner

Una vez pegadas las credenciales:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🎉 LISTO

Ya está conectado a Supabase. Ahora ejecuta:

```bash
flutter run
```

¡Y prueba a registrarte! 🚀
