# 📋 GUÍA RÁPIDA DE REFERENCIA - ConVive

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────┐
│              FLUTTER FRONTEND                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Screens  │→ │Providers │→ │   Services       │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│                                    ↓                 │
└────────────────────────────────────────────────────┐
                                    ↓                 │
┌─────────────────────────────────────────────────┐│
│         SUPABASE BACKEND                       ││
│  ┌──────────────┐    ┌──────────────────┐     ││
│  │ PostgreSQL   │    │   Realtime       │     ││
│  │  (10 tables) │    │   WebSocket      │     ││
│  └──────────────┘    └──────────────────┘     ││
│  ┌──────────────┐    ┌──────────────────┐     ││
│  │  Storage     │    │  Auth (JWT)      │     ││
│  │  (2 buckets) │    │                  │     ││
│  └──────────────┘    └──────────────────┘     ││
└─────────────────────────────────────────────┐│
                       ↓                       │
┌─────────────────────────────────────────┐│
│   PYTHON MICROSERVICE (FastAPI)        ││
│  Algoritmo IA de compatibilidad        ││
│  Validación de imágenes                ││
│  Recomendaciones                       ││
└─────────────────────────────────────────┐│
```

## 📁 Estructura de Carpetas

```
lib/
├── main.dart                          ← Entrada, MultiProvider setup
├── config/
│   ├── app_config.dart               ← URLs y API keys
│   ├── supabase_provider.dart        ← Singleton Supabase
│   └── ai_service_provider.dart      ← Singleton AI
├── models/                            ← 11 data models
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
├── services/                          ← Capa de servicios
│   ├── supabase_auth_service.dart
│   ├── supabase_database_service.dart
│   ├── supabase_realtime_service.dart
│   ├── supabase_storage_service.dart
│   ├── ai_service.dart
│   └── index.dart
├── providers/                         ← State management
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── matching_provider.dart
│   ├── property_provider.dart
│   └── index.dart
├── screens/                           ← UI Screens
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── splash_screen.dart
│   └── welcome_screen.dart
├── widgets/                           ← Componentes reutilizables
│   ├── bottom_nav_bar.dart
│   └── property_card.dart
├── constants/                         ← Constantes
│   ├── app_strings.dart              ← Strings i18n
│   ├── app_dimensions.dart           ← Espacios y tamaños
│   └── index.dart
├── exceptions/                        ← Excepciones personalizadas
│   ├── app_exceptions.dart
│   └── index.dart
├── utils/                             ← Utilidades
│   ├── app_utils.dart                ← Helpers para dates, validation, etc
│   ├── colors.dart                   ← Colores
│   └── index.dart
└── theme/                             ← Tema personalizado
    └── app_theme.dart
```

## 🔄 Flujo de Datos (Ejemplo: Login)

```
User taps "Login" button
        ↓
LoginScreen.onLoginPressed()
        ↓
Provider.of<AuthProvider>().signIn()
        ↓
AuthProvider.signIn() llama:
        ├→ SupabaseAuthService.signIn(email, password)
        ├→ SupabaseDatabaseService.getUser(uid)
        └→ Notifica listeners
        ↓
Screen escucha cambios con Consumer<AuthProvider>
        ↓
Si isAuthenticated, navega a HomeScreen
        ↓
HomeScreen carga:
        ├→ UserProvider.loadUser()
        ├→ MatchingProvider.loadMatches()
        └→ PropertyProvider.loadProperties()
        ↓
Datos mostrados en UI con Consumer widgets
```

## 🎯 Flujo de Matching (Swipe)

```
User en HomeScreen ve candidatos
        ↓
Taps "Like" o "Dislike" card
        ↓
MatchingProvider.swipe(targetUserId, SwipeDirection.like)
        ↓
Guarda swipe en BD
        ↓
