# ✅ CHECKLIST DE CONFIGURACIÓN FINAL - ConVive

## 🎯 OBJETIVO
Configurar todo para que el proyecto esté listo para desarrollo

---

## 📋 FASE 1: SUPABASE (15 minutos)

- [ ] **1.1** Ir a https://supabase.com
- [ ] **1.2** Crear nuevo proyecto
  - [ ] Nombre: ConVive
  - [ ] Base de datos password (fuerte)
  - [ ] Región: Sudamérica/Latinoamérica
- [ ] **1.3** Esperar a que se provisione (2-3 minutos)
- [ ] **1.4** Copiar credenciales:
  - [ ] URL del proyecto (Configuración → API → Project URL)
  - [ ] Anon Key (Configuración → API → Anon Key)
  - [ ] Guardar en lugar seguro

---

## 📋 FASE 2: FLUTTER - Configurar Credenciales (5 minutos)

- [ ] **2.1** Abre `lib/config/app_config.dart`
- [ ] **2.2** Reemplaza los valores:
  ```dart
  const String SUPABASE_URL = 'https://xxxxx.supabase.co'; // Tu URL
  const String SUPABASE_ANON_KEY = 'eyJ...'; // Tu Anon Key
  const String AI_SERVICE_URL = 'http://localhost:8000'; // Por ahora localhost
  const String ONE_SIGNAL_APP_ID = 'xxxxx'; // (Opcional por ahora)
  ```
- [ ] **2.3** Guarda el archivo

---

## 📋 FASE 3: CREAR TABLAS EN SUPABASE (10 minutos)

- [ ] **3.1** En Supabase Dashboard → SQL Editor
- [ ] **3.2** Crea nueva query (New Query)
- [ ] **3.3** Copia el contenido completo de `SQL_COMPLETO_SUPABASE.sql`
- [ ] **3.4** Pega en el SQL Editor
- [ ] **3.5** Haz click en "Run" o Ctrl+Enter
- [ ] **3.6** Espera confirmación "Query executed successfully"
- [ ] **3.7** Verifica que las 10 tablas se crearon:
  ```sql
  SELECT table_name FROM information_schema.tables 
  WHERE table_schema = 'public' ORDER BY table_name;
  ```

---

## 📋 FASE 4: CREAR STORAGE BUCKETS (5 minutos)

En Supabase Dashboard → Storage:

- [ ] **4.1** Crear bucket "profiles"
  - [ ] Nombre: `profiles`
  - [ ] Marcar: Public bucket ✅
  - [ ] Crear
  
- [ ] **4.2** Crear bucket "properties"
  - [ ] Nombre: `properties`
  - [ ] Marcar: Public bucket ✅
  - [ ] Crear

---

## 📋 FASE 5: FLUTTER - Build Runner (5 minutos)

- [ ] **5.1** Abre terminal en la carpeta del proyecto
- [ ] **5.2** Ejecuta:
  ```bash
  flutter pub get
  ```
- [ ] **5.3** Luego ejecuta:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- [ ] **5.4** Espera a que termine (debería ver 11 archivos .g.dart generados)
- [ ] **5.5** Si hay errores, ejecuta de nuevo

---

## 📋 FASE 6: VERIFICAR CONEXIÓN (10 minutos)

- [ ] **6.1** Abre terminal en la carpeta del proyecto
- [ ] **6.2** Ejecuta:
  ```bash
  flutter run
  ```
- [ ] **6.3** Selecciona dispositivo/emulador
- [ ] **6.4** Espera a que compile
- [ ] **6.5** La app debería abrir sin errores

---

## 📋 FASE 7: PRUEBA DE AUTENTICACIÓN (10 minutos)

Una vez que la app esté abierta:

- [ ] **7.1** Ir a LoginScreen
- [ ] **7.2** Hacer click en "Registrarse"
- [ ] **7.3** Llenar el formulario:
  - [ ] Email: `test@example.com`
  - [ ] Contraseña: `TestPass123`
  - [ ] Nombre: `Test User`
- [ ] **7.4** Hacer click en "Crear Cuenta"
- [ ] **7.5** Ver si aparece en Supabase → Authentication → Users

