# ConVive

Aplicacion movil y web para conectar personas que buscan vivienda compartida,
departamentos y companeros compatibles. El sistema combina Flutter, Supabase,
mapas, chat en tiempo real, panel administrativo, verificacion de publicaciones
y un asistente conversacional apoyado por IA.

Este documento funciona como memoria tecnica del proyecto. Describe que se ha
implementado, como se organiza la aplicacion, que hace el backend, cuales son
los flujos principales y que puntos deben revisarse antes de produccion.

## 1. Resumen Ejecutivo

ConVive resuelve el problema de encontrar vivienda compartida de forma mas
segura, organizada y compatible. La app permite que un usuario:

- Cree una cuenta y confirme su correo.
- Complete perfil, foto, datos personales y habitos de convivencia.
- Publique una propiedad o una busqueda de companero.
- Adjunte imagenes y PDF de verificacion para revision administrativa.
- Explore publicaciones mediante tarjetas tipo swipe y mapa.
- Envie likes a propiedades o busquedas.
- Reciba notificaciones cuando alguien interactua con sus publicaciones.
- Genere conexiones y conversaciones por chat.
- Consulte un chatbot de ayuda y recomendaciones.
- Envie quejas, sugerencias o reportes.

El administrador puede:

- Revisar usuarios registrados.
- Suspender o reactivar cuentas.
- Revisar publicaciones pendientes.
- Aprobar o rechazar propiedades y busquedas.
- Gestionar quejas, sugerencias y reportes.
- Responder feedback y notificar a usuarios involucrados.
- Consultar estadisticas generales.

## 2. Objetivo del Proyecto

El objetivo principal es construir una plataforma que facilite la busqueda de
vivienda compartida usando criterios de convivencia reales. A diferencia de una
lista simple de anuncios, ConVive considera:

- Habitos de limpieza.
- Tolerancia al ruido.
- Frecuencia de fiestas.
- Tolerancia a invitados.
- Mascotas.
- Horarios de sueno.
- Tiempo en casa.
- Nivel de responsabilidad.
- Preferencias de genero y presupuesto.
- Ubicacion de propiedades y busquedas.

La idea central es reducir fricciones antes de vivir con otra persona y ofrecer
un entorno mas confiable gracias a verificacion de publicaciones, reportes,
notificaciones y administracion.

## 3. Alcance Implementado

### 3.1 Autenticacion

Implementado con Supabase Auth:

- Registro con correo y contrasena.
- Inicio de sesion.
- Confirmacion de correo.
- Recuperacion de contrasena por deep link.
- Cambio de contrasena desde la cuenta.
- Inicio con Google OAuth.
- Cierre de sesion.
- Deteccion de cuentas suspendidas.
- Redireccion segun estado del usuario.

Archivos principales:

- `lib/providers/auth_provider.dart`
- `lib/services/supabase_auth_service.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/email_verification_screen.dart`
- `lib/screens/forgot_password_screen.dart`
- `lib/screens/reset_password_screen.dart`
- `lib/screens/change_password_screen.dart`
- `lib/screens/suspended_account_screen.dart`

### 3.2 Perfil y Habitos

El usuario completa su perfil despues de registrarse. Este flujo guarda datos en
`profiles` y `habits`.

Datos de perfil:

- Nombre completo.
- Fecha de nacimiento.
- Genero.
- Biografia.
- Foto de perfil.

Datos de habitos:

- Nivel de limpieza.
- Tolerancia al ruido.
- Frecuencia de fiestas.
- Tolerancia a invitados.
- Mascotas.
- Tolerancia a mascotas.
- Modo de trabajo.
- Horario de sueno.
- Tiempo en casa.
- Responsabilidad.

Archivos principales:

- `lib/screens/complete_profile_screen.dart`
- `lib/screens/edit_habits_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/user_profile_screen.dart`
- `lib/providers/user_provider.dart`
- `lib/models/profile.dart`
- `lib/models/habits.dart`

### 3.3 Publicacion de Propiedades

Los usuarios pueden publicar departamentos o habitaciones. Las publicaciones
nuevas se crean como pendientes hasta ser revisadas por administracion.

