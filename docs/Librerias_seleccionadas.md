# Principales librerías seleccionadas para la construcción de la aplicación móvil

La siguiente tabla lista las librerías incluidas en el proyecto (`pubspec.yaml`) y una breve justificación de su uso.

| LIBRERÍA | DESCRIPCIÓN / JUSTIFICACIÓN |
|---|---|
| `flutter_localizations` | Soporte para internacionalización (traducciones y formatos locales) en Flutter. |
| `cupertino_icons` | Iconos estilo iOS para widgets Cupertino. |
| `font_awesome_flutter` | Colección de iconos Font Awesome para enriquecer la interfaz. |
| `provider` | Gestión de estado ligera y recomendada para patrones MVVM/Provider en Flutter. |
| `go_router` | Gestión de rutas y navegación declarativa, con soporte para deep linking. |
| `supabase_flutter` | Cliente para Supabase: autenticación, bases de datos y storage como BaaS. |
| `http` | Cliente HTTP básico para llamadas REST/API. |
| `shared_preferences` | Almacenamiento local ligero para preferencias y tokens simples. |
| `json_annotation` | Anotaciones necesarias para la serialización de modelos (usado con `json_serializable`). |
| `uuid` | Generación de identificadores únicos (IDs temporales, keys). |
| `intl` | Formateo de fechas, números y mensajes localizados. |
| `geolocator` | Acceso a geolocalización (latitud/longitud, permisos, servicios de ubicación). |
| `onesignal_flutter` | Integración con OneSignal para notificaciones push. |
| `image_picker` | Selección de imágenes desde cámara o galería. |
| `cached_network_image` | Cache y carga eficiente de imágenes remotas. |
| `url_launcher` | Abrir URLs externas (navegador, llamadas, email) desde la app. |
| `flutter_map` | Visualización de mapas (basado en Leaflet). |
| `latlong2` | Tipos y utilidades para coordenadas geográficas, usado con `flutter_map`. |
| `flutter_map_marker_cluster` | Agrupado (clustering) de marcadores en `flutter_map` (ver compatibilidades con versión 7). |
| `google_sign_in` | Inicio de sesión con cuenta Google (OAuth). |

**Dev dependencies**

| LIBRERÍA | DESCRIPCIÓN / JUSTIFICACIÓN |
|---|---|
| `build_runner` | Motor de generación de código para Dart (ejecuta generadores como json_serializable). |
| `json_serializable` | Generador para convertir modelos Dart a JSON y viceversa (reduce boilerplate). |
| `flutter_lints` | Conjunto de reglas de lint recomendadas para proyectos Flutter. |
| `flutter_test` | Framework de testing proporcionado por Flutter para pruebas unitarias y widget tests. |

**Referencia:** ver la lista completa en [pubspec.yaml](pubspec.yaml)

---

¿Quieres que inserte esta sección en el `README.md` o que exporte el documento a PDF/Word? 
