# 🚀 Implementación de Groq en ConVive Chatbot

## ¿Qué es Groq?

Groq es una plataforma de inferencia de IA ultra-rápida que proporciona acceso a modelos de lenguaje avanzados (como Mixtral, Llama, etc.) a través de API. Está optimizado para velocidad y es ideal para aplicaciones en tiempo real como chatbots.

### Ventajas de Groq:
- ⚡ **Ultra-rápido**: Respuestas en milisegundos
- 💰 **Económico**: Precios competitivos
- 🔒 **Seguro**: API estable y confiable
- 📊 **Modelos potentes**: Acceso a Mixtral, Llama 2, Llama 3

---

## 📋 Requisitos Previos

1. Crear una cuenta en [Groq Console](https://console.groq.com)
2. Generar una API Key
3. Tener saldo disponible en tu cuenta de Groq (capa gratuita disponible)

---

## 🔧 Instalación y Configuración

### Paso 1: Obtener API Key de Groq

1. Ve a [https://console.groq.com](https://console.groq.com)
2. Crea una cuenta o inicia sesión
3. Navega a **API Keys** en el dashboard
4. Haz clic en **Create API Key**
5. Copia la clave generada

### Paso 2: Configurar API Key en ConVive

1. Abre el archivo `lib/config/groq_config.dart`:
```dart
static const String apiKey = 'gsk_YOUR_GROQ_API_KEY_HERE'; // ← Reemplaza con tu key
static const bool enableGroq = false; // ← Cambia a true
```

2. Reemplaza `gsk_YOUR_GROQ_API_KEY_HERE` con tu API Key real
3. Cambia `enableGroq = false` a `enableGroq = true`

**Ejemplo:**
```dart
static const String apiKey = 'gsk_abc123def456...'; // Tu API key real
static const bool enableGroq = true; // ✅ Habilitado
```

### Paso 3: Verificar la Instalación

Los archivos han sido creados automáticamente:
- ✅ `lib/services/groq_service.dart` - Servicio de integración con Groq
- ✅ `lib/config/groq_config.dart` - Configuración de Groq
- ✅ `lib/services/chatbot_service.dart` - Actualizado para usar Groq

---

## 🎯 Modelos Disponibles en Groq

En `lib/config/groq_config.dart` puedes cambiar el modelo entre estos:

### Modelos Recomendados:

1. **mixtral-8x7b-32768** (RECOMENDADO - DEFAULT)
   - Velocidad: ⚡⚡⚡⚡⚡ Ultra-rápido
   - Calidad: ⭐⭐⭐⭐
   - Casos de uso: Chat en tiempo real, respuestas rápidas
   - Tokens: Hasta 32,768

2. **llama3-70b-8192**
   - Velocidad: ⚡⚡⚡⚡
   - Calidad: ⭐⭐⭐⭐⭐
   - Casos de uso: Respuestas más precisas y complejas
   - Tokens: Hasta 8,192

3. **llama2-70b-4096**
   - Velocidad: ⚡⚡⚡
   - Calidad: ⭐⭐⭐⭐
   - Casos de uso: Análisis detallado
   - Tokens: Hasta 4,096

---

## 💻 Uso en el Código

### Estructura de Carpetas Creada

```
lib/
├── config/
│   └── groq_config.dart          # Configuración de Groq
├── services/
│   ├── groq_service.dart         # Servicio de Groq (NUEVO)
│   └── chatbot_service.dart      # Servicio de chatbot (ACTUALIZADO)
└── screens/
    └── chatbot_screen.dart       # Pantalla del chatbot (sin cambios)
```

### Cómo Funciona

1. **ChatbotScreen** → Envía mensaje a usuario
2. **ChatbotProvider** → Gestiona el estado del chat
3. **ChatbotService** → Procesa el mensaje y lo envía a Groq
4. **GroqService** → Comunica con la API de Groq
5. **Groq API** → Responde con respuesta de IA
6. **Response** → Se muestra al usuario en el chat

### Código de Ejemplo

El sistema está completamente integrado. Cuando el usuario envía un mensaje:

```dart
// En ChatbotProvider.sendMessage():
final response = await _chatbotService.processUserMessage(
  userId: currentUser.id,
  userMessage: userMessage,
  userProfile: userProfile,
  userHabits: userHabits,
  chatHistory: _messages,
);
```

Si Groq está habilitado, usará **GroqService**. Si no, usará el **backend original**.

---

## 🌟 Características Avanzadas

### Context del Usuario

El chatbot incluye información del usuario automáticamente:
- Email del usuario
- Tipo de suscripción
- Hábitos (limpieza, ruido, fiestas, invitados)

### Historial de Chat

El servicio mantiene los últimos 10 mensajes para:
- Mantener contexto de la conversación
- Proporcionar respuestas consistentes
- Mejorar la calidad de las recomendaciones

---

## ⚠️ Límites y Consideraciones

### Rate Limits de Groq

| Plan | Requests/Min | Requests/Day |
|------|-------------|--------------|
| Gratuito | 30 | 14,400 |
| Pro | 300 | Ilimitado |

### Costos Estimados

- **Mixtral-8x7b**: ~$0.15 / 1M tokens
- **Llama3-70b**: ~$0.60 / 1M tokens
- **Layer gratuita**: Hasta 10,000 tokens/día

---

## 🔍 Debugging

### Verificar que Groq está Habilitado

```dart
// En main.dart, verifica que ChatbotService recibe apiKey:
chatbotService: ChatbotService(
  groqApiKey: GroqConfig.enableGroq ? GroqConfig.apiKey : null,
)
```

### Ver Logs

Abre la consola de Flutter para ver debugging:
- Si Groq está activo, verás respuestas ultra-rápidas
- Si hay error, verás el mensaje de excepción

### Problemas Comunes

#### 1. "Invalid API Key"
- Verifica que copiaste correctamente la clave de Groq
- Asegúrate de que `enableGroq = true`
- Revisa que no hay espacios en blanco

#### 2. "Timeout en Groq API"
- Groq está experimentando latencia
- Intenta nuevamente (generalmente es muy rápido)
- Verifica tu conexión a internet

#### 3. "No content in Groq response"
- El modelo tardó demasiado
- Intenta con un modelo más rápido (Mixtral)

---

## 📊 Monitoreo y Estadísticas

En [Groq Console](https://console.groq.com) puedes ver:
- Tokens utilizados
- Requests procesados
- Costos acumulados
- Latencias promedio
- Tasa de aciertos

---

## 🚀 Próximos Pasos

1. ✅ API Key configurada
2. ✅ Groq habilitado
3. Probar chatbot en simulador/dispositivo
4. Monitorear uso en Groq Console
5. Optimizar prompts si es necesario

---

## 📚 Recursos Útiles

- [Documentación de Groq](https://console.groq.com/docs)
- [Playground de Groq](https://console.groq.com/playground)
- [Lista de Modelos](https://console.groq.com/docs/models)
- [API Reference](https://console.groq.com/docs/api)

---

## ❓ Preguntas Frecuentes

### ¿Puedo usar Groq sin API Key?
No, necesitas una API Key de Groq. La capa gratuita tiene suficiente para development.

### ¿Qué pasa si se acaba mi saldo en Groq?
El chatbot caerá al backend original configurado en `chatbot_service.dart`.

### ¿Puedo cambiar de modelo durante la ejecución?
Sí, actualiza `GroqConfig.model` y reinicia la app.

### ¿Es segura mi API Key?
- Nunca la publiques en GitHub
- Usa variables de entorno en producción
- Considera usar backend proxy en producción

---

## 🔐 Seguridad en Producción

Para producción, **NO hardcodees la API Key**:

```dart
// ❌ NUNCA en producción:
static const String apiKey = 'gsk_actual_key';

// ✅ Usa variables de entorno:
static const String apiKey = String.fromEnvironment('GROQ_API_KEY');
```

O usa un backend proxy que oculte la API Key.

---

**¡Groq está listo! 🎉**

Ahora tu chatbot tendrá respuestas ultra-rápidas potenciadas por IA.
