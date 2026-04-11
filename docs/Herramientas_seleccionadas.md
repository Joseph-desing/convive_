# Herramientas seleccionadas para la construcción de la aplicación móvil

Esta tabla resume las principales herramientas y servicios usados en el proyecto, con una breve justificación para cada una.

| HERRAMIENTA | JUSTIFICACIÓN |
|---|---|
| Windows PowerShell | Facilita la ejecución de scripts, instalación de dependencias y configuración de variables de entorno en sistemas Windows; útil para automatizar el flujo de trabajo de desarrollo. |
| Flutter CLI (flutter) | Herramienta principal para compilar, ejecutar, depurar y generar builds (Android, iOS, web, desktop). Permite hot reload y gestión de paquetes. |
| Dart SDK (dart) | Proporciona el lenguaje, el gestor de paquetes (`dart pub`) y utilidades de análisis/formatting necesarias para el desarrollo. |
| Android SDK / Gradle | Compila y empaqueta la app para Android; el repositorio usa `build.gradle.kts` (Kotlin DSL) para la configuración de Gradle. |
| Xcode | Requerido para compilar, firmar y publicar builds para iOS y macOS. |
| Visual Studio / CMake (Windows) | Necesarios para construir la variante de escritorio en Windows (soporte nativo). |
| Git / GitHub (incluye GitHub Copilot) | Control de versiones y colaboración; GitHub Copilot ofrece sugerencias de código asistidas por IA que aceleran la implementación. |
| OneSignal (onesignal_flutter) | Servicio de notificaciones push utilizado por la app para enviar mensajes en tiempo real y gestionar suscripciones. |
| Supabase (supabase_flutter) | Backend-as-a-Service para autenticación, base de datos y storage; simplifica la integración backend sin gestionar infraestructura propia. |
| build_runner / json_serializable | Herramientas de generación de código (Dart) usadas para crear modelos y serializadores automáticamente. |
| Android Studio / Visual Studio Code | IDEs recomendados con plugins Flutter/Dart para desarrollo, debugging y profiling. |
| Node.js (opcional) | Útil para herramientas auxiliares, scripts, integraciones de CI/CD o web tooling en proyectos que lo requieran. |

**Referencia:** configuración y dependencias en [pubspec.yaml](pubspec.yaml)

---

¿Quieres que exporte esta tabla a PDF/Word o que la incluya en el README del repositorio? 
