# 📋 ARQUITECTURA IMPLEMENTADA - ConVive

## ✅ Lo que se implementó

### 1. **Estructura de Carpetas Profesional**
```
lib/
├── config/          → Configuración de servicios
├── models/          → Modelos de datos (11 modelos)
├── services/        → Capa de servicios (5 servicios)
├── providers/       → Gestión de estado (4 providers)
├── screens/         → Pantallas de la app
├── widgets/         → Componentes reutilizables
├── constants/       → Constantes de la app
├── theme/           → Temas y estilos
└── utils/           → Funciones útiles
```

### 2. **Modelos de Datos Completos (ER Mapping)**
✅ User - Autenticación y roles
✅ Profile - Datos del usuario
✅ Habits - Atributos para compatibilidad (14 campos)
✅ Property - Departamentos/habitaciones
✅ PropertyImage - Imágenes de propiedades
✅ Swipe - Registrar likes/dislikes
✅ Match - Compatibilidad calculada
✅ Chat - Conversaciones
✅ Message - Mensajes del chat
✅ Subscription - Planes (free/premium)

Todos con:
- JSON serialization listo
- UUIDs únicos
- Timestamps automáticos
- Métodos copyWith()

### 3. **Servicios Supabase Completos**
✅ **SupabaseAuthService** - Auth, registro, login
✅ **SupabaseDatabaseService** - CRUD para todas las tablas
✅ **SupabaseRealtimeService** - Chat en tiempo real
✅ **SupabaseStorageService** - Upload de imágenes

### 4. **Servicio de IA**
✅ **AIService** - Llamadas al microservicio Python
  - Calcular compatibilidad (score 0-100)
  - Validar imágenes de perfil
  - Validar imágenes de propiedades
  - Detectar anomalías/perfiles sospechosos
  - Obtener recomendaciones personalizadas

### 5. **Gestión de Estado con Provider**
✅ **AuthProvider** - Autenticación y sesión
✅ **UserProvider** - Datos del usuario y perfil
✅ **MatchingProvider** - Matches, swipes, compatibilidad
✅ **PropertyProvider** - Propiedades, CRUD

### 6. **Configuración Centralizada**
✅ AppConfig - URLs y keys
✅ SupabaseProvider - Inyección de dependencias
✅ AIServiceProvider - Inyección de IA

### 7. **Documentación Completa**
✅ README.md actualizado con toda la arquitectura
✅ Stack tecnológico documentado
✅ Flujo de compatibilidad explicado
✅ Instrucciones de configuración

## 🔧 Próximos Pasos

### 1️⃣ **Configurar Supabase**
```bash
# 1. Crear cuenta en supabase.com
# 2. Actualizar credenciales en lib/config/app_config.dart
# 3. Crear tablas en PostgreSQL (SQL proporcionado abajo)
# 4. Configurar RLS (Row Level Security)
# 5. Configurar buckets de storage
```

### 2️⃣ **Generar archivos JSON serialization**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3️⃣ **Instalar dependencias**
```bash
flutter pub get
```

### 4️⃣ **Configurar Microservicio IA**
```bash
# El microservicio Python debe estar ejecutándose
# URL: http://localhost:8000
# Endpoints: /compatibility-score, /validate-profile-image, /validate-property-image
```

### 5️⃣ **Implementar pantallas con los providers**
```dart
// Ejemplo de uso en las screens:
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isLoading) return CircularProgressIndicator();
    return Text('Usuario: ${authProvider.currentUser?.email}');
  },
)
```

### 6️⃣ **Integrar OneSignal para notificaciones**
```dart
// En main.dart después de Supabase init:
await OneSignal.initialize("APP_ID");
```

### 7️⃣ **Implementar navegación con GoRouter**
```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    // ...
  ],
);
```

## 📊 SQL para crear tablas en Supabase

