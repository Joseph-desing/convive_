# 🗄️ CREAR TABLAS EN SUPABASE - Guía Paso a Paso

## ✅ ANTES DE EMPEZAR

- [ ] Supabase proyecto creado
- [ ] URL y Anon Key copiados a `lib/config/app_config.dart`
- [ ] Tienes el SQL script (`SQL_COMPLETO_SUPABASE.sql`)

---

## 📋 PASO 1: Abre el SQL Editor de Supabase

1. Ve a https://supabase.com → Dashboard
2. Selecciona tu proyecto
3. En el menú izquierdo → **SQL Editor**
4. Haz click en **New Query**

---

## 📋 PASO 2: Copia el SQL Completo

### Opción A: Copiar todo el archivo (Recomendado)
```
1. Abre: SQL_COMPLETO_SUPABASE.sql
2. Ctrl+A → Copiar todo
3. En Supabase SQL Editor → Pega
4. Haz click en "Run" (o Ctrl+Enter)
```

### Opción B: Copiar solo las tablas (Si hay problemas)
Copia esta sección completa:

```sql
-- ============ COPY DESDE AQUÍ ============

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'non_student', 'admin')) DEFAULT 'student',
  subscription_type TEXT DEFAULT 'free',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  birth_date DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  bio TEXT,
  profile_image_url TEXT,
  verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  sleep_start TEXT DEFAULT '22:00',
  sleep_end TEXT DEFAULT '07:00',
  cleanliness_level INTEGER CHECK (cleanliness_level >= 1 AND cleanliness_level <= 10) DEFAULT 5,
  noise_tolerance INTEGER CHECK (noise_tolerance >= 1 AND noise_tolerance <= 10) DEFAULT 5,
  party_frequency INTEGER CHECK (party_frequency >= 0 AND party_frequency <= 7) DEFAULT 0,
  guests_tolerance INTEGER CHECK (guests_tolerance >= 0 AND guests_tolerance <= 10) DEFAULT 5,
  pets BOOLEAN DEFAULT FALSE,
  pet_tolerance BOOLEAN DEFAULT FALSE,
  alcohol_frequency INTEGER CHECK (alcohol_frequency >= 0 AND alcohol_frequency <= 7) DEFAULT 0,
  work_mode TEXT CHECK (work_mode IN ('remote', 'presencial', 'hibrido')) DEFAULT 'presencial',
  time_at_home INTEGER CHECK (time_at_home >= 0 AND time_at_home <= 10) DEFAULT 5,
  communication_style TEXT,
  conflict_management TEXT,
  responsibility_level INTEGER CHECK (responsibility_level >= 1 AND responsibility_level <= 10) DEFAULT 5,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address TEXT NOT NULL,
  available_from DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS property_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  validated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS swipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  compatibility_score DECIMAL(5, 2) CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
  matched_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(user_a_id, user_b_id),
  CHECK (user_a_id != user_b_id)
);

CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  price DECIMAL(10, 2) NOT NULL,
  is_student BOOLEAN DEFAULT FALSE,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ============ COPY HASTA AQUÍ ============
```

---

## 📋 PASO 3: Ejecuta el Script

En Supabase SQL Editor:
1. Pega el SQL
2. Haz click en **"Run"** o presiona **Ctrl+Enter**
3. Espera a que termine (unos 5-10 segundos)

### ✅ Si ves esto: "Query executed successfully"
- Significa que **TODO está perfecto** ✅

### ❌ Si ves error, son estos comunes:

#### Error: "relation already exists"
```
→ Las tablas ya existen de un intento anterior
→ Solución: Haz click en "Drop table" para cada una
  O usa: DROP TABLE IF EXISTS (ya está en el script)
```

#### Error: "syntax error"
```
→ Falta una coma o comilla
→ Solución: Revisa la línea que reporta el error
```

#### Error: "permission denied"
```
→ Tu usuario no tiene permisos
→ Solución: Ve a Configuración → Authentication → Ve si estás como admin
```

---

## 📋 PASO 4: Crea los Storage Buckets

Después de crear las tablas, crea 2 buckets para imágenes:

### 1. Bucket: profiles

1. Ve a **Storage** (menú izquierdo)
2. Haz click en **"Create bucket"**
3. Nombre: `profiles`
4. **Public bucket**: MARCA ✅
5. Haz click en **"Create bucket"**

### 2. Bucket: properties

1. Haz click en **"Create bucket"** de nuevo
2. Nombre: `properties`
3. **Public bucket**: MARCA ✅
4. Haz click en **"Create bucket"**

---

## 📋 PASO 5: Verifica que Todo Está Bien

### En SQL Editor, ejecuta estas queries:

```sql
-- Ver todas las tablas (debería haber 10)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

Debería devolver:
```
chats
habits
matches
messages
properties
property_images
profiles
subscriptions
swipes
users
```

### Ver índices creados:
```sql
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;
```

---

## 🔒 PASO 6: Verifica Row Level Security

```sql
-- Ver políticas RLS
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

Debería haber muchas políticas (15+)

---

## 📊 RESUMEN DE LO QUE SE CREÓ

### ✅ 10 Tablas
1. **users** - Usuarios del sistema
2. **profiles** - Perfil de usuario
3. **habits** - Hábitos y preferencias
4. **properties** - Propiedades/departamentos
5. **property_images** - Imágenes de propiedades
6. **swipes** - Registro de swipes (like/dislike)
7. **matches** - Matches entre usuarios
8. **chats** - Conversaciones
9. **messages** - Mensajes en chats
10. **subscriptions** - Suscripciones de usuarios

### ✅ 20+ Índices
Para optimizar búsquedas y filtrados

### ✅ 15+ Políticas RLS
Para seguridad (cada usuario solo ve sus datos)

### ✅ 2 Storage Buckets
- `profiles/` - Imágenes de perfil
- `properties/` - Imágenes de propiedades

---

## 🎯 PRÓXIMO PASO

Una vez creadas las tablas:

1. **Configura las credenciales en Flutter:**
   ```dart
   // lib/config/app_config.dart
   const String SUPABASE_URL = 'https://xxxxx.supabase.co';
   const String SUPABASE_ANON_KEY = 'eyJ...';
   ```

2. **Ejecuta el generador de código:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Prueba la conexión:**
   ```bash
   flutter run
   ```

---

## ⚠️ IMPORTANTE

### Credenciales
- **NUNCA** exposas el `SUPABASE_ANON_KEY` en GitHub
- Úsalo solo en desarrollo
- Para producción, usa variables de entorno

### RLS Policies
- Las políticas están HABILITADAS
- Los usuarios solo pueden ver/modificar sus propios datos
- Es seguro por defecto

### Backups
- Supabase hace backups automáticos
- Pero SIEMPRE haz backup manual antes de cambios importantes

---

## 🆘 TROUBLESHOOTING

| Problema | Solución |
|----------|----------|
| "Bucket already exists" | Los buckets ya existen, puedes ignorar |
| "Table already exists" | Ejecuta DROP TABLE primero, o copia sin IF NOT EXISTS |
| "Foreign key violation" | Asegúrate de que las tablas madre existen primero |
| "Cannot insert null" | Algún campo obligatorio está vacío |
| "RLS policy violation" | El usuario no tiene permisos (deberías estar autenticado) |

---

## 📞 VERIFICACIÓN FINAL

Si todo funciona:
- ✅ 10 tablas creadas
- ✅ Índices optimizados
- ✅ RLS políticas activas
- ✅ 2 buckets de almacenamiento
- ✅ Listo para Flutter

¡Ahora puedes conectar Flutter a Supabase y empezar con el desarrollo! 🚀
