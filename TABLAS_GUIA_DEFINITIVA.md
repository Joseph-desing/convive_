# 📋 TABLAS SUPABASE - GUÍA DEFINITIVA

## 🎯 LO QUE NECESITAS

Tu proyecto ConVive necesita **10 tablas** en Supabase para funcionar completamente.

Cada tabla tiene:
- ✅ Campos optimizados
- ✅ Relaciones correctas
- ✅ Índices para búsqueda rápida
- ✅ Seguridad (RLS policies)

---

## 📄 ARCHIVO PRINCIPAL: SQL_COMPLETO_SUPABASE.sql

**Este archivo contiene TODO lo que necesitas copiar y pegar en Supabase.**

### ¿Qué hace?
1. Crea 10 tablas
2. Crea 20+ índices
3. Configura 15+ políticas de seguridad
4. Todo listo para usarse inmediatamente

### ¿Cómo usarlo?
```
1. Abre: SQL_COMPLETO_SUPABASE.sql
2. Copia TODO (Ctrl+A)
3. Ve a Supabase → SQL Editor → New Query
4. Pega (Ctrl+V)
5. Haz click RUN
6. Espera: "Query executed successfully"
```

---

## 📊 LAS 10 TABLAS

### 1. **users** - Usuarios del Sistema
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  role TEXT (student/non_student/admin),
  subscription_type TEXT (free/premium),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
**Qué almacena:** Cuentas de usuario, rol, tipo de suscripción

### 2. **profiles** - Perfil de Usuario
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  user_id UUID (1:1 con users),
  full_name TEXT,
  birth_date DATE,
  gender TEXT (male/female/other),
  bio TEXT,
  profile_image_url TEXT,
  verified BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
**Qué almacena:** Información pública del usuario