Campos implementados:

- Titulo.
- Descripcion.
- Precio mensual.
- Direccion.
- Coordenadas.
- Fecha disponible.
- Numero de habitaciones.
- Alicuota incluida o no.
- Estado: pendiente, activa, inactiva.
- Imagenes.
- PDF de verificacion.
- Estado de alquilado.

Archivos principales:

- `lib/screens/create_property_screen.dart`
- `lib/screens/property_details_screen.dart`
- `lib/screens/my_publications_screen.dart`
- `lib/models/property.dart`
- `lib/models/property_image.dart`
- `lib/providers/property_provider.dart`
- `lib/services/supabase_storage_service.dart`

### 3.4 Busquedas de Roommate

Un usuario tambien puede publicar que busca companero o habitacion.

Campos implementados:

- Titulo.
- Descripcion.
- Presupuesto.
- Direccion.
- Coordenadas.
- Preferencia de genero.
- Preferencias de habitos.
- Imagenes.
- PDF de verificacion.
- Estado de revision.

Archivos principales:

- `lib/screens/create_roommate_search_screen.dart`
- `lib/screens/roommate_search_details_screen.dart`
- `lib/models/roommate_search.dart`
- `lib/providers/roommate_search_provider.dart`

### 3.5 Exploracion por Tarjetas

La pantalla principal muestra publicaciones en formato swipe. Hay dos pestanas:

- Departamentos.
- Companero/a.

El usuario puede:

- Dar like.
- Dar dislike.
- Ver ubicacion en mapa.
- Ver detalles visuales de la publicacion.
- Consultar compatibilidad calculada segun habitos.

Archivos principales:

- `lib/screens/home_screen.dart`
- `lib/widgets/property_card.dart`
- `lib/widgets/filter_sheet.dart`
- `lib/services/compatibility_service.dart`

### 3.6 Mapas y Ubicacion

La app usa `flutter_map` con coordenadas `latlong2`.

Funciones implementadas:

- Seleccionar ubicacion al crear publicaciones.
- Mostrar publicaciones en mapa.
- Mostrar vista previa de propiedad o busqueda.
- Abrir mapa desde tarjetas.
- Filtros basicos de publicaciones.

Archivos principales:

- `lib/screens/map_location_picker.dart`
- `lib/screens/map_posts_screen.dart`
- `lib/screens/map_property_preview_screen.dart`
- `lib/screens/map_roommate_preview_screen.dart`

### 3.7 Likes, Matches y Compatibilidad

El sistema registra swipes en Supabase. La compatibilidad se calcula localmente
comparando habitos.

Factores de compatibilidad:

- Horarios de sueno.
- Limpieza.
- Ruido.
- Fiestas.
- Invitados.
- Mascotas.
- Alcohol.
- Tiempo en casa.

Archivos principales:

- `lib/models/swipe.dart`
- `lib/models/match.dart`
- `lib/providers/matching_provider.dart`
- `lib/services/compatibility_service.dart`
- `lib/services/supabase_database_service.dart`

Nota: existen flujos historicos donde un like podia crear match automatico y
flujos mas recientes donde el match se confirma por reciprocidad/notificacion.
Antes de produccion conviene unificar esta regla de negocio.

### 3.8 Chat en Tiempo Real

El chat usa Supabase Realtime sobre la tabla `messages`.

Implementado:

- Obtener chats del usuario.
- Crear chat asociado a match.
- Listar mensajes.
- Enviar mensajes.
- Editar o eliminar mensajes.
- Escuchar mensajes nuevos por canal realtime.
- Guardar ultima lectura en `chat_reads`.
- Borrado suave de conversaciones para un usuario.

Archivos principales:

- `lib/screens/chat_screen.dart`
- `lib/screens/matches_screen.dart`
- `lib/models/chat.dart`
- `lib/models/message.dart`
- `lib/models/chat_preview.dart`
- `lib/services/supabase_messages_service.dart`
- `lib/services/supabase_realtime_service.dart`

### 3.9 Notificaciones