```sql
-- USERS
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  role ENUM ('student', 'non_student', 'admin'),
  subscription_type ENUM ('free', 'premium'),
  created_at TIMESTAMP DEFAULT now()
);

-- PROFILES
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  full_name VARCHAR NOT NULL,
  birth_date DATE,
  gender ENUM ('male', 'female', 'other'),
  bio TEXT,
  profile_image_url TEXT,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

-- HABITS
CREATE TABLE habits (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  sleep_start INT DEFAULT 23,
  sleep_end INT DEFAULT 7,
  cleanliness_level INT DEFAULT 5,
  noise_tolerance INT DEFAULT 5,
  party_frequency INT DEFAULT 3,
  guests_tolerance INT DEFAULT 5,
  pets BOOLEAN DEFAULT FALSE,
  pet_tolerance INT DEFAULT 5,
  alcohol_frequency INT DEFAULT 3,
  work_mode ENUM ('remote', 'office', 'hybrid'),
  time_at_home INT DEFAULT 50,
  communication_style INT DEFAULT 5,
  conflict_management INT DEFAULT 5,
  responsibility_level INT DEFAULT 5,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

-- PROPERTIES
CREATE TABLE properties (
  id UUID PRIMARY KEY,
  owner_id UUID REFERENCES users(id),
  title VARCHAR NOT NULL,
  description TEXT,
  price DECIMAL NOT NULL,
  latitude DECIMAL,
  longitude DECIMAL,
  address TEXT,
  available_from DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

-- PROPERTY_IMAGES
CREATE TABLE property_images (
  id UUID PRIMARY KEY,
  property_id UUID REFERENCES properties(id),
  image_url TEXT NOT NULL,
  validated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now()
);

-- SWIPES
CREATE TABLE swipes (
  id UUID PRIMARY KEY,
  swiper_id UUID REFERENCES users(id),
  target_user_id UUID REFERENCES users(id),
  direction ENUM ('like', 'dislike'),
  created_at TIMESTAMP DEFAULT now()
);

-- MATCHES
CREATE TABLE matches (
  id UUID PRIMARY KEY,
  user_a UUID REFERENCES users(id),
  user_b UUID REFERENCES users(id),
  compatibility_score DECIMAL,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

-- CHATS
CREATE TABLE chats (
  id UUID PRIMARY KEY,
  match_id UUID REFERENCES matches(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

-- MESSAGES
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  chat_id UUID REFERENCES chats(id),
  sender_id UUID REFERENCES users(id),
  content TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

-- SUBSCRIPTIONS
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  price DECIMAL,
  is_student BOOLEAN,
  start_date DATE,
  end_date DATE,
  status ENUM ('active', 'expired', 'cancelled'),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);
```

## 🚀 Checklist de implementación

- [ ] Configurar Supabase (URL, keys, SQL)
- [ ] Generar JSON serialization (`build_runner`)
- [ ] Instalar dependencias (`flutter pub get`)
- [ ] Implementar pantallas con Providers
- [ ] Integrar OneSignal
- [ ] Configurar GoRouter para navegación
- [ ] Testear flujo de autenticación
- [ ] Testear matching y compatibilidad
- [ ] Testear chat en tiempo real
- [ ] Deploy en TestFlight/PlayStore

## 📚 Recursos

- [Supabase Docs](https://supabase.com/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Flutter Docs](https://flutter.dev/docs)
- [JSON Serialization](https://flutter.dev/docs/development/data-and-backend/json)

## 💡 Notas Importantes

1. **Seguridad**: Todas las operaciones en Supabase deben usar RLS (Row Level Security)
2. **Escalabilidad**: El microservicio IA debe ser stateless
3. **Performance**: Usa índices en PostgreSQL para búsquedas geográficas
4. **Caching**: Implementa Redis en el backend para cachear compatibilidades
5. **Moderation**: El microservicio IA debe validar imágenes y detectar perfiles fake

---

**Arquitectura completada por:** GitHub Copilot  
**Fecha:** 20 de enero de 2026  
**Version:** 1.0.0
