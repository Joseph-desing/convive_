📱 CHATBOT IA - GUÍA DE IMPLEMENTACIÓN Y USO
============================================

## ✅ ¿QUÉ SE HA IMPLEMENTADO?

### 1. MODELO DE DATOS (chatbot_message.dart)
✅ ChatbotMessage con tipos: user, assistant, suggestion
✅ Campos para usuario recomendado, score de compatibilidad y ubicación
✅ Serialización JSON automática (.g.dart generado)

### 2. SERVICIO DE IA (chatbot_service.dart)
✅ processUserMessage() - Procesar mensajes del usuario
✅ getCompatibilityRecommendation() - Obtener recomendación con score
✅ getWelcomeMessage() - Bienvenida personalizada
✅ Manejo de errores y timeouts

### 3. PROVIDER DE ESTADO (chatbot_provider.dart)
✅ Gestión de historial de mensajes
✅ Control de carga y errores
✅ initializeChatbot() - Iniciar conversación
✅ sendMessage() - Enviar y procesar mensajes
✅ getRecommendation() - Buscar compatibilidad

### 4. SCREEN DEL CHATBOT (chatbot_screen.dart)
✅ UI completa con historial scrollable
✅ Diseño responsivo con Material Design
✅ Cards de recomendación con Avatar, nombre y score
✅ Botones: "Ver Perfil" y "Ver Ubicación"
✅ Integración con MapLocationPicker
✅ Input de texto con validación
✅ Indicadores de carga

### 5. BACKEND MOCK (chatbot_backend_mock.py)
✅ Servidor FastAPI local para pruebas
✅ Endpoints: /chatbot/process, /chatbot/recommend, /chatbot/welcome
✅ Datos simulados de 4 usuarios compatibles
✅ CORS habilitado para la app Flutter

### 6. INTEGRACIÓN EN APP
✅ ChatbotProvider añadido en main.dart
✅ Ruta /chatbot disponible en GoRouter
✅ Botón "Chat IA" en header de Home Screen
✅ Acceso desde home: context.push('/chatbot')

### 7. DOCUMENTACIÓN
✅ CHATBOT_IA_INTEGRATION.md - Documentación técnica completa
✅ Este archivo - Guía de uso

---

## 🚀 CÓMO USAR LOCALMENTE

### PASO 1: Instalar dependencias del backend
```powershell
# Instalar FastAPI y Uvicorn
pip install fastapi uvicorn

# O usar requirements.txt si lo prefieres
pip install -r requirements.txt
```

### PASO 2: Ejecutar backend mock
```powershell
cd c:\Users\HP\Desktop\convive_

# Opción 1: Directamente con python
python chatbot_backend_mock.py

# Opción 2: Con uvicorn
uvicorn chatbot_backend_mock:app --reload --host 0.0.0.0 --port 8000
```

✅ Deberías ver algo como:
```
🚀 Iniciando Chatbot IA Backend Mock...
📍 URL: http://localhost:8000
📊 Docs: http://localhost:8000/docs
✅ Presiona Ctrl+C para detener
```

Nota: Si usas un emulador/dispositivo real, reemplaza localhost con tu IP local

### PASO 3: Ejecutar app Flutter
```powershell
cd c:\Users\HP\Desktop\convive_
flutter run
```

### PASO 4: Acceder al chatbot en la app
1. Login en la app
2. En Home Screen, busca el botón con icono 🤖 en el header
3. ¡Abre el chatbot y comienza a conversar!

---

## 💬 FLUJO DE CONVERSACIÓN

### Conversación Típica:

**Bot:** "¡Hola Juan! Bienvenido a ConVive Assistant..."
**Bot:** "¿Estás buscando compañero/a de habitación o departamento?"

**User:** "Busco un compañero para compartir apartamento"

**Bot:** "Entiendo que buscas un compañero de habitación. ¿Prefieres alguien limpio, tranquilo o más social?"

**User:** "Alguien limpio y tranquilo"

**Bot:** "🎉 ¡Tengo una recomendación! María García podría ser perfecta para ti. Estudiante de ingeniería, limpia, tranquila y amable..."

**Card mostrada:**
- Avatar de María
- Nombre: María García
- Score: 92% Compatible ❤️
- Botón "Ver Perfil" (abre modal)
- Botón "Ver Ubicación" (abre mapa)

---

## 🔧 ESTRUCTURA DE ARCHIVOS CREADOS

```
c:\Users\HP\Desktop\convive_\
├── lib/
│   ├── models/
│   │   ├── chatbot_message.dart      ← Modelo del chatbot
│   │   └── chatbot_message.g.dart    ← Serialización auto (generado)
│   │
│   ├── services/
│   │   └── chatbot_service.dart      ← Servicio HTTP
│   │
│   ├── providers/
│   │   └── chatbot_provider.dart     ← State management
│   │
│   ├── screens/
│   │   └── chatbot_screen.dart       ← UI del chatbot
│   │
│   └── main.dart                     ← MODIFICADO (ChatbotProvider + ruta)
│
├── chatbot_backend_mock.py           ← Backend FastAPI mock
│
└── CHATBOT_IA_INTEGRATION.md         ← Documentación técnica

Otros archivos modificados:
├── lib/screens/home_screen.dart      ← Botón del chatbot agregado
├── lib/models/index.dart             ← Export chatbot_message
├── lib/services/index.dart           ← Export chatbot_service
└── lib/providers/index.dart          ← Export chatbot_provider
```

---

## 🧪 PRUEBAS

### Test 1: Conversación Básica
✓ Abre el chatbot
✓ Escribe: "Busco compañero de apartamento"
✓ Deberías recibir una respuesta del bot