La app tiene notificaciones internas guardadas en Supabase. Tambien esta
incluida la dependencia de OneSignal para push notifications, aunque la
configuracion final requiere App ID real.

Implementado:

- Carga de notificaciones del usuario.
- Contador de no leidas.
- Marcar una o todas como leidas.
- Eliminar notificaciones.
- Realtime para nuevas notificaciones.
- Limpieza de notificaciones antiguas/duplicadas.
- Preferencia local para activar o desactivar notificaciones.

Archivos principales:

- `lib/providers/notifications_provider.dart`
- `lib/screens/notifications_screen.dart`
- `lib/screens/notification_match_screen.dart`
- `lib/screens/match_returned_screen.dart`
- `lib/models/notification.dart`

### 3.10 Chatbot e Inteligencia Artificial

El chatbot combina dos capas:

- Backend mock local en `chatbot_backend_mock.py`, usado para flujo guiado.
- Backend FastAPI en `backend/main.py`, usado como proxy hacia Groq.

El servicio Flutter intenta primero el backend mock en `localhost:8001`. Si no
esta disponible, usa Groq mediante el backend FastAPI.

Funciones:

- Mensaje de bienvenida.
- Conversacion con contexto del usuario.
- Recomendaciones basadas en respuestas y habitos.
- Fallback cuando el servidor no responde.

Archivos principales:

- `lib/screens/chatbot_screen.dart`
- `lib/providers/chatbot_provider.dart`
- `lib/services/chatbot_service.dart`
- `lib/services/groq_service.dart`
- `lib/config/groq_config.dart`
- `backend/main.py`
- `chatbot_backend_mock.py`

Importante: las claves privadas no deben vivir en Flutter. Deben moverse al
backend y cargarse por variables de entorno.

### 3.11 Panel Administrativo

El panel administrativo permite gestionar la plataforma.

Modulos:

- Dashboard general.
- Usuarios.
- Propiedades.
- Busquedas de roommate.
- Quejas y sugerencias.
- Perfil administrativo.

Funciones:

- Ver estadisticas.
- Filtrar usuarios por rol.
- Suspender o activar usuarios.
- Revisar publicaciones pendientes.
- Aprobar publicaciones.
- Rechazar publicaciones con nota.
- Notificar rechazo al usuario.
- Eliminar publicaciones.
- Responder quejas.
- Notificar a usuarios reportados.

Archivos principales:

- `lib/screens/admin_dashboard.dart`
- `lib/screens/admin_users_screen.dart`
- `lib/screens/admin_properties_screen.dart`
- `lib/screens/admin_feedback_screen.dart`
- `lib/screens/admin_profile_screen.dart`
- `lib/providers/admin_provider.dart`
- `lib/services/admin_service.dart`
- `lib/widgets/admin/admin_ui.dart`

## 4. Arquitectura General

```
Usuario
  |
  v
Flutter App
  |-- Providers: estado de UI y negocio
  |-- Services: acceso a Supabase, IA, storage y realtime
  |-- Models: objetos de dominio
  |-- Screens/Widgets: interfaz
  |
  +--> Supabase Auth
  +--> Supabase PostgreSQL
  +--> Supabase Storage
  +--> Supabase Realtime
  |
  +--> Backend FastAPI
          |
          +--> Groq API
```

## 5. Estructura del Proyecto

```
convive_/
  android/                 Proyecto Android
  ios/                     Proyecto iOS
  web/                     Proyecto Web
  assets/images/           Logos e imagenes
  backend/                 API FastAPI para IA
  docs/                    Documentacion academica/complementaria
  lib/
    config/                Configuracion de Supabase e IA
    constants/             Textos, dimensiones y constantes
    exceptions/            Excepciones de aplicacion
    models/                Modelos serializables
    providers/             Estado con Provider
    screens/               Pantallas
    services/              Acceso a backend, Supabase y storage
    utils/                 Helpers, colores, PDF picker
    widgets/               Componentes reutilizables
  test/                    Pruebas
```

## 6. Stack Tecnologico

Frontend:

- Flutter.
- Dart.
- Provider.
- GoRouter.
- Material/Cupertino.
- Flutter Map.
- Image Picker.
- File Picker.
- Shared Preferences.