### ✅ Si funciona:
- El usuario aparece en Supabase
- Se crean automáticamente Profile y Habits
- Puedes iniciar sesión

### ❌ Si falla:
- Verifica que las credenciales sean correctas
- Revisa la consola de Flutter para errores
- Mira la documentación de debugging

---

## 📋 FASE 8: PYTHON MICROSERVICIO IA (30 minutos)

### Opción A: Setup Local (Recomendado para desarrollo)

- [ ] **8.1** Crear carpeta `microservicio_ia/` en raíz del proyecto
- [ ] **8.2** Abrir PowerShell en esa carpeta
- [ ] **8.3** Crear entorno virtual:
  ```bash
  python -m venv venv
  ```
- [ ] **8.4** Activar:
  ```bash
  .\venv\Scripts\Activate.ps1
  ```
- [ ] **8.5** Crear archivo `requirements.txt` con:
  ```txt
  fastapi==0.104.0
  uvicorn==0.24.0
  python-multipart==0.0.6
  pydantic==2.0.0
  numpy==1.24.0
  pillow==10.0.0
  ```
- [ ] **8.6** Instalar dependencias:
  ```bash
  pip install -r requirements.txt
  ```
- [ ] **8.7** Crear archivo `main.py` (ver EJEMPLOS_DE_USO.dart o PROXIMOS_PASOS.md)
- [ ] **8.8** Ejecutar:
  ```bash
  python main.py
  ```
- [ ] **8.9** Debería ver: "Uvicorn running on http://0.0.0.0:8000"

### Opción B: Docker (Para producción)
- Ver documentación de Docker en PROXIMOS_PASOS.md

---

## 📋 FASE 9: CONFIGURAR MAIN.DART (5 minutos)

