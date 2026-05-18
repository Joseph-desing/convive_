# Deployment a Produccion

Guia para publicar ConVive fuera del entorno local.

## Componentes a Desplegar

1. Frontend Flutter Web o app movil.
2. Backend FastAPI para IA.
3. Supabase como backend principal.
4. Storage para imagenes y documentos.
5. Realtime para mensajes y notificaciones.

## Backend FastAPI

El backend se encuentra en `backend/`.

Variables necesarias:

```env
GROQ_API_KEY=tu_api_key
GROQ_MODEL=llama-3.1-70b-versatile
```

Comando de arranque:

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

### Railway o Render

1. Conectar el repositorio.
2. Elegir carpeta `backend` como servicio.
3. Configurar variables de entorno.
4. Definir comando de start.
5. Verificar `/health`.

### Render Blueprint

Tambien puedes usar `render.yaml` desde la raiz del repo. Render creara dos
servicios:

- `convive-ai-backend`: proxy de Groq (`backend/main.py`).
- `convive-chatbot-guided`: flujo guiado del chatbot (`chatbot_backend_mock.py`).

Variables requeridas:

```env
GROQ_API_KEY=tu_api_key_de_groq
SUPABASE_URL=https://xdpknfhbieejnqpjqpll.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_de_supabase
```

Cuando ambos servicios esten publicados, usa sus URLs en el build del APK:

```bash
flutter build apk --release --dart-define=AI_SERVICE_URL=https://convive-ai-backend.onrender.com --dart-define=CHATBOT_MOCK_URL=https://convive-chatbot-guided.onrender.com
```

### Docker

Ejemplo de Dockerfile:

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## APK conectado a produccion

El celular no puede usar `localhost` de tu PC. Compila el APK indicando la URL
publica del backend:

```bash
flutter build apk --release --dart-define=AI_SERVICE_URL=https://tu-backend.com
```

No uses `localhost` en `AI_SERVICE_URL` para el APK. Debe ser una URL accesible
desde internet o desde la red del telefono.

Si publicas tambien el flujo guiado del chatbot, agrega su URL:

```bash
flutter build apk --release --dart-define=AI_SERVICE_URL=https://tu-backend.com --dart-define=CHATBOT_MOCK_URL=https://tu-chatbot-guiado.com
```

## Flutter Web

Build:

```bash
flutter build web --release
```

La salida queda en:

```text
build/web
```

Opciones:

- Firebase Hosting.
- Netlify.
- Vercel.
- Hosting estatico propio.

Firebase:

```bash
firebase deploy
```

## Android

Build APK:

```bash
flutter build apk --release
```

Build App Bundle:

```bash
flutter build appbundle --release
```

Antes de publicar en Play Store:

- Reducir permisos Android.
- Revisar nombre, icono y package id.
- Configurar firmas.
- Probar en dispositivo real.
- Validar politicas de privacidad.

## iOS

```bash
flutter build ios --release
```

Antes de publicar:

- Configurar Bundle ID.
- Configurar certificados.
- Revisar permisos en `Info.plist`.
- Probar deep links.

## Supabase

Checklist:

- Tablas creadas.
- RLS activado.
- Policies revisadas.
- Buckets configurados.
- URLs de redirect de Auth configuradas.
- Edge Function `send-admin-email` desplegada si se usa envio administrativo.
- Backups habilitados.

## Seguridad Pre-Produccion

Obligatorio:

- Rotar claves expuestas.
- Eliminar `supabaseSecretKey` del cliente.
- Eliminar Groq API key del cliente.
- Usar variables de entorno en backend.
- Restringir CORS a dominios reales.
- Revisar permisos Android.
- Proteger rutas admin por rol.
- Confirmar RLS para `users`, `profiles`, `habits`, `properties`,
  `roommate_searches`, `feedback`, `notifications`, `matches`, `chats` y
  `messages`.

## Configuracion por Ambiente

Recomendado:

- `dev`: localhost y proyecto Supabase de pruebas.
- `staging`: backend desplegado y datos controlados.
- `prod`: backend y Supabase productivos.

Evitar URLs hardcodeadas como `localhost` en builds productivos.

## Verificacion Final

- Login funciona.
- Registro confirma email.
- Recuperacion de contrasena funciona.
- Perfil se guarda.
- Publicacion sube imagenes y PDF.
- Admin aprueba/rechaza.
- Home muestra solo publicaciones activas.
- Like genera notificacion.
- Chat realtime funciona.
- Chatbot responde.
- Usuario suspendido no entra.
- No hay claves privadas en el build.