Backend y servicios:

- Supabase Auth.
- Supabase PostgreSQL.
- Supabase Storage.
- Supabase Realtime.
- FastAPI.
- Uvicorn.
- httpx.
- Groq API.

Build y despliegue:

- Flutter Web.
- Firebase Hosting configurado en `firebase.json`.
- Android/iOS nativo.
- Backend Python desplegable en Railway, Render, Heroku, Cloud Run o servidor.

## 7. Modelo de Datos

Tablas principales usadas por la app:

- `users`: usuario de aplicacion, email, rol, suspension.
- `profiles`: perfil publico y datos personales.
- `habits`: habitos de convivencia.
- `properties`: publicaciones de departamentos/habitaciones.
- `property_images`: imagenes de propiedades.
- `roommate_searches`: busquedas de companero.
- `roommate_search_images`: imagenes asociadas a busquedas.
- `swipes`: likes/dislikes entre usuarios.
- `matches`: conexiones entre usuarios.
- `chats`: conversaciones asociadas a matches.
- `messages`: mensajes.
- `chat_reads`: ultima lectura por chat y usuario.
- `notifications`: notificaciones internas.
- `feedback`: quejas, sugerencias y reportes.
- `admin_messages`: mensajes administrativos.

## 8. Flujo Principal de Usuario

1. Usuario abre la app.
2. `SplashScreen` verifica sesion.
3. Si no hay sesion, navega a login.
4. Usuario se registra o inicia sesion.
5. Si el correo no esta confirmado, va a verificacion.
6. Si no tiene perfil, va a completar perfil.
7. En home ve propiedades y busquedas.
8. Puede dar like/dislike o abrir el mapa.
9. Si publica, sube imagenes y PDF.
10. Admin aprueba o rechaza.
11. Si hay interacciones, se generan notificaciones.
12. Si hay match/chat, los usuarios conversan.

## 9. Flujos Tecnicos Detallados

### 9.1 Registro e Inicio de Sesion

El flujo de autenticacion esta basado en Supabase Auth y se coordina desde
`AuthProvider`.

Registro:

1. El usuario ingresa nombre, correo y contrasena en `LoginScreen`.
2. La pantalla valida campos obligatorios y terminos.
3. `AuthProvider.signUp()` llama a `SupabaseAuthService.signUp()`.
4. Supabase crea el usuario en `auth.users`.
5. Se envia un correo de confirmacion.
6. Mientras el correo no este confirmado, la app redirige a
   `EmailVerificationScreen`.
7. Cuando el usuario confirma el correo, Supabase habilita la cuenta.
8. Al iniciar sesion por primera vez, si no existe registro en `public.users`,
   la app lo crea usando metadata de Supabase.
9. Si el usuario no tiene perfil completo, se redirige a
   `CompleteProfileScreen`.

Inicio de sesion:

1. `LoginScreen` llama a `AuthProvider.signIn()`.
2. Supabase valida correo y contrasena.
3. La app verifica si el correo esta confirmado.
4. Se consulta `public.users`.
5. Si `is_suspended = true`, se cierra sesion y se envia a
   `SuspendedAccountScreen`.
6. Si el rol es `admin`, se redirige a `/admin`.
7. Si es usuario normal, se redirige a `/home`.

Archivos relacionados:

- `lib/screens/login_screen.dart`
- `lib/providers/auth_provider.dart`
- `lib/services/supabase_auth_service.dart`
- `lib/config/supabase_provider.dart`
- `lib/main.dart`

### 9.2 Confirmacion de Correo

La confirmacion de correo usa enlaces enviados por Supabase.

En web:

- El redirect configurado apunta a la ruta de confirmacion web.
- La app intenta intercambiar el `code` por una sesion con
  `exchangeCodeForSession`.
- Si la sesion se crea correctamente, redirige a home.
- Si no se crea sesion, muestra confirmacion y envia a login.

En movil:

- Se usan deep links con esquema `com.example.convive`.
- `app_links` escucha los enlaces entrantes.
- El listener esta en `main.dart`.
- Si el host es `login-callback`, se redirige a home o login segun sesion.