¿Target_user también hizo like?
        ├→ NO: Solo registra swipe
        └→ SÍ: 
            ├→ Llama AI: calculateCompatibilityScore()
            ├→ Si score > 70%:
            │   └→ Crea Match con IA score
            └→ Notifica a ambos usuarios
            
        ↓
MatchingProvider notifica listeners
        ↓
UI se actualiza mostrando nuevo match
```

## 📨 Flujo de Chat (Realtime)

```
User abre chat con match
        ↓
ChatScreen se monta
        ↓
RealtimeService.subscribeToMessages(chatId)
        ↓
Establece WebSocket connection a Supabase
        ↓
User envía mensaje
        ↓
Message guardada en BD
        ↓
Supabase emite PostgresChangeEvent
        ↓
Stream en RealtimeService recibe evento
        ↓
Provider notifica listeners
        ↓
UI se actualiza en tiempo real (sin recargar)
```

## 🏘️ Flujo de Propiedades

```
PropertyProvider.loadProperties()
        ↓
DatabaseService.getProperties(limit: 20)
        ↓
Retorna List<Property> de BD
        ↓
Para cada propiedad:
        ├→ Carga PropertyImage(s)
        └→ Calcula distancia al usuario
        
        ↓
Provider actualiza _properties list
        ↓
Screen muestra PropertyCard widgets
        ↓
User puede:
        ├→ Ver detalles
        ├→ Ver galería de imágenes
        ├→ Contactar al dueño
        └→ Guardar como favorita
```

## 🤖 Flujo de Validación de IA

```
User sube imagen de perfil
        ↓
SupabaseStorageService.uploadProfileImage(file)
        ↓
AI_SERVICE.validateProfileImage(file)
        ↓
Servicio Python:
        ├→ Verifica resolución mín 300x300
        ├→ Verifica resolución máx 5000x5000
        ├→ Detecta si contiene rostro (ML)
        └→ Retorna {valid, reasons}
        
        ↓
Si válida:
        ├→ Guarda URL en Profile
        └→ Marca como validated=true
        
Else:
        └→ Muestra error al usuario
```

## 🔐 Autenticación (JWT)

```
signUp(email, password)
        ↓
Supabase.auth.signUp()
        ↓
Genera JWT token
        ↓
Retorna User object con uid
        ↓
AuthProvider guarda currentUser
        ↓
Requests posteriores incluyen JWT en header:
        Authorization: Bearer {token}
        
signOut()
        ↓
Supabase.auth.signOut()
        ↓
Invalida JWT
        ↓
AuthProvider borra currentUser
        ↓
UI retorna a LoginScreen
```

## 📊 Tabla de Modelos

| Modelo | Campos Clave | Relaciones |
|--------|-------------|-----------|
| **User** | id, email, role, subscription_type | 1→1 Profile, 1→1 Habits, 1→∞ Properties |
| **Profile** | user_id, fullName, profileImageUrl | 1←→1 User |
| **Habits** | user_id, cleanliness_level, noise_tolerance, ... | 1←→1 User |
| **Property** | owner_id, title, price, address | ∞←→1 User, 1→∞ PropertyImage |
| **PropertyImage** | property_id, imageUrl, validated | ∞←→1 Property |
| **Swipe** | swiper_id, target_user_id, direction | ∞→1 User |
| **Match** | user_a_id, user_b_id, compatibility_score | ∞→1 User, 1→1 Chat |
| **Chat** | match_id | 1←→1 Match, 1→∞ Message |
| **Message** | chat_id, sender_id, content | ∞→1 Chat, ∞→1 User |
| **Subscription** | user_id, price, status, end_date | ∞←→1 User |

## 🎨 Estado del Provider

### AuthProvider
```dart
_currentUser: User?                    ← Usuario autenticado
_isLoading: bool                       ← Cargando
_error: String?                        ← Mensaje de error

Métodos:
- signUp(email, password, fullName, role)
- signIn(email, password)
- signOut()
- resetPassword(email)
```

### UserProvider
```dart
_user: User?
_profile: Profile?
_habits: Habits?
_isLoading: bool
_error: String?

