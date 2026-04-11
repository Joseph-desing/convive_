/// Archivo de documentación: Integración del Chatbot IA
/// 
/// Este archivo proporciona la documentación técnica completa 
/// para la implementación y uso del chatbot IA en ConVive.

# 🤖 Chatbot IA - Documentación de Integración

## 📋 Descripción General

El chatbot IA es un asistente conversacional integrado en ConVive que ayuda a los usuarios a:
- 🎯 Encontrar compañeros de habitación compatibles
- 🏠 Descubrir departamentos ideales
- 📊 Analizar compatibilidad según hábitos
- 🗺️ Visualizar ubicaciones en mapa

## 🏗️ Arquitectura

### Componentes Creados

```
lib/
├── models/
│   └── chatbot_message.dart      # Modelo de mensajes del chatbot
│
├── services/
│   └── chatbot_service.dart      # Servicio de comunicación con IA
│
├── providers/
│   └── chatbot_provider.dart     # State management del chatbot
│
└── screens/
    └── chatbot_screen.dart       # UI principal del chatbot
```

### Flujo de Datos

```
ChatbotScreen
    ↓
ChatbotProvider (State Management)
    ↓
ChatbotService (HTTP)
    ↓
Backend IA (Python/FastAPI)
    ↓
Microservicio de Compatibilidad
    ↓
Base de Datos (Supabase)
```

## 🔧 Implementación

### 1. Modelo: ChatbotMessage

```dart
ChatbotMessage(
  type: MessageType.assistant,
  content: 'Bienvenido...',
  matchedUserId: 'user123',
  matchedUserName: 'Juan',
  compatibilityScore: 0.85,
  propertyLocation: {'lat': 10.5, 'lng': -60.2},
)
```

**Tipos de Mensajes:**
- `user` - Mensaje del usuario
- `assistant` - Respuesta del chatbot
- `suggestion` - Recomendación de compatibilidad

### 2. Servicio: ChatbotService

**Métodos principales:**

```dart
// Procesar mensaje del usuario
Future<ChatbotMessage> processUserMessage({
  required String userId,
  required String userMessage,
  required Map<String, dynamic> userProfile,
  required Map<String, dynamic> userHabits,
})

// Obtener recomendación de compatibilidad
Future<ChatbotMessage> getCompatibilityRecommendation({
  required String userId,
  required List<String> userResponses,
  required Map<String, dynamic> userHabits,
})

// Obtener mensaje de bienvenida personalizado
Future<String> getWelcomeMessage(String userName)
```

### 3. Provider: ChatbotProvider

**Gestiona:**
- 📝 Historial de mensajes
- 🔄 Estado de carga
- ⚠️ Manejo de errores
- 💾 Recomendación actual

**Métodos principales:**

```dart
// Inicializar chatbot
Future<void> initializeChatbot(User user)

// Enviar mensaje
Future<void> sendMessage(String userMessage, User currentUser)

// Obtener recomendación
Future<void> getRecommendation(User currentUser, List<String> userResponses)

// Limpiar historial
void clearMessages()
```

### 4. Screen: ChatbotScreen

**Características:**
- ✅ Historial de conversación scrollable
- ✅ UI responsiva con MaterialDesign
- ✅ Cards interactivos para recomendaciones
- ✅ Botones para ver perfil y ubicación
- ✅ Input de texto con validación
- ✅ Indicadores de carga

## 🚀 Cómo Usar

### En Home Screen o Navigation

```dart
// Agregar botón para abrir chatbot
ElevatedButton(
  onPressed: () => context.push('/chatbot'),
  child: const Text('Chat IA'),
)
```

### Flujo de Conversación

1. **Bienvenida** → Mensaje personalizado
2. **Preguntas** → El usuario responde sobre sus preferencias
3. **Procesamiento** → IA analiza respuestas
4. **Recomendación** → Muestra usuario compatible con score
5. **Acción** → Ver perfil o ubicación en mapa

## ⚙️ Configuración Backend

### Base URL del Servicio IA

En `chatbot_service.dart`:

```dart
final baseUrl = 'http://localhost:8000'; // Cambiar a URL real
```

### Endpoints Esperados

```
POST /chatbot/process          → Procesar mensaje
POST /chatbot/recommend        → Obtener recomendación
POST /chatbot/welcome          → Mensaje de bienvenida
```

### Respuesta JSON Esperada

```json
{
  "id": "msg123",
  "type": "suggestion",
  "content": "Descripción del usuario...",
  "timestamp": "2026-03-29T10:30:00Z",
  "matched_user_id": "user456",
  "matched_user_name": "Maria García",
  "matched_user_avatar": "https://...",
  "compatibility_score": 0.92,
  "property_location": {
    "lat": 10.5,
    "lng": -60.2,
    "address": "Calle Principal 123"
  }
}
```

## 🔌 Integración con Mapa

Cuando el usuario presiona "Ver Ubicación":

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => MapLocationPicker(
      initialLocation: message.propertyLocation,
      readOnly: true,
    ),
  ),
);
```

## 📱 Rutas Disponibles

```
/chatbot          → Pantalla principal del chatbot
```

## ✅ Próximos Pasos

- [ ] Conectar con backend Python/FastAPI real
- [ ] Implementar algoritmo de compatibilidad más avanzado
- [ ] Agregar persistencia de historial en BD
- [ ] Feedback de usuario para mejorar IA
- [ ] Animaciones y transiciones suaves
- [ ] Soporte para múltiples idiomas
- [ ] Caché de recomendaciones

## 🐛 Troubleshooting

### Error: "Timeout en chatbot service"
- Verificar que el backend IA está corriendo
- Aumentar timeout en `chatbot_service.dart`

### No aparecen mensajes
- Verificar que `initializeChatbot()` fue llamado
- Revisar logs en la consola

### La ubicación no se muestra en el mapa
- Verificar que `propertyLocation` contiene `lat` y `lng`
- Verificar que `map_location_picker.dart` está correctamente configurado

## 📞 Soporte

Para más información, consultar:
- Backend IA: `/docs/` (Backend repository)
- Servicio de Compatibilidad: `supabase_database_service.dart`
- Configuración Supabase: `config/supabase_provider.dart`
