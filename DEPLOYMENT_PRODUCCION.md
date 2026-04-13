# 🚀 Deployment a Producción - Backend + Flutter Web

## Resumen

Para producción, necesitas:

1. **Backend** - Hosteado en servidor (no en tu PC)
2. **Flutter Web** - Build HTML/JS estático
3. **Configuración** - URLs y CORS actualizadas

---

## Opción 1: Heroku (Recomendado - Rápido)

### Requisitos
- Cuenta en https://heroku.com (plan free o paid)
- Heroku CLI instalado: https://devcenter.heroku.com/articles/heroku-cli
- Git configurado

### Pasos

**1. Login a Heroku**
```bash
heroku login
```

**2. Crear app**
```bash
cd backend
heroku create tu-app-convive-backend
```

Esto te dará una URL como: `https://tu-app-convive-backend.herokuapp.com`

**3. Configurar variables de entorno**
```bash
heroku config:set GROQ_API_KEY=gsk_tu_api_key --app tu-app-convive-backend
heroku config:set GROQ_MODEL=llama-3.1-70b-versatile --app tu-app-convive-backend
```

**4. Crear archivo `Procfile`** (si no existe)
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

**5. Deploy**
```bash
git add .
git commit -m "Backend para producción"
git push heroku main
```

**6. Verificar**
```bash
curl https://tu-app-convive-backend.herokuapp.com/health
```

Debe retornar:
```json
{
  "status": "ok",
  "service": "ConVive Backend",
  "groq_configured": true
}
```

---

## Opción 2: Railway (Más fácil)

### Requisitos
- Cuenta en https://railway.app (con GitHub)

### Pasos

**1. Conectar GitHub**
- Ir a https://railway.app
- Click en "New Project" → "Deploy from GitHub repo"
- Seleccionar tu repo

**2. Configurar variables**
- En Railway dashboard, settings:
  - `GROQ_API_KEY` = tu_api_key
  - `GROQ_MODEL` = llama-3.1-70b-versatile

**3. Railway detecta automáticamente**
- Ve el archivo `requirements.txt`
- Ve que es Python
- Deployea automáticamente

**4. Obtener URL**
- Railway te da una URL como: `https://modulo-prod.up.railway.app`

---

## Opción 3: Docker + AWS/Google Cloud

### Crear archivo `Dockerfile`
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ENV PORT=8000
EXPOSE $PORT

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Build local
```bash
docker build -t convive-backend .
docker run -e GROQ_API_KEY=gsk_... -p 8000:8000 convive-backend
```

### Subir a Google Cloud Run
```bash
gcloud run deploy convive-backend \
  --source . \
  --region us-central1 \
  --set-env-vars GROQ_API_KEY=gsk_...
```

---

## Actualizar Flutter Web para Producción

### 1. Cambiar Base URL

En `lib/services/groq_service.dart`:

```dart
// ❌ Antes (desarrollo)
this.baseUrl = 'http://localhost:8000',

// ✅ Después (producción)
this.baseUrl = 'https://tu-app-convive-backend.herokuapp.com',
```

### 2. Build Flutter Web
```bash
flutter build web --release
```

Genera carpeta: `build/web/`

### 3. Opcional: Subir Flutter Web también

**Si quieres Flutter Web hosteado:**

#### Con Firebase Hosting
```bash
firebase init hosting
firebase deploy --project convive-app
```

#### Con Netlify
```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

#### Con Vercel
```bash
npm install -g vercel
vercel --prod
```

---

## Actualizar CORS en Backend

Ahora que tienes URLs finales:

En `backend/main.py`, línea ~30:

```python
origins = [
    # Desarrollo
    "http://localhost:5173",
    "http://localhost:5174",
    "http://127.0.0.1:5173",
    
    # Producción Flutter Web (si lo hosteaste)
    "https://convive-app.vercel.app",
    "https://convive.netlify.app",
    "https://convive.firebaseapp.com",
    
    # O si lo abres desde tu dominio
    "https://app.convive.com",
]
```

Push al repositorio:
```bash
git add backend/main.py
git commit -m "Actualizar CORS para producción"
git push
```

---

## Checklist Pre-Producción

Backend:
- [ ] Código probado localmente
- [ ] `.env` con variables correctas
- [ ] `Procfile` existe (si usas Heroku)
- [ ] CORS configurado para dominios reales
- [ ] Health check funcionando

Flutter:
- [ ] Base URL apunta a backend en producción
- [ ] Build de producción: `flutter build web --release`
- [ ] Testing en navegador

Seguridad:
- [ ] API Key de Groq protegida (solo en servidor)
- [ ] CORS restringido a dominios conocidos
- [ ] No subir archivos `.env` a Git (usar `.gitignore`)

---

## Monitoreo en Producción

### Ver logs en Heroku
```bash
heroku logs --tail --app tu-app-convive-backend
```

### Ver logs en Railway
- Dashboard → Logs tab

### Google Cloud Run metrics
- Dashboard → Monitoring

---

## Actualizar Código en Producción

### Si cambias el backend

1. Test localmente
2. Push a GitHub
3. Heroku/Railway redepoya automáticamente
4. Verificar: `https://tu-backend/health`

### Si cambias Flutter

1. Test localmente: `flutter run -d web`
2. Build: `flutter build web --release`
3. Deploy: 
   - Con Firebase: `firebase deploy`
   - Con Netlify: `netlify deploy --prod`
   - Con Vercel: `vercel --prod`

---

## Costos Estimados (USD/mes)

| Servicio | Costo |
|----------|-------|
| Heroku | $7-50 (dyno pequeño) |
| Railway | $5-20 (pay-as-you-go) |
| Google Cloud Run | Free (si < 2M requests) |
| Firebase Hosting | Free (5GB/mes) |
| Vercel | Free (proyecto básico) |

---

## Optimizaciones

### Rate Limiting
Agregar a `backend/main.py`:
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/api/chat")
@limiter.limit("30/minute")  # 30 calls/min
async def chat(request: ChatRequest):
    ...
```

### Caching
Cachear respuestas comunes:
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def get_response_cached(message_hash):
    ...
```

### Logging centralizado
```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("📨 Mensaje procesado")
```

---

## Soporte

- **Heroku**: https://devcenter.heroku.com/
- **Railway**: https://docs.railway.app/
- **Google Cloud Run**: https://cloud.google.com/run/docs
- **FastAPI**: https://fastapi.tiangolo.com/deployment/

---

**Nota**: Una vez en producción, es relativamente fácil actualizar bien el backend como el frontend sin downtime. ¡Usa esto a tu favor! 🚀
