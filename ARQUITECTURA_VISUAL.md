# 📊 Diagrama Visual: Antes vs Después

## ❌ ANTES (No Funciona)

```
┌─────────────────────┐
│   Flutter Web       │
│   (Browser)         │
└──────────┬──────────┘
           │
           │ POST /chat/completions
           │ (CORS BLOCKED ❌)
           ↓
┌─────────────────────┐
│  https://api.groq.  │
│  com/openai/v1      │
└─────────────────────┘
           │
           ↓
    ❌ ERROR 400
    CORS bloqueado
```

**Estado del navegador:**
```
❌ Access to XMLHttpRequest at 'https://api.groq.com/...'
   from origin 'http://localhost:5173' has been blocked by CORS policy
```

**Console de Groq:**
```
Última utilización: Nunca
Uso (24h): 0 llamadas
```

---

## ✅ DESPUÉS (Funciona)

```
┌─────────────────────┐
│   Flutter Web       │
│   (Browser)         │
│  localhost:5173     │
└──────────┬──────────┘
           │
           │ POST /api/chat
           │ (No CORS ✅)
           ↓
┌─────────────────────┐
│   Tu Backend        │
│   (FastAPI)         │
│  localhost:8000     │
└──────────┬──────────┘
           │
           │ POST /chat/completions
           │ (Server-to-Server ✅)
           ↓
┌─────────────────────┐
│  https://api.groq.  │
│  com/openai/v1      │
└─────────────────────┘
           │
           ↓
    ✅ Respuesta incluida
    Contenido recibido

```

**Estado del navegador:**
```
✅ Llamada a http://localhost:8000/api/chat
✅ CORS permitido (backend es same-origin o configurado)
✅ Response status 200 OK
```

**Console de Groq:**
```
Última utilización: Ahora
Uso (24h): 5 llamadas
```

---

## 🔄 Flujo Completo de un Mensaje

### Paso 1: Usuario escribe en chat
```
┌─────────────────┐
│ @user escribes: │
│ "Hola, soy      │
│  introvértido"  │
└────────┬────────┘
         │
         ↓
   [SEND BUTTON]
```

### Paso 2: Flutter envía a tu backend
```
POST http://localhost:8000/api/chat

Headers:
  Content-Type: application/json
  Authorization: Bearer tu_api_key

Body:
{
  "user_message": "Hola, soy introvértido",
  "chat_history": [
    {
      "role": "assistant",
      "content": "¿Cómo eres en cuanto a socialización?"
    }
  ],
  "system_prompt": "Eres un asistente..."
}
```

### Paso 3: Tu backend recibe
```
Backend (main.py)

✅ POST /api/chat recibido
✅ Variables cargadas de .env
✅ API Key: gsk_... ✓
✅ Modelo: llama-3.1-70b-versatile ✓
```

### Paso 4: Backend construye request para Groq
```
Backend → Groq

POST https://api.groq.com/openai/v1/chat/completions

Headers:
  Content-Type: application/json
  Authorization: Bearer gsk_...

Body:
{
  "model": "llama-3.1-70b-versatile",
  "messages": [
    {
      "role": "system",
      "content": "Eres un asistente..."
    },
    {
      "role": "assistant",
      "content": "¿Cómo eres en cuanto a socialización?"
    },
    {
      "role": "user",
      "content": "Hola, soy introvértido"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1024
}
```

### Paso 5: Groq responde
```
Groq → Backend

Status: 200 OK

Body:
{
  "choices": [
    {
      "message": {
        "content": "Perfecto, entiendo que prefieres
                   ambientes tranquilos. Buscaremos
                   compañeros con hábitos similares..."
      }
    }
  ],
  "usage": {
    "prompt_tokens": 120,
    "completion_tokens": 45,
    "total_tokens": 165
  }
}
```

### Paso 6: Backend retorna a Flutter
```
Backend → Flutter Web

Status: 200 OK

Body:
{
  "content": "Perfecto, entiendo que prefieres
              ambientes tranquilos. Buscaremos
              compañeros con hábitos similares...",
  "usage": {
    "completion_tokens": 45,
    "prompt_tokens": 120,
    "total_tokens": 165
  }
}
```

### Paso 7: Flutter renderiza en chat
```
┌────────────────────────┐
│ ChatScreen             │
│                        │
│ Assistant:             │
│ "Perfecto, entiendo... │
│                        │
│ Buscando compañeros... │
└────────────────────────┘
```

---

## 📍 Arquitectura Física

### Desarrollo Local

```
Tu PC (Windows)

┌─────────────────────────────────────────┐
│  VS Code / Editor                       │
│  ├─ lib/services/groq_service.dart      │
│  └─ backend/main.py                     │
└────────────────┬────────────────────────┘

Terminal 1:                Terminal 2:
┌──────────────────────┐  ┌──────────────────────┐
│ flutter run -d web   │  │ python main.py       │
│                      │  │                      │
│ Browser on:         │  │ Server on:           │
│ localhost:5173      │  │ localhost:8000       │
└──────────────────────┘  └──────────────────────┘
         ↑                         ↑
         └─────────────────────────┘
              (HTTP requests)
```

