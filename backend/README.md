# ConVive Backend

Backend FastAPI usado como intermediario entre Flutter y proveedores de IA.

## Proposito

El backend evita que la aplicacion Flutter llame directamente a Groq desde el
cliente. Esto permite:

- Evitar CORS en Flutter Web.
- Proteger la API key en variables de entorno.
- Centralizar prompts y formato de respuesta.
- Agregar logging, rate limiting y reglas de seguridad en el servidor.

Flujo:

```text
Flutter -> FastAPI -> Groq API
```

## Archivos

```text
backend/
  main.py             API FastAPI
  requirements.txt    Dependencias Python
  README.md           Esta documentacion
```

## Dependencias

- `fastapi`: framework web.
- `uvicorn`: servidor ASGI.
- `httpx`: cliente HTTP async.
- `python-dotenv`: carga de `.env`.
- `pydantic`: validacion de modelos.

## Variables de Entorno

Crear `backend/.env`:

```env
GROQ_API_KEY=tu_api_key
GROQ_MODEL=llama-3.1-70b-versatile
```

Nunca subir `.env` al repositorio.

## Ejecucion Local

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Servidor local:

```text
http://localhost:8000
```

## Endpoints

### GET /health

Verifica que el backend este vivo y que Groq este configurado.

Respuesta:

```json
{
  "status": "ok",
  "service": "ConVive Backend",
  "groq_configured": true
}
```

### POST /api/chat

Procesa un mensaje del chatbot.

Request:

```json
{
  "user_message": "Busco un companero tranquilo",
  "chat_history": [
    {
      "role": "assistant",
      "content": "Hola, en que puedo ayudarte?"
    }
  ],
  "system_prompt": "Responde como asistente de ConVive",
  "user_id": "uuid",
  "user_profile": {
    "email": "usuario@correo.com",
    "subscription_type": "free"
  },
  "user_habits": {
    "cleanliness": 8,
    "noise_level": 4,
    "party_frequency": 1,
    "guests_frequency": 3
  }
}
```

Response:

```json
{
  "content": "Te conviene buscar perfiles con baja frecuencia de fiestas y alta limpieza.",
  "usage": {
    "prompt_tokens": 120,
    "completion_tokens": 40,
    "total_tokens": 160
  }
}
```

### POST /api/recommendations

Genera recomendaciones a partir de habitos o respuestas del usuario.

## CORS

El backend permite localhost para desarrollo. En produccion debe restringirse a
los dominios reales de la aplicacion web.

## Seguridad Pendiente

Antes de produccion:

- Usar solo variables de entorno para claves.
- Restringir CORS.
- Agregar autenticacion de requests con JWT Supabase.
- Agregar rate limiting.
- Agregar logs estructurados.
- Evitar devolver errores internos crudos al cliente.

## Despliegue

Opciones recomendadas:

- Railway.
- Render.
- Google Cloud Run.
- Heroku.
- VPS con Docker.

Ver `../DEPLOYMENT_PRODUCCION.md`.

