# Librerias Seleccionadas

Este documento justifica las librerias principales usadas en ConVive. La lista
se basa en `pubspec.yaml` y sirve como soporte academico para explicar las
decisiones tecnicas del proyecto.

## Dependencias de Produccion

| Libreria | Uso en ConVive | Justificacion |
| --- | --- | --- |
| `flutter` | Framework principal | Permite construir una aplicacion multiplataforma para Android, iOS, web y escritorio desde una sola base de codigo. |
| `flutter_localizations` | Localizacion | Habilita soporte de idiomas y formatos regionales. |
| `cupertino_icons` | Iconografia iOS | Aporta iconos compatibles con componentes estilo Cupertino. |
| `font_awesome_flutter` | Iconografia adicional | Amplia el catalogo visual para botones, estados y pantallas. |
| `provider` | Gestion de estado | Mantiene estado de autenticacion, usuarios, publicaciones, notificaciones, admin y chatbot de forma simple y mantenible. |
| `go_router` | Navegacion | Gestiona rutas declarativas, redirecciones, deep links y rutas protegidas. |
| `supabase_flutter` | Backend principal | Integra autenticacion, base de datos, storage y realtime con Supabase. |
| `http` | Cliente REST | Permite consumir el backend FastAPI y otros endpoints HTTP. |
| `shared_preferences` | Preferencias locales | Guarda configuraciones simples como preferencia de notificaciones o tema. |
| `json_annotation` | Serializacion | Define anotaciones para modelos convertibles a JSON. |
| `uuid` | Identificadores | Genera identificadores cuando se necesitan IDs temporales o locales. |
| `intl` | Formatos | Maneja fechas, numeros y textos localizados. |
| `geolocator` | Ubicacion | Obtiene permisos y coordenadas del dispositivo. |
| `geocoding` | Direcciones | Convierte coordenadas y direcciones cuando se seleccionan ubicaciones. |
| `onesignal_flutter` | Push notifications | Base para integrar notificaciones push en dispositivos moviles. |
| `image_picker` | Imagenes | Permite seleccionar imagenes de perfil y publicaciones. |
| `file_picker` | Archivos PDF | Permite seleccionar documentos de verificacion para publicaciones. |
| `cached_network_image` | Imagenes remotas | Optimiza carga y cache de imagenes desde Supabase Storage. |
| `web` | Compatibilidad web | Facilita integraciones especificas para Flutter Web. |
| `url_launcher` | URLs externas | Abre enlaces, correos o navegadores desde la app. |
| `flutter_map` | Mapas | Renderiza mapas interactivos para publicaciones y ubicacion. |
| `flutter_map_cancellable_tile_provider` | Map tiles | Mejora la carga/cancelacion de tiles en mapas. |
| `latlong2` | Coordenadas | Representa latitud y longitud en `flutter_map`. |
| `google_sign_in` | OAuth Google | Permite autenticacion con cuentas de Google. |
| `app_links` | Deep links | Procesa enlaces de recuperacion, confirmacion y callbacks moviles. |

## Dependencias de Desarrollo

| Libreria | Uso | Justificacion |
| --- | --- | --- |
| `flutter_test` | Pruebas | Framework oficial para tests unitarios y de widgets. |
| `flutter_lints` | Calidad | Reglas recomendadas para mantener estilo y buenas practicas. |
| `build_runner` | Generacion | Ejecuta generadores de codigo Dart. |
| `json_serializable` | Modelos JSON | Genera `fromJson` y `toJson`, reduciendo errores manuales. |

## Relacion con los Modulos

- Autenticacion: `supabase_flutter`, `go_router`, `app_links`, `google_sign_in`.
- Perfil y publicaciones: `image_picker`, `file_picker`, `cached_network_image`.
- Mapas: `flutter_map`, `latlong2`, `geolocator`, `geocoding`.
- Estado: `provider`, `shared_preferences`.
- IA/backend: `http`.
- Calidad: `flutter_lints`, `flutter_test`, `build_runner`.

