# ConVive - App de Compañeros/as de Vivienda con IA

**ConVive** es una aplicación mobile que conecta estudiantes y profesionales para encontrar compañeros/as de vivienda compatibles usando inteligencia artificial. La app utiliza algoritmos de compatibilidad basados en hábitos de vida para hacer matches precisos.

## 📋 Tabla de Contenidos

- [Arquitectura Técnica](#arquitectura-técnica)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Configuración](#configuración)
- [Desarrollo](#desarrollo)
- [Deployment](#deployment)

## 🏗️ Arquitectura Técnica

### Visión General

```
┌─────────────────┐
│  Flutter App    │ (Frontend)
│   - UI/UX       │
│   - Gestión Local│
└────────┬────────┘
         │
         ├─────────────────────────────────────┐
         │                                     │
┌────────▼─────────┐              ┌──────────▼──────────┐
│   Supabase       │              │  Microservicio IA   │
│  ┌────────────┐  │              │  (Python + FastAPI) │
│  │ Auth       │  │              │  ┌──────────────┐   │
│  │ PostgreSQL │  │              │  │ Compatibilidad   │
│  │ Realtime   │  │              │  │ Validación IMG   │
│  │ Storage    │  │              │  │ Anomalías    │   │
│  └────────────┘  │              │  └──────────────┘   │
└───────────────────┘              └────────────────────┘
```

### Stack Tecnológico

**Frontend (Flutter):**
- `provider` - Gestión de estado
- `go_router` - Navegación
- `supabase_flutter` - Backend
- `http` - Llamadas al microservicio de IA
- `cached_network_image` - Imágenes
- `geolocator` - Ubicación
- `onesignal_flutter` - Notificaciones

**Backend (Supabase):**
- PostgreSQL - Base de datos relacional
- Auth - Autenticación email/OAuth
- Realtime - Chat y notificaciones en tiempo real
- Storage - Imágenes y media
- Edge Functions - Lógica serverless

**Microservicio IA (Python):**
- FastAPI - Framework web
- scikit-learn - Algoritmos de compatibilidad
- OpenCV - Validación de imágenes
- Redis - Caché

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
│
├── config/                   # Configuración
│   ├── app_config.dart
│   ├── supabase_provider.dart
│   └── ai_service_provider.dart
│
├── models/                   # Modelos de datos (ER Mapping)
│   ├── user.dart
│   ├── profile.dart
│   ├── habits.dart
│   ├── property.dart
│   ├── property_image.dart
│   ├── swipe.dart
│   ├── match.dart
│   ├── chat.dart
│   ├── message.dart
│   ├── subscription.dart
│   └── index.dart
│
├── services/                 # Capa de servicios
│   ├── supabase_auth_service.dart
│   ├── supabase_database_service.dart
│   ├── supabase_realtime_service.dart
│   ├── supabase_storage_service.dart
│   ├── ai_service.dart
│   └── index.dart
│
├── providers/                # Gestión de estado
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── matching_provider.dart
│   ├── property_provider.dart
│   └── index.dart
│
├── screens/                  # Pantallas
│   ├── splash_screen.dart
│   ├── welcome_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   └── ...
│
├── widgets/                  # Componentes reutilizables
│   ├── property_card.dart
│   ├── bottom_nav_bar.dart
│   └── ...
│
├── constants/                # Constantes
│   ├── app_strings.dart
│   └── app_dimensions.dart
│
├── theme/                    # Temas y estilos
│   ├── app_theme.dart
│   └── colors.dart
│
└── utils/                    # Utilidades
    ├── colors.dart
    └── extensions.dart
```

## 🗄️ Modelo de Datos (ER)

### Tablas Principales

#### `users`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | PK |
| email | VARCHAR | Email único |
| role | ENUM | student\|non_student\|admin |
| subscription_type | ENUM | free\|premium |
| created_at | TIMESTAMP | - |

#### `profiles`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users.id |
| full_name | VARCHAR | Nombre completo |
| birth_date | DATE | Fecha de nacimiento |
| gender | ENUM | male\|female\|other |
| bio | TEXT | Biografía |
| profile_image_url | TEXT | URL de foto |
| verified | BOOLEAN | Perfil verificado |
| created_at | TIMESTAMP | - |

#### `habits`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK → users.id |
| sleep_start | INT | Hora (0-23) |
| sleep_end | INT | Hora (0-23) |
| cleanliness_level | INT | 1-10 |
| noise_tolerance | INT | 1-10 |
| party_frequency | INT | 1-10 |
| guests_tolerance | INT | 1-10 |
| pets | BOOLEAN | Tiene mascotas |
| pet_tolerance | INT | 1-10 |
| alcohol_frequency | INT | 1-10 |
| work_mode | ENUM | remote\|office\|hybrid |
| ... | ... | Más atributos |

#### `properties`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | PK |
| owner_id | UUID | FK → users.id |
| title | VARCHAR | Título del anuncio |
| description | TEXT | Descripción |
| price | DECIMAL | Precio mensual |
| latitude | DECIMAL | Ubicación |
| longitude | DECIMAL | Ubicación |
| address | TEXT | Dirección |
| available_from | DATE | Disponible desde |
| is_active | BOOLEAN | Activo |
| created_at | TIMESTAMP | - |

#### `matches`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | PK |
| user_a | UUID | FK → users.id |
| user_b | UUID | FK → users.id |
| compatibility_score | DECIMAL | 0-100 (%) |
| created_at | TIMESTAMP | - |

#### `chats` & `messages`
Tabla para almacenar conversaciones y mensajes en tiempo real entre matches.

#### `swipes`
Tabla para registrar cada swipe (like/dislike) de compatibilidad.

## 🔧 Configuración

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Configurar Supabase

1. Crear cuenta en [supabase.com](https://supabase.com)
2. Copiar URL y Anon Key
3. Actualizar en `lib/config/app_config.dart`:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 3. Configurar Microservicio de IA

1. Descargar o clonar el repositorio del microservicio
2. Configurar variables de entorno
3. Iniciar servidor FastAPI
4. Actualizar URL en `app_config.dart`:

```dart
static const String aiServiceUrl = 'http://localhost:8000';
```

### 4. Configurar OneSignal (Notificaciones)

1. Crear app en [onesignal.com](https://onesignal.com)
2. Copiar App ID
3. Actualizar en `app_config.dart`:

```dart
static const String oneSignalAppId = 'your-onesignal-app-id';
```

## 🚀 Desarrollo

### Ejecutar la app

```bash
flutter run
```

### Generar modelos JSON

```bash
flutter pub run build_runner build
```

### Ver logs

```bash
flutter logs
```

## 🆕 Cambios recientes

- Global map button: pantalla de mapas con marcadores para publicaciones y búsquedas de roomates.
- `FilterSheet`: panel de filtros completo (radio, precio, dormitorios, ordenar, solo matches) con persistencia local.
- `bedrooms`: campo añadido al modelo cliente y SQL de migración generado (ejecutar la migración en Supabase si aún no está aplicada).
- Super-Like (botón estrella): flujo cliente que registra super-likes (actualmente se guardan como `like` si la restricción DB lo requiere) y crea match/chat automático cuando hay reciprocidad.
- `NotificationsScreen`: pantalla para ver notificaciones (likes / super-likes) con detección del remitente y marcación como leída.
- Chat reads (`chat_reads`): se añadió logging y reintentos para `updateLastReadAt` (upsert → update → insert) para diagnosticar problemas con RLS y asegurar que el campo `last_read_at` se guarde.

Si trabajas en desarrollo y quieres verificar el comportamiento de `chat_reads`, desde el SQL editor de Supabase ejecuta:

```sql
SELECT * FROM chat_reads
WHERE chat_id = '<CHAT_ID>'
  AND user_id = '<USER_ID>';
```

Si devuelve `No rows returned`, el `upsert` no creó la fila (posible RLS o fallo). Revisa los logs de la app para las líneas que comienzan con:

- `DEBUG updateLastReadAt upsert response`
- `DEBUG updateLastReadAt upsert threw`
- `DEBUG updateLastReadAt update response`
- `DEBUG updateLastReadAt insert response`

Estos ayudan a identificar si la operación fue bloqueada por las políticas de Row Level Security o si hubo otro error.

## 📡 Servicios Principales

### AuthProvider
```dart
// Registrarse
authProvider.signUp(
  email: 'user@example.com',
  password: '123456',
  fullName: 'Juan Pérez',
  role: UserRole.student,
);

// Iniciar sesión
authProvider.signIn(
  email: 'user@example.com',
  password: '123456',
);
```

### UserProvider
```dart
// Cargar datos del usuario
userProvider.loadUser(userId);

// Actualizar perfil
userProvider.updateProfile({
  'full_name': 'Juan Pérez',
  'bio': 'Mi bio...',
});
```

### MatchingProvider
```dart
// Crear match si hay compatibilidad
matchingProvider.createMatchIfCompatible(
  userId1: 'user1',
  userId2: 'user2',
  habits1: habits1,
  habits2: habits2,
);

// Hacer swipe
matchingProvider.swipe(
  swiperId: 'user1',
  targetUserId: 'user2',
  direction: SwipeDirection.like,
);
```

### PropertyProvider
```dart
// Cargar propiedades
propertyProvider.loadProperties(limit: 20);

// Crear propiedad
propertyProvider.createProperty(property);
```

## 🔄 Flujo de Compatibilidad

1. **Usuario A** hace swipe en Usuario B
2. **Frontend** llama a `MatchingProvider.swipe()`
3. **Servicio** guarda el swipe en Supabase
4. **Backend** checa si ambos se dieron like (mutual match)
5. Si es mutual match → **Llamar IA** para calcular compatibilidad
6. Si compatibilidad > 70% → **Crear Match** en BD
7. **Notificar** a ambos usuarios (OneSignal)

## 📦 Build & Deploy

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📝 Licencia

Este proyecto está bajo licencia MIT.

## 👥 Contribuidores

- Equipo ConVive

## 📞 Soporte

Para reportar bugs o sugerencias, contactar a: support@convive.app