### Producción

```
Internet

┌─────────────────────────────────────────────────┐
│ CDN / Hosting (Firebase, Vercel, Netlify)       │
│ ├─ yourapp.com                                  │
│ └─ Flutter Web (HTML/JS estático)               │
└──────────────────────┬──────────────────────────┘
                       │
                       │ POST /api/chat
                       ↓
┌─────────────────────────────────────────────────┐
│ Backend Hosting (Heroku, Railway, Cloud Run)    │
│ ├─ backend-app.herokuapp.com                    │
│ └─ FastAPI server                               │
└──────────────────────┬──────────────────────────┘
                       │
                       │ POST /chat/completions
                       ↓
┌─────────────────────────────────────────────────┐
│ Groq API (en internet)                          │
│ ├─ api.groq.com                                 │
│ └─ LLM Models                                   │
└─────────────────────────────────────────────────┘
```

---

## 📋 Configuración por Ambiente

### DESARROLLO

**groq_service.dart:**
```dart
baseUrl = 'http://localhost:8000'
```

**Backend corriendo:**
```bash
python main.py  # Escucha en 0.0.0.0:8000
```

**Flutter Web corriendo:**
```bash
flutter run -d web  # Abre en localhost:5173 (o similar)
```

### PRODUCCIÓN

**groq_service.dart:**
```dart
baseUrl = 'https://tu-backend.herokuapp.com'
// O
baseUrl = 'https://tu-backend.railway.app'
// O
baseUrl = 'https://api.tudominio.com'
```

**Backend hosteado:**
```bash
# Heroku
heroku create tu-app
heroku config:set GROQ_API_KEY=...
git push heroku main

# Resultado URL: https://tu-app.herokuapp.com
```

**Flutter Web hosteado:**
```bash
flutter build web --release

# Subir carpeta build/web/ a Vercel/Netlify/Firebase
firebase deploy

# Resultado URL: https://tuapp.firebaseapp.com
```

---

## 🔁 Ciclo de Desarrollo

```
1. Escribir código
   ├─ flutter/lib/services/groq_service.dart
   └─ backend/main.py

   ↓

2. Test localmente
   ├─ Terminal 1: flutter run -d web
   └─ Terminal 2: python main.py

   ↓

3. Verificar en navegador
   ├─ http://localhost:5173
   └─ Enviar mensaje en chat

   ↓

4. Si OK → Commit
   ├─ git add .
   └─ git commit -m "..."

   ↓

5. Deploy a producción
   ├─ git push heroku main (backend)
   └─ firebase deploy (flutter)

   ↓

6. Verificar en producción
   └─ https://tuapp.com
```

---

## 📊 Tabla Comparativa

| Aspecto | ❌ Antes | ✅ Después |
|---------|---------|-----------|
| Flutter Web | ❌ Error 400 | ✅ Funciona |
| Flutter Mobile | ❌ Expone API Key | ✅ Seguro |
| CORS | ❌ Bloqueado | ✅ Permitido |
| API Key | ❌ En navegador | ✅ En servidor |
| Groq Console | ❌ 0 llamadas | ✅ Registra uso |
| Producción | ❌ Imposible | ✅ Viable |
| Rate Limiting | ❌ No | ✅ Posible |
| Monitoreo | ❌ No | ✅ Centralized |

---

## 🚀 Estado Final

```
✅ Backend FastAPI corriendo
✅ Flutter apunta a tu backend
✅ CORS configurado
✅ Groq API accesible desde servidor
✅ Chatbot funciona en web
✅ API Key protegida
✅ Listo para producción
```

---

Diagrama ASCII alternativo (Terminal):
```
USER
  │
  ├─→ "Hola" (en chat)
  │
  ↓
FLUTTER WEB
  │
  ├─→ groq_service.sendMessage()
  │
  ↓
HTTP POST
  │
  ├─→ localhost:8000/api/chat
  │
  ↓
FASTAPI BACKEND
  │
  ├─→ Recibe: { user_message, chat_history }
  ├─→ Construye prompt
  ├─→ Llama a Groq: POST https://api.groq.com/...
  │
  ↓
GROQ API
  │
  ├─→ Procesa con LLM
  ├─→ Retorna: { content, usage }
  │
  ↓
FASTAPI BACKEND
  │
  ├─→ Recibe respuesta de Groq
  ├─→ Retorna al Frontend: { content, usage }
  │
  ↓
HTTP RESPONSE
  │
  ├─→ Status 200 OK
  │
  ↓
FLUTTER WEB
  │
  ├─→ Parsea respuesta
  ├─→ Actualiza ChatScreen
  │
  ↓
USER VE
  │
  └─→ Respuesta del asistente en chat ✅
```

¡Listo! 🎉