Archivos relacionados:

- `lib/main.dart`
- `lib/screens/email_verification_screen.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### 9.3 Recuperacion de Contrasena

El reset password esta implementado para web y movil.

Solicitud de recuperacion:

1. El usuario entra a `ForgotPasswordScreen`.
2. Ingresa su correo.
3. `AuthProvider.resetPassword()` llama a
   `SupabaseProvider.client.auth.resetPasswordForEmail()`.
4. Supabase envia un correo con enlace de recuperacion.
5. El redirect cambia segun plataforma:
   - Web: ruta `/#/reset-password`.
   - Movil: deep link `com.example.convive://reset-password`.

Recepcion del enlace:

1. `main.dart` escucha deep links con `AppLinks`.
2. Si el enlace contiene `code`, `token`, `access_token` o `type=recovery`,
   la app extrae esos parametros.
3. Se navega a `/reset-password`.
4. `ResetPasswordScreen` recibe el token/codigo y correo si esta disponible.

Cambio de contrasena:

1. El usuario escribe la nueva contrasena.
2. La app intenta actualizar la contrasena con la sesion activa.
3. Si falla, intenta verificar el codigo como OTP recovery usando Supabase.
4. Cuando Supabase valida el token/codigo, se ejecuta `updateUser()` con la
   nueva contrasena.
5. Al finalizar, la app cierra la sesion temporal.
6. El usuario vuelve a login para entrar con la nueva contrasena.

Manejo de errores:

- Token expirado: se muestra mensaje para solicitar nuevo enlace.
- Token invalido: se informa al usuario.
- Contrasena debil: se pide minimo de caracteres.
- Errores de red: se informa error de conexion.

Archivos relacionados:

- `lib/screens/forgot_password_screen.dart`
- `lib/screens/reset_password_screen.dart`
- `lib/providers/auth_provider.dart`
- `lib/main.dart`
- `web/reset-password.html`

### 9.4 Perfil, Habitos y Compatibilidad

Despues de autenticarse, el usuario debe completar su perfil.

Flujo:

1. `CompleteProfileScreen` recolecta informacion personal.
2. Si hay imagen, se sube a Supabase Storage.
3. Se crea registro en `profiles`.
4. Se crea o actualiza registro en `habits`.
5. La app usa esos habitos para calcular compatibilidad.

La compatibilidad no depende solo de distancia o precio. Se calcula comparando
habitos mediante `CompatibilityService`.

Factores:

- Horario de sueno.
- Limpieza.
- Ruido.
- Fiestas.
- Invitados.
- Mascotas.
- Alcohol.
- Tiempo en casa.

Archivos relacionados:

- `lib/screens/complete_profile_screen.dart`
- `lib/models/profile.dart`
- `lib/models/habits.dart`
- `lib/services/compatibility_service.dart`

### 9.5 Publicacion y Verificacion de Propiedades

Cuando un usuario publica una propiedad:

1. Completa titulo, descripcion, precio, direccion y disponibilidad.
2. Selecciona ubicacion en mapa.
3. Agrega fotos.
4. Adjunta PDF de verificacion.
5. La app crea la propiedad con estado pendiente/inactivo.
6. Las imagenes se guardan en Supabase Storage.
7. Las URLs se registran en `property_images`.
8. El PDF se sube al bucket de storage.
9. El administrador revisa y aprueba o rechaza.

Estados:

- `pending`: esperando revision.
- `active`: visible en home/mapa.
- `inactive`: rechazada o inactiva.
- `is_rented`: indica si ya fue alquilada.

Archivos relacionados:

- `lib/screens/create_property_screen.dart`
- `lib/screens/my_publications_screen.dart`
- `lib/services/supabase_storage_service.dart`
- `lib/services/supabase_database_service.dart`

### 9.6 Busqueda de Roommate

La busqueda de roommate funciona parecido a una propiedad, pero enfocada en una
persona que busca companero.

Flujo:

