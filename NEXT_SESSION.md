# 🚀 PRÓXIMA SESIÓN - Orden de Inicialización

Cuando cierres y vuelvas a abrir Visual Studio Code, sigue este orden **EXACTO**:

---

## **PASO 1: Abre 2 Terminales PowerShell** 
(Terminal 1 para backend, Terminal 2 para frontend)

---

## **TERMINAL 1 - BACKEND (Puerto 8000)**

```powershell
# Navega a backend
cd c:\Users\HP\Desktop\convive_\backend

# Activa entorno virtual
venv\Scripts\activate

# Ejecuta backend
python main.py
```

**Deberías ver:**
```
✅ Cliente HTTP inicializado
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

✅ **DEJA ESTE TERMINAL CORRIENDO** (no lo cierres)

---

## **TERMINAL 2 - FRONTEND (Puerto 5173)**

En otra terminal PowerShell:

```powershell
# Navega a la raíz
cd c:\Users\HP\Desktop\convive_

# Limpia (importante después de cambios)
flutter clean

# Descarga dependencias
flutter pub get

# Ejecuta en web
flutter run -d web
```

**Deberías ver:**
```
✅ Launching web
app is listening on http://localhost:5173
```

---

## **PASO 2: Abre el navegador**

```
http://localhost:5173
```

---

## **PASO 3: Prueba el Chatbot**

1. Navega al chatbot
2. Escribe un mensaje
3. Deberías ver respuesta de Groq

---

## 📋 CHECKLIST RÁPIDO:

- [ ] Terminal 1: Backend en `http://localhost:8000` ✅
- [ ] Terminal 2: Flutter en `http://localhost:5173` ✅
- [ ] Archivo `.env` existe en `backend/.env` con `GROQ_API_KEY` ✅
- [ ] `groq_service.dart` apunta a `http://localhost:8000` ✅

---

## ⚠️ PROBLEMAS COMUNES:

### Puerto 8000 en uso
```powershell
taskkill /F /IM python.exe
```

### Port 5173 en uso
```powershell
flutter run -d web -v --port=5174
```

### App no conecta al backend
1. Verifica backend está corriendo: `curl http://localhost:8000/health`
2. Recarga Flutter: presiona `R` en terminal

---

## 🔧 ARCHIVO IMPORTANTE

Configuración que NO cambiar:
- `backend/.env` → Tiene GROQ_API_KEY
- `lib/services/groq_service.dart` → Apunta a localhost:8000
- `backend/main.py` → Backend corriendo

**TODO LISTO PARA PRÓXIMA SESIÓN ✅**
