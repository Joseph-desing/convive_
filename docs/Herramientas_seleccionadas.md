# Herramientas Seleccionadas

Este documento resume las herramientas usadas para construir, ejecutar,
probar y desplegar ConVive.

## Herramientas de Desarrollo

| Herramienta | Uso | Justificacion |
| --- | --- | --- |
| Flutter CLI | Compilar y ejecutar la app | Permite correr la app en web, Android, iOS y desktop. |
| Dart SDK | Lenguaje y tooling | Incluye analisis, formateo y gestion de paquetes. |
| Visual Studio Code / Android Studio | IDE | Facilitan edicion, debugging, hot reload y manejo de emuladores. |
| PowerShell | Terminal local | Usado en Windows para ejecutar scripts, comandos Flutter y backend Python. |
| Git | Control de versiones | Permite registrar cambios, comparar versiones y colaborar. |
| Android SDK / Gradle | Build Android | Compila APK/AAB y configura permisos, manifest y dependencias nativas. |
| Xcode | Build iOS | Necesario para compilar, firmar y publicar en ecosistema Apple. |
| CMake / Visual Studio Build Tools | Desktop Windows | Requerido si se compila la variante Windows. |

## Servicios Externos

| Servicio | Uso | Justificacion |
| --- | --- | --- |
| Supabase | Auth, PostgreSQL, Storage, Realtime | Reduce complejidad de backend y ofrece servicios integrados. |
| Groq | Modelo de lenguaje | Procesa respuestas del chatbot mediante el backend FastAPI. |
| OneSignal | Notificaciones push | Base para notificaciones push moviles. |
| Firebase Hosting | Hosting web | El proyecto tiene configuracion de hosting para `build/web`. |

## Herramientas del Backend

| Herramienta | Uso | Justificacion |
| --- | --- | --- |
| Python | Lenguaje backend | Sencillo para APIs y servicios de IA. |
| FastAPI | API REST | Framework rapido, tipado y adecuado para servicios JSON. |
| Uvicorn | Servidor ASGI | Ejecuta FastAPI en desarrollo y produccion. |
| httpx | Cliente HTTP | Llama a Groq desde el servidor. |
| python-dotenv | Variables de entorno | Carga configuracion sensible desde `.env`. |

## Herramientas de Calidad

| Herramienta | Uso |
| --- | --- |
| `flutter analyze` | Analisis estatico del codigo Dart. |
| `flutter test` | Ejecucion de pruebas. |
| `build_runner` | Generacion de archivos `.g.dart`. |
| `json_serializable` | Serializacion segura de modelos. |

## Justificacion General

La seleccion prioriza rapidez de desarrollo, soporte multiplataforma y bajo
costo operativo. Supabase concentra gran parte del backend funcional, Flutter
reduce duplicacion entre plataformas y FastAPI permite aislar la IA para no
exponer claves privadas en el cliente.