Métodos:
- loadUser(userId)
- updateProfile(data)
- updateHabits(data)
```

### MatchingProvider
```dart
_matches: List<Match>
_candidates: List<User>
_isLoading: bool
_error: String?

Métodos:
- loadUserMatches(userId)
- loadCandidates(userId)
- swipe(targetUserId, direction)
- createMatchIfCompatible(userA, userB)
```

### PropertyProvider
```dart
_properties: List<Property>
_userProperties: List<Property>
_selectedProperty: Property?
_isLoading: bool
_error: String?

Métodos:
- loadProperties(page: int)
- loadUserProperties(userId)
- getProperty(propertyId)
- createProperty(data)
- updateProperty(id, data)
- deleteProperty(id)
```

## 🛡️ Seguridad (RLS)

Supabase Row Level Security policies garantizan:
```
✅ Users solo ven su propio perfil (excepto admin)
✅ Users no pueden editar datos de otros
✅ Properties visible a todos, editable solo por owner
✅ Messages solo visible a participantes del chat
✅ Swipes privados entre usuarios
```

## 🚀 Endpoints del Microservicio IA

```
POST /compatibility-score
  Request: { user_a_habits, user_b_habits }
  Response: { score: 75.5 }  # 0-100

POST /validate-profile-image
  Request: FormData(file)
  Response: { valid: true, reasons: [], width: 600, height: 800 }

POST /validate-property-image
  Request: FormData(file)
  Response: { valid: true, reasons: [], width: 1200, height: 900 }

POST /recommendations
  Request: { user_id, habits }
  Response: ["user_id_1", "user_id_2", ...]

POST /detect-anomaly
  Request: { profile_data }
  Response: { is_suspicious: false, reasons: [] }

GET /health
  Response: { status: "ok" }
```

## ⚡ Performance Tips

1. **Usar `Consumer` en lugar de `Provider.of` en build()**
   ```dart
   // ✅ Bueno
   Consumer<UserProvider>(
     builder: (context, provider, _) => Text(provider.name)
   )
   
   // ❌ Evitar
   Text(Provider.of<UserProvider>(context).name)
   ```

2. **Usar `listen: false` para setters**
   ```dart
   Provider.of<AuthProvider>(context, listen: false).signIn()
   ```

3. **Paginar datos largos**
   ```dart
   loadProperties(page: 1) // Carga de 20 en 20
   ```

4. **Caché en proveedores**
   ```dart
   if (_user != null) return _user!; // No recargar
   ```

5. **Usar índices en BD**
   ```sql
   CREATE INDEX idx_properties_owner_id ON properties(owner_id);
   ```

## 🔍 Debugging

```dart
// Activar logs de Supabase
Supabase.initialize(
  url: SUPABASE_URL,
  anonKey: SUPABASE_ANON_KEY,
  debug: true, // ← Para ver requestsHTTP
);

// Inspeccionar estado del provider
Provider.of<AuthProvider>(context).toString()

// Ver errores de serialización
buildRunner: 
  flutter pub run build_runner build --verbose
```

## 📱 Próximas Screens a Implementar

- [ ] SplashScreen - Cargando
- [ ] WelcomeScreen - Introducción
- [ ] LoginScreen - Email/contraseña
- [ ] SignUpScreen - Registro
- [ ] ProfileSetupScreen - Información personal
- [ ] HabitsScreen - Preferencias
- [ ] HomeScreen - Swiping
- [ ] MatchesScreen - Lista de matches
- [ ] ChatScreen - Mensajería
- [ ] PropertyDetailScreen - Detalles de propiedad
- [ ] PropertyListScreen - Listado de propiedades
- [ ] CreatePropertyScreen - Crear propiedad

---

**¡Usa esta guía como referencia rápida durante el desarrollo!**