### Test 2: Recomendación
✓ Elige una opción específica (limpio, tranquilo, etc.)
✓ El bot debe mostrar un card de recomendación
✓ Verifica que los datos del usuario se muestren

### Test 3: Ver Perfil
✓ Presiona "Ver Perfil" en una recomendación
✓ Debe abrir un modal con detalles del usuario

### Test 4: Ver Ubicación
✓ Presiona "Ver Ubicación" en una recomendación
✓ Debe abrir el mapa con la ubicación marcada

### Test 5: Scroll
✓ Envía varios mensajes
✓ Verifica que el historial scrollea automáticamente

---

## ⚙️ CONFIGURACIÓN AVANZADA

### Cambiar URL del Backend

En `lib/services/chatbot_service.dart`:

```dart
ChatbotService({
  this.baseUrl = 'http://10.0.0.1:8000', // Tu IP local
})
```

### Aumentar Timeout

En `chatbot_service.dart`:

```dart
.timeout(
  const Duration(seconds: 30),  // Aumentar de 15 a 30
  onTimeout: () => throw Exception('Timeout'),
)
```

### Personalizaciones de UI

En `lib/screens/chatbot_screen.dart`:

- Colores: Edita `AppColors.primary` y `AppColors.secondary`
- Fuentes: Edita `TextStyle` en los Widgets
- Animaciones: Añade `AnimatedBuilder` o `Lottie`

---

## 🔌 ENDPOINTS DEL BACKEND

### 1. GET /
Health check del servicio

### 2. POST /chatbot/welcome
Obtener mensaje de bienvenida personalizado

**Request:**
```json
{
  "user_name": "Juan"
}
```

**Response:**
```json
{
  "message": "¡Hola Juan! Bienvenido a ConVive Assistant..."
}
```

### 3. POST /chatbot/process
Procesar mensaje del usuario

**Request:**
```json
{
  "user_id": "user123",
  "message": "Busco compañero tranquilo",
  "user_profile": {"name": "Juan", "age": 25},
  "user_habits": {"cleanliness": 8, "noise_level": 5}
}
```

**Response:**
```json
{
  "id": "msg456",
  "type": "assistant",
  "content": "Entiendo que buscas...",
  "timestamp": "2026-03-29T10:30:00Z",
  "matched_user_id": null,
  "matched_user_name": null,
  "compatibility_score": null,
  "property_location": null
}
```

### 4. POST /chatbot/recommend
Obtener recomendación de compatibilidad

**Request:**
```json
{
  "user_id": "user123",
  "responses": ["tranquilo", "limpio", "madrugador"],
  "habits": {"cleanliness": 8}
}
```

**Response:**
```json
{
  "id": "msg789",
  "type": "suggestion",
  "content": "¡María es perfecta para ti!...",
  "timestamp": "2026-03-29T10:35:00Z",
  "matched_user_id": "user456",
  "matched_user_name": "María García",
  "matched_user_avatar": "https://i.pravatar.cc/150?img=1",
  "compatibility_score": 0.92,
  "property_location": {
    "lat": 10.4806,
    "lng": -66.9036,
    "address": "La Candelaria, Caracas"
  }
}
```

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### ❌ Error: "Connection refused" en chatbot
**Solución:** Verifica que el backend está corriendo en puerto 8000

### ❌ Error: "Timeout en chatbot service"
**Solución:** 
- El backend tardó mucho. Aumenta timeout en chatbot_service.dart
- Verifica rendimiento del servidor

### ❌ No aparece el botón del chatbot en Home
**Solución:** Verifica que:
1. `home_screen.dart` tiene el import de `go_router`
2. El botón está en el header (líneas ~247-258)
3. main.dart tiene la ruta `/chatbot` en GoRouter

### ❌ El chatbot muestra errores en Flutter
**Solución:**
```
flutter clean
flutter pub get
flutter run
```

### ❌ "Message de tipo 'suggestion' no muestra"
**Solución:** Verifica que el backend devuelve `type: "suggestion"` correctamente

---

## 🎯 PRÓXIMAS MEJORAS

1. **Backend Real en Python:**
   - Implementar algoritmo real de compatibilidad con ML
   - Conectar con base de datos PostgreSQL (Supabase)
   - Mejorar NLP para entender preguntas naturales

2. **Persistencia:**
   - Guardar historial de chat en Supabase
   - Recuperar chats anteriores

3. **Notificaciones:**
   - Notificar nuevas recomendaciones por OneSignal
   - Avisos cuando alguien hace match contigo

4. **Análisis:**
   - Dashboard de métricas del chatbot
   - A/B testing de preguntas

5. **UX/UI:**
   - Animaciones con Lottie
   - Typing indicators (puntos animados)
   - Chat bubbles mejoradas

6. **Multilingual:**
   - Soporte para inglés, portugués, italiano

---

## 📞 SOPORTE

Si encuentras problemas:

1. Revisa los logs en la consola de Flutter: `flutter logs`
2. Verifica el servidor: `http://localhost:8000/docs`
3. Consulta CHATBOT_IA_INTEGRATION.md para más detalles técnicos
4. Check los archivos de documentación de password reset (similar arquitectura)

---

## 📝 RESUMEN RÁPIDO

✅ **Instalado:** Model, Service, Provider, Screen, Backend Mock
✅ **Integrado:** En main.dart, home_screen.dart, router GoRouter
✅ **Funcional:** Flujo completo de conversación y recomendación
✅ **Localizable:** Backend en Python levantable localmente
✅ **Escalable:** Listo para conectar con backend real

**Próximo Paso:** Conectar con tu backend Python/FastAPI real cuando esté listo.

¡El chatbot está listo para
 usar! 🚀