1. Usuario crea busqueda con titulo, descripcion y presupuesto.
2. Define direccion y coordenadas.
3. Indica preferencia de genero si aplica.
4. Selecciona preferencias/habitos.
5. Sube imagenes y PDF de verificacion.
6. La publicacion queda pendiente de revision.
7. Admin aprueba o rechaza.
8. Si esta activa, aparece en home y mapa.

Archivos relacionados:

- `lib/screens/create_roommate_search_screen.dart`
- `lib/models/roommate_search.dart`
- `lib/providers/roommate_search_provider.dart`

### 9.7 Likes, Notificaciones y Matches

Flujo de interaccion:

1. En `HomeScreen`, el usuario ve tarjetas de departamentos o busquedas.
2. Puede hacer dislike o like.
3. El swipe se guarda en `swipes`.
4. Si es like, se crea una notificacion para el propietario o creador de la
   busqueda.
5. Las notificaciones aparecen en `NotificationsScreen`.
6. Si existe reciprocidad o confirmacion de match, se crea un registro en
   `matches`.
7. Al existir match, se crea o recupera un chat asociado.

Archivos relacionados:

- `lib/screens/home_screen.dart`
- `lib/providers/notifications_provider.dart`
- `lib/providers/matching_provider.dart`
- `lib/services/supabase_database_service.dart`
- `lib/services/supabase_messages_service.dart`

### 9.8 Chat entre Usuarios

El chat se apoya en Supabase Realtime.

Flujo:

1. El usuario entra a `MatchesScreen`.
2. La app carga matches del usuario.
3. Cada match puede tener un chat asociado.
4. `ChatScreen` carga mensajes previos.
5. Al enviar mensaje, se inserta en `messages`.
6. Supabase Realtime notifica a los clientes suscritos al chat.
7. La app actualiza la vista sin recargar.
8. `chat_reads` guarda la ultima lectura para saber que mensajes estan
   pendientes.

Archivos relacionados:

- `lib/screens/chat_screen.dart`
- `lib/screens/matches_screen.dart`
- `lib/services/supabase_messages_service.dart`
- `lib/models/chat.dart`
- `lib/models/message.dart`

### 9.9 Chatbot

El chatbot esta disenado para asistir al usuario en la busqueda de vivienda y
companeros.

Capas:

1. `ChatbotScreen`: interfaz de conversacion.
2. `ChatbotProvider`: estado de mensajes, carga y errores.
3. `ChatbotService`: decide si usa mock local o Groq.
4. `chatbot_backend_mock.py`: backend local de flujo guiado.
5. `backend/main.py`: backend FastAPI para conectarse con Groq.
6. Groq API: modelo de lenguaje.

Flujo:

1. El usuario abre el chatbot.
2. Se carga un mensaje de bienvenida.
3. El usuario escribe o selecciona una opcion.
4. La app intenta enviar el mensaje al mock local `localhost:8001`.
5. Si el mock responde, se usa esa respuesta.
6. Si el mock no esta disponible, se usa fallback a Groq mediante FastAPI.
7. El backend FastAPI arma el prompt con perfil y habitos del usuario.
8. Groq genera la respuesta.
9. Flutter muestra el mensaje en la conversacion.

Tipos de respuesta:

- Mensaje normal del asistente.
- Opciones seleccionables.
- Recomendaciones.
- Sugerencias de usuarios o publicaciones compatibles.
- Mensajes de error si el backend no esta disponible.

Archivos relacionados:

- `lib/screens/chatbot_screen.dart`
- `lib/providers/chatbot_provider.dart`
- `lib/services/chatbot_service.dart`
- `lib/services/groq_service.dart`
- `backend/main.py`
- `chatbot_backend_mock.py`

### 9.10 Panel Administrativo

El panel administrativo centraliza moderacion y control.

Flujo de acceso:

1. Usuario inicia sesion.
2. `AuthProvider` carga su rol desde `users`.
3. Si el rol es `admin`, se redirige a `/admin`.
4. Desde el dashboard se accede a usuarios, propiedades, busquedas y feedback.

Funciones:

- Dashboard con estadisticas.
- Gestion de usuarios.
- Suspension de cuentas.
- Revision de publicaciones.
- Aprobacion de propiedades y busquedas.
- Rechazo con nota administrativa.
- Gestion de quejas, sugerencias y reportes.
- Respuesta al feedback.
- Notificaciones administrativas.

