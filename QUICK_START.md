# ⚡ Quick Start (5 minutos)

**Objetivo**: Que el chatbot funcione en Flutter Web en 5 minutos.

---

## Paso 1: Backend Setup (2 minutos)

Abre PowerShell en la carpeta del proyecto:

```powershell
# Ir a la carpeta backend
cd backend

# Crear ambiente virtual
python -m venv venv

# Activar
venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt
```

---

## Paso 2: Configurar API Key (1 minuto)

```powershell
# Crear .env
copy .env.example .env

# Editar .env (usa el editor que prefieras)
# Reemplaza: GROQ_API_KEY=gsk_tu_api_key_aqui
code .env  # Si tienes VS Code
```

Pega tu API Key de Groq (que comienza con `gsk_`)

---

## Paso 3: Iniciar Backend (30 segundos)

```powershell
# Con venv activado
python main.py
```

Deberías ver:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

✅ Backend está corriendo

---

## Paso 4: Verificar Backend (30 segundos)

Abre **otra terminal** y ejecuta:

```powershell
curl http://localhost:8000/health
```

Si ves:
```json
{"status": "ok", "service": "ConVive Backend", "groq_configured": true}
```

✅ Everything OK

---

## Paso 5: Iniciar Flutter Web (1 minuto)

Abre **otra terminal** en la carpeta del proyecto:

```bash
flutter run -d web
```

Espera a que compile y se abra el navegador.

---

## Paso 6: Probar Chatbot

En el navegador que apareció (probablemente `localhost:5173`):

1. Busca el chatbot
2. Escribe un mensaje
3. ✅ Debería responder

Si funciona: **¡Listo en 5 minutos!** 🎉

---

## ❌ Si no funciona

**Problema ①: "groq_configured: false"**
```
❌ Solución: API Key no está en .env
✅ Editar backend/.env con tu API Key
✅ Reiniciar backend
```

**Problema ②: "Connection refused" desde Flutter**
```
❌ Solución: Backend no está corriendo
✅ Verificar que `python main.py` está en otra terminal
✅ Verificar que dice "Uvicorn running on http://127.0.0.1:8000"
```

**Problema ③: CORS Error en navegador**
```
❌ Solución: Flutter en puerto diferente
✅ Verificar en cuál puerto corre (ej: 5174)
✅ Agregar ese puerto a backend/main.py línea ~30
✅ Reiniciar backend
```

---

## ✅ Checklist

- [ ] Backend activo en terminal 1
- [ ] health check retorna status OK
- [ ] Flutter corriendo en terminal 2
- [ ] Navegador abierto (localhost:5173 o similar)
- [ ] Chatbot responde sin errores

Si todo ✅ → **Terminado**

Si hay ❌ → Ver sección "Si no funciona" arriba

---

## Siguiente Paso

**Para producción:**
- Ver `DEPLOYMENT_PRODUCCION.md`

**Para troubleshooting:**
- Ver `BACKEND_TROUBLESHOOTING.md`

**Para info técnica:**
- Ver `CAMBIOS_RESUMEN.md`

---

**¡Es tan simple como ejecutar 3 terminales! ⚡**