- [ ] **9.1** Abre `lib/main.dart`
- [ ] **9.2** Verifica que inicialice los providers:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializar Supabase
    await SupabaseProvider.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    // Inicializar IA Service
    AIServiceProvider.initialize(
      baseUrl: AppConfig.aiServiceUrl,
    );
    
    runApp(const MyApp());
  }
  ```
- [ ] **9.3** Verifica que el MaterialApp tiene MultiProvider:
  ```dart
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MatchingProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
      ],
      child: MaterialApp(
        // ... configuración
      ),
    );
  }
  ```

---

## 📋 FASE 10: ESTRUCTURA FINAL (Verificación)

Verifica que tengas estos archivos:

### Configuración
- [ ] `lib/config/app_config.dart` - Credenciales ✅
- [ ] `lib/config/supabase_provider.dart` - Singleton ✅
- [ ] `lib/config/ai_service_provider.dart` - Singleton ✅

### Modelos (11)
- [ ] `lib/models/user.dart`
- [ ] `lib/models/profile.dart`
- [ ] `lib/models/habits.dart`
- [ ] `lib/models/property.dart`
- [ ] `lib/models/property_image.dart`
- [ ] `lib/models/swipe.dart`
- [ ] `lib/models/match.dart`
- [ ] `lib/models/chat.dart`
- [ ] `lib/models/message.dart`
- [ ] `lib/models/subscription.dart`
- [ ] `lib/models/partner_profile.dart`

### Servicios (5)
- [ ] `lib/services/supabase_auth_service.dart`
- [ ] `lib/services/supabase_database_service.dart`
- [ ] `lib/services/supabase_realtime_service.dart`
- [ ] `lib/services/supabase_storage_service.dart`
- [ ] `lib/services/ai_service.dart`

### Proveedores (4)
- [ ] `lib/providers/auth_provider.dart`
- [ ] `lib/providers/user_provider.dart`
- [ ] `lib/providers/matching_provider.dart`
- [ ] `lib/providers/property_provider.dart`

### Constantes y Utilities
- [ ] `lib/constants/app_strings.dart`
- [ ] `lib/constants/app_dimensions.dart`
- [ ] `lib/utils/app_utils.dart`
- [ ] `lib/utils/colors.dart`
- [ ] `lib/exceptions/app_exceptions.dart`

### Screens (Listos para actualizar)
- [ ] `lib/screens/home_screen.dart`
- [ ] `lib/screens/login_screen.dart`
- [ ] `lib/screens/splash_screen.dart`
- [ ] `lib/screens/welcome_screen.dart`

### Documentación
- [ ] `README.md`
- [ ] `ARQUITECTURA_IMPLEMENTADA.md`
- [ ] `PROXIMOS_PASOS.md`
- [ ] `GUIA_RAPIDA.md`
- [ ] `DEBUGGING.md`
- [ ] `CREAR_TABLAS_SUPABASE.md`
- [ ] `SQL_COMPLETO_SUPABASE.sql`
- [ ] `EJEMPLOS_DE_USO.dart`

---

## 🎯 PRUEBAS FINALES

### Test 1: Compilación
- [ ] `flutter pub get` sin errores ✅
- [ ] `flutter pub run build_runner build` sin errores ✅
- [ ] `flutter run` compila sin errores ✅

### Test 2: Autenticación
- [ ] Puedo registrarme ✅
- [ ] Puedo iniciar sesión ✅
- [ ] Los datos se guardan en Supabase ✅

### Test 3: UI Responsiva
- [ ] Pantallas se ven bien en mobile ✅
- [ ] Gradientes se ven correctos ✅
- [ ] Botones funcionan ✅

### Test 4: Performance
- [ ] La app no se congela ✅
- [ ] Las imágenes cargan rápido ✅
- [ ] No hay memory leaks ✅

---

## 📊 MATRIZ DE COMPLETITUD

| Componente | Estado |
|-----------|--------|
| Supabase creado | ✅ |
| Tablas creadas | ✅ |
| Buckets creados | ✅ |
| Credenciales configuradas | ✅ |
| Build runner ejecutado | ✅ |
| Providers inicializados | ✅ |
| Auth funcionando | ✅ |
| Microservicio IA | ✅ |
| Screens actualizadas | 📝 (Próximo) |
| Chat en tiempo real | 📝 (Próximo) |

---

## 🚀 PRÓXIMOS PASOS (En Orden)

### Semana 1:
1. ✅ Completar todas las fases 1-10 de este checklist
2. 📝 Actualizar HomeScreen para usar PropertyProvider
3. 📝 Actualizar LoginScreen para usar AuthProvider

### Semana 2:
4. 📝 Crear ProfileScreen con UserProvider
5. 📝 Crear MatchingScreen con swiping
6. 📝 Implementar ChatScreen con RealtimeService

### Semana 3:
7. 📝 Agregar filtering y búsqueda
8. 📝 Agregar OneSignal para notificaciones
9. 📝 Testing completo

### Semana 4:
10. 📝 Build release (APK/IPA)
11. 📝 Deploy a PlayStore/AppStore

---

## ⚠️ NOTAS IMPORTANTES

### Credenciales
```
❌ NUNCA compartas el SUPABASE_ANON_KEY
❌ NUNCA lo subas a GitHub público
✅ Úsalo solo en desarrollo
✅ Para producción usa environment variables
```

### Datos de Prueba
- Email: `test@example.com`
- Contraseña: `TestPass123!`
- (Cambiar antes de producción)

### Problemas Comunes
Ver `DEBUGGING.md` para troubleshooting

---

## 📞 SOPORTE RÁPIDO

| Error | Solución |
|-------|----------|
| "No se encuentra supabase" | Ejecuta `flutter pub get` |
| "xxx.g.dart no existe" | Ejecuta `flutter pub run build_runner build` |
| "Conexión rechazada" | Verifica URL y Anon Key |
| "RLS policy violation" | Debes estar autenticado |
| "Bucket no existe" | Crea buckets en Storage |

---

## ✅ DONE!

Si completaste todos los checks:

✅ Supabase está listo
✅ Flutter está configurado
✅ Tablas están creadas
✅ Servicios están conectados
✅ Providers están inicializados
✅ Listo para desarrollo

**¡Ahora puedes empezar a construir! 🚀**

---

**Tiempo total**: 1-1.5 horas
**Dificultad**: Media (es configuración, no desarrollo)
**Resultado**: Arquitectura profesional lista para producción