Archivos relacionados:

- `lib/screens/admin_dashboard.dart`
- `lib/screens/admin_users_screen.dart`
- `lib/screens/admin_properties_screen.dart`
- `lib/screens/admin_feedback_screen.dart`
- `lib/providers/admin_provider.dart`
- `lib/services/admin_service.dart`

## 10. Backend FastAPI

Ubicacion: `backend/main.py`.

Responsabilidades:

- Proveer endpoint de salud.
- Recibir mensajes del chatbot.
- Construir prompt con contexto del usuario.
- Enviar solicitud a Groq.
- Retornar respuesta limpia a Flutter.
- Evitar problemas de CORS del navegador.
- Mantener la API key fuera del cliente cuando se configure correctamente.

Endpoints:

- `GET /health`: verifica estado del servicio y si Groq esta configurado.
- `POST /api/chat`: procesa mensaje conversacional.
- `POST /api/recommendations`: genera recomendaciones por habitos.

Variables esperadas:

- `GROQ_API_KEY`
- `GROQ_MODEL`

Ver mas en `backend/README.md`.

## 11. Seguridad y Riesgos Pendientes

Antes de produccion se deben atender estos puntos:

- Rotar cualquier clave privada que haya estado en el repositorio.
- Quitar claves secretas del cliente Flutter.
- Mover Groq API key exclusivamente al backend.
- Proteger rutas admin por rol en frontend y en RLS.
- Revisar politicas RLS de Supabase para todas las tablas sensibles.
- Reducir permisos Android al minimo necesario.
- Cambiar URLs `localhost` por configuracion por ambiente.
- Evitar signed URLs de PDF con duracion excesiva.
- Unificar reglas de match para que no existan flujos contradictorios.
- Validar que los usuarios no puedan cambiarse a rol admin o propietario si no corresponde.

## 12. Ejecucion Local

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar app:

```bash
flutter run
```

Ejecutar web:

```bash
flutter run -d chrome
```

Backend IA:

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Ver guia rapida completa en `QUICK_START.md`.

## 13. Pruebas y Calidad

Estado actual:

- Existe `test/widget_test.dart`, pero es una prueba placeholder.
- El analizador puede tardar demasiado en el entorno actual.
- Falta cobertura automatizada de flujos criticos.

Pruebas recomendadas:

- Registro, login y confirmacion de correo.
- Recuperacion de contrasena.
- Creacion/edicion de perfil.
- Creacion de propiedad con imagenes y PDF.
- Aprobacion/rechazo por admin.
- Swipe, notificacion y match.
- Chat realtime.
- Restricciones RLS.
- Cuentas suspendidas.

## 14. Documentacion Vigente

- `README.md`: memoria tecnica general.
- `QUICK_START.md`: guia para ejecutar en local.
- `backend/README.md`: API del backend FastAPI.
- `DEPLOYMENT_PRODUCCION.md`: pasos para produccion.
- `DOCUMENTACION_INDICE.md`: indice de documentacion.
- `docs/Librerias_seleccionadas.md`: librerias usadas.
- `docs/Herramientas_seleccionadas.md`: herramientas usadas.

## 15. Estado de Implementacion

Implementado:

- Autenticacion completa con Supabase.
- Deep links para auth y recuperacion.
- Perfil y habitos.
- Publicaciones de propiedades.
- Busquedas de roommate.
- Imagenes y PDF de verificacion.
- Home con swipe.
- Mapa de publicaciones.
- Compatibilidad por habitos.
- Notificaciones internas con realtime.
- Chat con realtime.
- Panel admin.
- Quejas y sugerencias.
- Chatbot con backend local y FastAPI/Groq.
- Temas claro/oscuro.
- Localizacion base ES/EN.

Pendiente para produccion:

- Seguridad de claves.
- RLS auditado.
- Menos permisos Android.
- Configuracion por ambiente.
- Tests reales.
- Despliegue estable del backend IA.
- Limpieza final de logs `print`/`debugPrint`.
