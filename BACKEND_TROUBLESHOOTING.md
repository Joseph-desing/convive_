# 🔧 Troubleshooting - Backend + Flutter Web

## Escenario 1: "HTTP 400 en el chatbot"

### Síntoma
```
Error en Groq service: Error en Backend service: ...
```

### Diagnóstico

**Paso 1**: Verificar que backend está corriendo
```powershell
curl http://localhost:8000/health
```

Si no funciona: Backend no levantado

**Paso 2**: Si backend corre pero HTTP 400
```powershell
# Verificar logs del backend
# Debería decir qué error retorna Groq
```

### Soluciones

| Problema | Solución |
|----------|----------|
| `"GROQ_API_KEY no configurada"` | Editar `.env` con API Key válida |
| `"401_invalid_api_key"` | Generar nueva API Key en https://console.groq.com |
| `"model not found"` | Verificar modelo en `.env`: `llama-3.1-70b-versatile` |
| `"rate_limit_exceeded"` | Esperar unos minutos, luego reintentar |

---

## Escenario 2: "CORS policy blocked"

### Síntoma
```
Access to XMLHttpRequest at 'http://localhost:8000/...'
from origin 'http://localhost:5173' has been blocked by CORS policy
```

### Causa
El puerto de Flutter WebNo está en `allow_origins` del backend

### Solución

**Paso 1**: Identificar en cuál puerto corre Flutter
```
El output de `flutter run -d web` dice:
"Launching lib/main.dart on Chrome in debug mode..."
```

Busca la URL: `http://localhost:PORT`

**Paso 2**: Agregar ese origen al backend

Editar `backend/main.py`, línea ~30:
```python
origins = [
    "http://localhost:5173",  # Cambiar si es otro puerto
    "http://localhost:5174",
    "http://localhost:5175",
    "http://127.0.0.1:5173",
]
```

**Paso 3**: Reiniciar backend
```powershell
# Ctrl+C en la terminal donde corre el backend
python main.py
```

---

## Escenario 3: "Connection refused"

### Síntoma
```
Error connecting to http://localhost:8000
Connection refused
```

### Causa
Backend no está corriendo

### Solución

**Opción 1**: Backend nunca se inició
```powershell
cd backend
venv\Scripts\activate
python main.py
```

**Opción 2**: Backend se cerró
- Ver si hay errores en la terminal
- Reiniciar: `python main.py`

**Opción 3**: Puerto ocupado
Si dice `Address already in use`:
```powershell
# Buscar proceso en puerto 8000
netstat -ano | findstr :8000

# Si encuentras un PID, matalo:
taskkill /PID <PID> /F

# Reiniciar backend
python main.py
```

---

## Escenario 4: Backend dice "groq_configured: false"

### Síntoma
```json
{
  "status": "ok",
  "service": "ConVive Backend",
  "groq_configured": false
}
```

### Causa
Variable `GROQ_API_KEY` no está configurada

### Solución

**Paso 1**: Verificar archivo `.env` existe
```powershell
ls backend/.env
```

Si no existe:
```powershell
copy backend\.env.example backend\.env
```

**Paso 2**: Editar `.env` con tu API Key
```
GROQ_API_KEY=gsk_abc123defg456hij...
GROQ_MODEL=llama-3.1-70b-versatile
```

⚠️ **Importante**: 
- La API Key comienza con `gsk_`
- No incluyas comillas
- No dejes espacios extra

**Paso 3**: Reiniciar backend
```powershell
python main.py
```

Verificar:
```powershell
curl http://localhost:8000/health
```

Debe decir `"groq_configured": true`

---

## Escenario 5: "Error 401: Invalid API Key"

### Síntoma
```
Backend Error 401: invalid_request_error
Error code: 401 - Invalid authentication credentials
```

### Causa
API Key de Groq expirada o inválida

### Solución

**Paso 1**: Ir a https://console.groq.com

**Paso 2**: 
- Verificar que API Key sigue siendo válida
- Si no: Generar una nueva

**Paso 3**: 
- Copiar la nueva API Key
- Pegar en `.env`
- Reiniciar backend

---

## Escenario 6: "Timeout en backend"

### Síntoma
```
Error en Groq service: Timeout en backend
```

### Causa
- Groq tarda mucho en responder (sobrecarga)
- Conexión lenta
- Query muy compleja

### Solución

**Corto plazo**: Reintentar después de 30 segundos

**Largo plazo**: 
- Si es frecuente, aumentar timeout en `groq_service.dart`:
```dart
.timeout(
  const Duration(seconds: 30),  // Cambiar de 20 a 30
  onTimeout: () => throw Exception('Timeout'),
),
```

---

## Escenario 7: "chatbot retorna respuestas vacías"

### Síntoma
El chatbot responde pero el mensaje está vacío

### Causa
- Groq retornó respuesta vacía
- Error en parsing
- Token limit alcanzado

### Solución

**Opción 1**: Verificar logs del backend
En la terminal donde corre backend, busca:
```
❌ Groq Error 400
📤 Request Body: {...}
```

**Opción 2**: Reducir `max_tokens` en `backend/main.py`
```python
'max_tokens': 512,  # Cambiar de 1024 a 512
```

**Opción 3**: Simplificar el prompt de sistema
Mensajes muy largos pueden causar problemas

---

## Escenario 8: Django/Flask vs FastAPI

### Si usas otro framework

**Express.js (Node.js):**
```javascript
app.get('/health', (req, res) => {
  res.json({ status: 'ok', groq_configured: true });
});

app.post('/api/chat', async (req, res) => {
  // Llamar a Groq aqui
});
```

**Django (Python):**
```python
@api_view(['POST'])
def chat(request):
    # Llamar a Groq aqui
    return Response({'content': content})
```

La lógica es la misma, solo cambia el framework

---

## Escenario 9: Producción (Heroku)

### Error: Backend no responde
```
Connection to tu-app.herokuapp.com refused
```

**Solución:**
```bash
# Ver logs
heroku logs --app tu-app --tail

# Redeploy
git push heroku main

# Restart
heroku restart --app tu-app
```

### Verificar en producción
```bash
curl https://tu-app.herokuapp.com/health
```

---

## Checklist - "Nada funciona"

- [ ] Backend corriendo: `curl http://localhost:8000/health`
- [ ] GROQ_API_KEY en `.env`: `grep GROQ_API_KEY backend/.env`
- [ ] API Key válida: Verificar en https://console.groq.com
- [ ] Flutter en puerto correcto: Ver output de `flutter run -d web`
- [ ] Puerto Flutter en allow_origins: Editar `backend/main.py`
- [ ] Sin firewall bloqueando: Verificar antivirus/firewall
- [ ] groq_configured = true: `curl http://localhost:8000/health`

---

## Logs Útiles

### Ver logs detallados del backend
```powershell
# Con uvicorn
python -m uvicorn main:app --reload --log-level=debug
```

### Ver requests/responses en Flutter
```dart
// En groq_service.dart, descomentar para debug
print('📨 Request: ${jsonEncode(...)}');
print('✅ Response: $content');
```

---

## ¿Aún no funciona?

1. Copia el error exacto
2. Vuelca los logs del backend
3. Comparte:
   - Error message
   - Backend logs
   - `groq_service.dart` configuración
   - `.env` (sin API Key)

---

**Nota**: 99% de los problemas son:
1. Backend no corriendo
2. API Key inválida
3. CORS mal configurado
4. Puerto Flask incorrecto

¡Revisa esos primero! ✅
