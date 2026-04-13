# ConVive Backend - Proxy Groq API

Servidor FastAPI que actúa como intermediario entre Flutter Web y Groq API.

## ¿Por qué?

Groq API bloquea CORS desde navegadores. Este backend evita ese problema:

```
Flutter Web → Este Backend (FastAPI) → Groq API
```

## Instalación

### 1. Crear ambiente virtual

```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python -m venv venv
source venv/bin/activate
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Configurar variables de entorno

```bash
# Copiar .env.example a .env
cp .env.example .env

# Editar .env y añadir tu API Key de Groq
# GROQ_API_KEY=gsk_...
```

## Uso Local

```bash
# Iniciar servidor
python main.py

# O directamente con uvicorn
uvicorn main:app --reload --port 8000
```

El servidor estará en: `http://localhost:8000`

### Verificar que funciona

```bash
curl http://localhost:8000/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "service": "ConVive Backend",
  "groq_configured": true
}
```

## Endpoints

### POST /api/chat

**Request:**
```json
{
  "user_message": "Hola, soy extrovertido y me encantan las fiestas",
  "chat_history": [
    {
      "role": "assistant",
      "content": "¿Cómo eres en cuanto a socialización?"
    }
  ],
  "user_id": "user_123",
  "user_profile": {
    "email": "user@example.com",
    "subscription_type": "free"
  },
  "user_habits": {
    "cleanliness": 8,
    "noise_level": 6,
    "party_frequency": 8,
    "guests_frequency": 7
  }
}
```

**Response:**
```json
{
  "content": "Perfecto, entonces buscamos compañeros con hábitos similares...",
  "usage": {
    "completion_tokens": 45,
    "prompt_tokens": 120,
    "total_tokens": 165
  }
}
```

### POST /api/recommendations

Obtener recomendaciones basadas en hábitos del usuario.

### GET /health

Verificar estado del servidor.

## Deployment (Producción)

### Opción 1: Heroku

```bash
# 1. Instalar Heroku CLI
# https://devcenter.heroku.com/articles/heroku-cli

# 2. Login
heroku login

# 3. Crear app
heroku create convive-backend

# 4. Configurar variables
heroku config:set GROQ_API_KEY=tu_api_key

# 5. Deploy
git push heroku main
```

### Opción 2: Railway

```bash
# Simplemente conecta tu GitHub repo a Railway
# Railway detecta requirements.txt y configura todo
```

### Opción 3: Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Deploy:
```bash
docker build -t convive-backend .
docker run -e GROQ_API_KEY=tu_api_key -p 8000:8000 convive-backend
```

## Actualizar Flutter para usar este Backend

En `groq_service.dart`, cambiar:

```dart
// ❌ Antes (directo a Groq, no funciona en Web)
baseUrl = 'https://api.groq.com/openai/v1'

// ✅ Después (a tu backend)
baseUrl = 'http://localhost:8000'  // Desarrollo
// baseUrl = 'https://tu-backend.com'  // Producción
```

Y cambiar el endpoint:
```dart
// ❌ Antes
Uri.parse('$baseUrl/chat/completions')

// ✅ Después
Uri.parse('$baseUrl/api/chat')
```

## Seguridad

- ✅ API Key de Groq se protege en el servidor (nunca se expone en el navegador)
- ✅ CORS configurado solo para dominios autorizados
- ⚠️ En producción, añade autenticación (ej: JWT tokens)
- ⚠️ Rate limiting para evitar abuso

## Troubleshooting

### "GROQ_API_KEY not configured"
- Verificar que .env existe y tiene la API Key
- Verificar que la API Key es válida en Groq

### "Error 401 from Groq"
- API Key expirada o inválida
- Generar nueva API Key en https://console.groq.com

### CORS Error desde Flutter
- Verificar que el origen está en `allow_origins` en `main.py`
- Añadir `http://localhost:5173` (o tu puerto Flutter)

## Soporte

Para más info:
- Documentación Groq: https://console.groq.com/docs
- Documentación FastAPI: https://fastapi.tiangolo.com/
