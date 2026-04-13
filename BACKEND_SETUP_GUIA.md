# 🚀 Setup Rápido: Backend + Flutter Web

## El Problema (Ya Resuelto)

❌ Groq bloquea CORS desde navegadores
✅ Backend intermediario lo soluciona

## Arquitectura Nueva

```
Flutter Web
    ↓
Backend FastAPI (puerto 8000)
    ↓
Groq API
```

## Pasos para Funcionar

### 1️⃣ Configurar Backend (Windows)

```powershell
# Ir a la carpeta del backend
cd c:\Users\HP\Desktop\convive_\backend

# Crear virtual env
python -m venv venv

# Activar
venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Copiar .env.example a .env
# Luego editar .env y poner tu API Key de Groq
copy .env.example .env
# Editar .env con tu editor
```

**En el archivo `.env` que acabas de crear:**
```
GROQ_API_KEY=gsk_tuApiKeyAqui
GROQ_MODEL=llama-3.1-70b-versatile
```

### 2️⃣ Iniciar Backend

```powershell
# Desde la carpeta backend con venv activado
python main.py
```

✅ Verás:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### 3️⃣ Verificar que Funciona

En otra terminal (o PowerShell window), prueba:

```powershell
# Hacer un GET al health check
curl http://localhost:8000/health
```

Debería retornar:
```json
{
  "status": "ok",
  "service": "ConVive Backend",
  "groq_configured": true
}
```

Si dice `"groq_configured": false`, la API Key no está configurada correctamente.

### 4️⃣ Iniciar Flutter Web

En terminal diferente:

```bash
cd c:\Users\HP\Desktop\convive_
flutter run -d web
```

Flutter debería lanzar en `http://localhost:5173`

### 5️⃣ Probar Chatbot

- Abre `http://localhost:5173` en tu navegador
- Intenta enviar un mensaje en el chat
- ✅ Ahora NO debería dar error CORS
- ✅ La respuesta vendrá del backend → Groq

## 🔧 Configuración por Entorno

### DESARROLLO (Local)

`groq_service.dart`:
```dart
this.baseUrl = 'http://localhost:8000',
```

Backend: Ejecutar `python main.py` en tu PC

### PRODUCCIÓN

1. **Subir backend a hosting** (Heroku, Railway, AWS, etc.)
   
   Ejemplo Heroku:
   ```bash
   heroku create tu-app-convive
   heroku config:set GROQ_API_KEY=gsk_...
   git push heroku main
   ```

2. **Actualizar Flutter**
   
   `groq_service.dart`:
   ```dart
   this.baseUrl = 'https://tu-app-convive.herokuapp.com',
   ```

3. **Actualizar CORS en backend**
   
   En `backend/main.py`, línea 30:
   ```python
   origins = [
       "https://tu-dominio-flutter.com",
       "https://app.convive.com",
       # Etc...
   ]
   ```

## 📊 Flujo Completo

### Antes (❌ Fallaba)
```
Flutter Web (navegador)
    ↓
https://api.groq.com/openai/v1/chat/completions
    ↓
❌ CORS blocked! Error 400
```

### Ahora (✅ Funciona)
```
Flutter Web (navegador)
    ↓
http://localhost:8000/api/chat
    ↓
Backend (Python) - sin restricciones CORS
    ↓
https://api.groq.com/openai/v1/chat/completions
    ↓
✅ Groq responde con contenido
```

## 🐛 Troubleshooting

### "Error: groq_configured = false"
- ❌ API Key no encontrada
- ✅ Solución: Editar `.env` y poner API Key válida
- ✅ Reiniciar backend: `Ctrl+C` luego `python main.py`

### "error_code: 401_invalid_api_key"
- ❌ API Key expirada o mal copiada
- ✅ Solución: Generar nueva en https://console.groq.com

### "Connection refused" desde Flutter
- ❌ Backend no está corriendo
- ✅ Solución: Ejecutar `python main.py` en otra terminal

### "CORS policy blocked"
- ❌ El origen no está en `allow_origins`
- ✅ Agregar tu dominio en `backend/main.py` línea 30
- ✅ Reiniciar backend

### Flutter Web en puerto diferente
- ❌ Flutter abre en puerto 5174, 5175, etc.
- ✅ Agregar ese puerto a `allow_origins` en backend

## ✅ Verificación Final

Todo funciona si:

- [ ] Backend corre en `http://localhost:8000`
- [ ] `/health` retorna `"groq_configured": true`
- [ ] Flutter Web abre sin errores CORS
- [ ] Chatbot recibe respuestas de Groq
- [ ] Mensajes no fallan con error 400

## 📝 Notas

- **Seguridad**: API Key está PROTEGIDA en el servidor (nunca en el navegador)
- **Escalabilidad**: Puedes llamar al backend desde Android/iOS también
- **Costos**: El backend controla y registra el uso de Groq correctamente

¡Listo! 🎉