### 3. **habits** - Hábitos y Preferencias (14 atributos)
```sql
CREATE TABLE habits (
  id UUID PRIMARY KEY,
  user_id UUID (1:1 con users),
  sleep_start TEXT,
  sleep_end TEXT,
  cleanliness_level INTEGER (1-10),
  noise_tolerance INTEGER (1-10),
  party_frequency INTEGER (0-7),
  guests_tolerance INTEGER (0-10),
  pets BOOLEAN,
  pet_tolerance BOOLEAN,
  alcohol_frequency INTEGER (0-7),
  work_mode TEXT (remote/presencial/hibrido),
  time_at_home INTEGER (0-10),
  communication_style TEXT,
  conflict_management TEXT,
  responsibility_level INTEGER (1-10),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
**Qué almacena:** Preferencias para algoritmo IA

### 4. **properties** - Propiedades/Departamentos
```sql
CREATE TABLE properties (
  id UUID PRIMARY KEY,
  owner_id UUID (∞:1 con users),
  title TEXT,
  description TEXT,
  price DECIMAL,
  latitude DECIMAL,
  longitude DECIMAL,
  address TEXT,
  available_from DATE,
  is_active BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
**Qué almacena:** Información de propiedades listadas

### 5. **property_images** - Imágenes de Propiedades
```sql
CREATE TABLE property_images (
  id UUID PRIMARY KEY,
  property_id UUID (∞:1 con properties),
  image_url TEXT,
  validated BOOLEAN,
  created_at TIMESTAMP
);
```
**Qué almacena:** URLs de imágenes (múltiples por propiedad)

### 6. **swipes** - Registro de Swipes
```sql
CREATE TABLE swipes (
  id UUID PRIMARY KEY,
  swiper_id UUID (∞:1 con users),
  target_user_id UUID (∞:1 con users),
  direction TEXT (like/dislike),
  created_at TIMESTAMP
);
```
**Qué almacena:** Cada like o dislike que hace un usuario

### 7. **matches** - Matches entre Usuarios
```sql
CREATE TABLE matches (
  id UUID PRIMARY KEY,
  user_a_id UUID (∞:1 con users),
  user_b_id UUID (∞:1 con users),
  compatibility_score DECIMAL (0-100),
  matched_at TIMESTAMP,
  created_at TIMESTAMP
);
```
**Qué almacena:** Matches mutuos (score calculado por IA)

### 8. **chats** - Conversaciones
```sql
CREATE TABLE chats (
  id UUID PRIMARY KEY,
  match_id UUID (1:1 con matches),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
**Qué almacena:** Conversaciones (1 por match)

### 9. **messages** - Mensajes en Chats (Tiempo Real)
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  chat_id UUID (∞:1 con chats),
  sender_id UUID (∞:1 con users),
  content TEXT,
  created_at TIMESTAMP
);
```
**Qué almacena:** Mensajes individuales (Realtime via WebSocket)

### 10. **subscriptions** - Suscripciones
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID (∞:1 con users),
  price DECIMAL,
  is_student BOOLEAN,
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  status TEXT (active/expired/cancelled),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```
**Qué almacena:** Información de suscripción del usuario

---

## 🔗 RELACIONES VISUALIZADAS

```
users (1)
  ├─→ (1) profiles              [1 usuario = 1 perfil]
  ├─→ (1) habits                [1 usuario = 1 set de hábitos]
  ├─→ (∞) properties            [1 usuario = múltiples propiedades]
  ├─→ (∞) swipes                [1 usuario = múltiples swipes]
  ├─→ (∞) matches               [1 usuario = múltiples matches]
  ├─→ (∞) subscriptions         [1 usuario = múltiples suscripciones]
  └─→ (∞) messages              [1 usuario = múltiples mensajes]

properties (1)
  ├─→ (∞) property_images       [1 propiedad = múltiples imágenes]
  └─→ (1) users [owner]         [cada propiedad tiene 1 dueño]

matches (1)
  └─→ (1) chats                 [1 match = 1 chat]

chats (1)
  └─→ (∞) messages              [1 chat = múltiples mensajes]
```

---

## 📈 ESTADÍSTICAS

- **Tablas:** 10
- **Campos totales:** 80+
- **Índices:** 20+
- **Políticas RLS:** 15+
- **Relaciones:** 15+
- **Constraints:** 30+

---

## 🔒 SEGURIDAD RLS

Cada tabla tiene políticas que garantizan:
- ✅ Solo ves tus datos (excepto público)
- ✅ No puedes modificar datos de otros
- ✅ Perfiles públicos para matching
- ✅ Mensajes privados entre participantes
- ✅ Propiedades filtrables por estado

---

## 💾 STORAGE BUCKETS

Además de las tablas, necesitas 2 buckets:

### 1. profiles/
```
Uso: Imágenes de perfil de usuarios
Ruta: profiles/{user_id}/photo.jpg
Público: SÍ
```

### 2. properties/
```
Uso: Imágenes de propiedades
Ruta: properties/{property_id}/image1.jpg
Público: SÍ
```

---

## ⚡ QUICK START

### Paso 1: Copiar SQL (2 minutos)
```bash
Abre: SQL_COMPLETO_SUPABASE.sql
Copia: TODO (Ctrl+A)
```

### Paso 2: Pegar en Supabase (1 minuto)
```
Ve a: https://supabase.com → Dashboard
→ Tu proyecto → SQL Editor → New Query
Pega: (Ctrl+V)
Run: Ctrl+Enter
```

### Paso 3: Crear Buckets (2 minutos)
```
Storage → Create bucket → "profiles" → Public
Storage → Create bucket → "properties" → Public
```

### Paso 4: Configurar Flutter (2 minutos)
```dart
// lib/config/app_config.dart
const String SUPABASE_URL = 'https://xxxxx.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...';
```

### Paso 5: Build Runner (2 minutos)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Total: ~10 minutos** ⏱️

---

## ✅ VERIFICACIÓN

Después de ejecutar el SQL, verifica en Supabase:

```sql
-- Ver tablas creadas (debería haber 10)
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

-- Ver índices (debería haber 20+)
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public';

-- Ver políticas RLS (debería haber 15+)
SELECT policyname FROM pg_policies 
WHERE schemaname = 'public';
```

---

## 🚀 YA ESTÁ

Una vez hayas:
- ✅ Ejecutado el SQL
- ✅ Creado los buckets
- ✅ Configurado Flutter
- ✅ Ejecutado build_runner

**Tu backend está 100% listo para desarrollo.** 🎉

---

## 📞 TROUBLESHOOTING

| Error | Solución |
|-------|----------|
| "Table already exists" | Ejecuta `DROP TABLE IF EXISTS` primero |
| "Cannot insert null" | Algún campo requerido está vacío |
| "Foreign key violation" | Intenta insertar ID que no existe |
| "RLS policy violation" | Debes estar autenticado o tener permisos |
| "Bucket not found" | Crea el bucket manualmente en Storage |

---

## 📁 ARCHIVOS RELACIONADOS

- `SQL_COMPLETO_SUPABASE.sql` - El SQL (copiar-pegar directo)
- `CREAR_TABLAS_SUPABASE.md` - Guía detallada paso a paso
- `CHECKLIST_FINAL.md` - Checklist completo del proyecto
- `EMPEZAR_AHORA.md` - Resumen ejecutivo rápido

---

**¡Listo! Solo necesitas copiar y pegar el SQL. 📋**
