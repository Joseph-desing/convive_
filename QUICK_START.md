# Quick Start

Guia corta para levantar ConVive en desarrollo local.

## Requisitos

- Flutter SDK instalado.
- Dart incluido con Flutter.
- Python 3.10 o superior.
- Cuenta/proyecto de Supabase configurado.
- Opcional: API key de Groq para chatbot IA.

## 1. Instalar dependencias Flutter

Desde la raiz del proyecto:

```bash
flutter pub get
```

## 2. Ejecutar backend IA

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Crear archivo `.env` dentro de `backend/`:

```env
GROQ_API_KEY=tu_api_key_de_groq
GROQ_MODEL=llama-3.1-70b-versatile
```

Iniciar servidor:

```bash
python main.py
```

Verificar:

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

## 3. Ejecutar backend mock del chatbot

Algunos flujos del chatbot intentan usar primero el mock local en puerto `8001`.
Si necesitas probar ese flujo:

```bash
python chatbot_backend_mock.py
```

## 4. Ejecutar Flutter

Web:

```bash
flutter run -d chrome --dart-define=USE_LOCAL_BACKEND=true
```

Android:

```bash
flutter run -d android --dart-define=USE_LOCAL_BACKEND=true
```

Sin `USE_LOCAL_BACKEND=true`, la app no intenta conectarse a `localhost`.

APK conectado a backend publicado:

```bash
flutter build apk --release --dart-define=AI_SERVICE_URL=https://tu-backend.com
```

Si tambien publicas el backend guiado `chatbot_backend_mock.py`, agrega:

```bash
flutter build apk --release --dart-define=AI_SERVICE_URL=https://tu-backend.com --dart-define=CHATBOT_MOCK_URL=https://tu-chatbot-guiado.com
```

Build web:

```bash
flutter build web --release
```

## 5. Flujos basicos para probar

1. Registro con correo.
2. Confirmacion de email.
3. Login.
4. Completar perfil y habitos.
5. Crear publicacion con imagenes y PDF.
6. Revisar publicacion como admin.
7. Dar like desde home.
8. Revisar notificaciones.
9. Abrir chat.
10. Probar chatbot.

## 6. Problemas comunes

### El chatbot no responde

- Verifica `http://localhost:8000/health`.
- Verifica que `GROQ_API_KEY` exista en `backend/.env`.
- Si usa mock, verifica que `chatbot_backend_mock.py` este en puerto `8001`.

### En celular no conecta a localhost

En un telefono real, `localhost` apunta al telefono, no a tu PC. Usa la IP local
de tu maquina o un backend desplegado.

### Error de permisos en Supabase

Revisa politicas RLS. El cliente Flutter usa la anon key, por lo que cada tabla
debe tener policies correctas para select/insert/update/delete.

### Admin no ve datos

Confirma que el usuario tenga `role = 'admin'` en la tabla `users` y que RLS le
permita leer/actualizar las tablas administrativas.

## 7. Comandos utiles

```bash
flutter analyze
flutter test
flutter pub run build_runner build --delete-conflicting-outputs
flutter clean
flutter pub get
```
