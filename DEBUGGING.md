# 🐛 GUÍA DE DEBUGGING - ConVive

## 🔴 Errores Comunes y Soluciones

### 1. Error: "xxx.g.dart no encontrado"

**Síntoma:**
```
Error: The file 'lib/models/user.g.dart' does not exist.
```

**Causa:** No se ejecutó `build_runner` después de cambiar modelos

**Solución:**
```bash
# Opción 1: Build de una sola vez
flutter pub run build_runner build --delete-conflicting-outputs

# Opción 2: Watch mode (auto-rebuild al editar)
flutter pub run build_runner watch

# Limpia cache si persiste error
rm -r .dart_tool/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2. Error: "SupabaseProvider no inicializado"

**Síntoma:**
```
MissingPluginException: No implementation found for method getDefaultStorage
```

**Causa:** No se llamó `SupabaseProvider.initialize()` en main()

**Solución:** En `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ AGREGADO
  await SupabaseProvider.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}
```

---

### 3. Error: "FirebaseException: Could not reach Cloud Firestore backend"

**Síntoma:**
```
E/flutter: PlatformException(Error 500, )
```

**Causa:** Credenciales de Supabase inválidas o red desconectada

**Solución:**
```dart
// En app_config.dart, verifica:
const String SUPABASE_URL = 'https://tuproyecto.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJ...'; // Copiado correcto de Supabase

// Prueba conexión:
Future<void> testConnection() async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .limit(1);
    print('✅ Conexión OK: $response');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

### 4. Error: "Provider<AuthProvider> not found"

**Síntoma:**
```
Error: Could not find the correct Provider<AuthProvider> above this Widget
```

**Causa:** Widget está fuera del scope de MultiProvider

**Solución:**
```dart
// En main.dart, verifica que el widget esté dentro de MultiProvider:
MaterialApp(
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      // ...
    ],
    child: MyApp(), // ✅ AppBar y screens aquí
  ),
)
```

---

### 5. Error: "Invalid Supabase URL or key"

**Síntoma:**
```
Exception: Invalid Supabase URL or key
```

**Causa:** URL o key vacía, malformada o copiada mal

**Solución:**
```dart
// Verifica en Supabase Dashboard:
// 1. Settings → API
// 2. URL: https://xxxxx.supabase.co (exactamente)
// 3. Anon Key: eyJ... (todo el token)

// En app_config.dart:
const String SUPABASE_URL = 'https://xxxxx.supabase.co'; // Sin trailing slash
const String SUPABASE_ANON_KEY = 'eyJ...'; // Todo el token

print('URL: $SUPABASE_URL');
print('Key: $SUPABASE_ANON_KEY');
```

---

### 6. Error: "toJson() method not found"

**Síntoma:**
```
NoSuchMethodError: The method 'toJson' was called on null.
```

**Causa:** .g.dart no generado o User.fromJson() recibió null

**Solución:**
```dart
// En main.dart, asegura que fromJson handle null:
class User {
  static User? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return _$UserFromJson(json); // Generado por build_runner
  }
}

// Alternativa: mapeo defensivo en servicios
try {
  final json = response.data as Map<String, dynamic>?;
  return json != null ? User.fromJson(json) : null;
} catch (e) {
  print('Error parseando User: $e');
  rethrow;
}
```

---

### 7. Error: "Bad state: Cannot add new events after calling close"

**Síntoma:**
```
Bad state: Cannot add new events after calling close
```

**Causa:** RealtimeService stream cerrado antes de usarlo

**Solución:**
```dart
// En supabase_realtime_service.dart, verifica ciclo de vida:
class SupabaseRealtimeService {
  StreamSubscription? _subscription;

  void subscribeToMessages(String chatId) {
    _subscription?.cancel(); // ✅ Cancela subscription anterior
    
    _subscription = Supabase.instance.client
        .from('messages')
        .on(RealtimeListenTypes.postgresChanges,
            ...)
        .listen(...);
  }

  void dispose() {
    _subscription?.cancel(); // ✅ Limpia al destruir
  }
}
```

---

### 8. Error: "404 Not Found" desde AI Service

**Síntoma:**
```
http.ClientException: Not Found (404)
```

**Causa:** URL del microservicio IA incorrecta o servicio no corriendo

**Solución:**
```bash
# 1. Verifica que el servicio esté corriendo:
python main.py
# Debería mostrar: Uvicorn running on http://0.0.0.0:8000

# 2. Prueba manualmente:
curl http://localhost:8000/health

# 3. En app_config.dart:
const String AI_SERVICE_URL = 'http://localhost:8000'; // Desarrollo
// const String AI_SERVICE_URL = 'http://192.168.x.x:8000'; // Desde otro dispositivo
// const String AI_SERVICE_URL = 'https://api.example.com'; // Producción

# 4. En emulador Android, usa:
const String AI_SERVICE_URL = 'http://10.0.2.2:8000'; // Acceso a localhost desde emulador
```

---

### 9. Error: "Image loading fails"

**Síntoma:**
```
The image type 'NetworkImage' has been deprecated in favor of 'Image.network'.
```

**Causa:** URL de imagen nula o formato incorrecto

**Solución:**
```dart
// En property_card.dart o similar:
Image.network(
  property.images.isNotEmpty ? property.images.first.imageUrl : '',
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.broken_image),
    );
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(child: CircularProgressIndicator());
  },
)
```

---

### 10. Error: "JSON Parse Error"

**Síntoma:**
```
FormatException: Unexpected character (at character 1)
```

**Causa:** Response no es JSON válido o encoding incorrecto

**Solución:**
```dart
// En ai_service.dart:
Future<double> calculateCompatibilityScore(HabitsData a, HabitsData b) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/compatibility-score'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_a_habits': a.toJson(),
        'user_b_habits': b.toJson(),
      }),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}'); // ✅ Debug el response crudo

    if (response.statusCode != 200) {
      throw AIException.fromResponse(response.statusCode);
    }

    final json = jsonDecode(response.body);
    return (json as Map<String, dynamic>)['score'] as double;
  } catch (e) {
    print('Error detallado: $e');
    rethrow;
  }
}
```

---

### 11. Error: "RLS policy violation"

**Síntoma:**
```
PostgrestException: new row violates row-level security policy
```

**Causa:** RLS policy no permite la operación para el usuario

**Solución:**
```sql
-- En Supabase SQL Editor, verifica las políticas:
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Ejemplo de política correcta:
CREATE POLICY "Users can read own data"
ON public.profiles
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own data"
ON public.profiles
FOR UPDATE
USING (auth.uid() = user_id);

-- Para desarrollo (SIN SEGURIDAD):
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```

---

### 12. Error: "Null safety issues"

**Síntoma:**
```
The argument type 'String?' can't be assigned to the parameter type 'String'
```

**Causa:** Variable nullable usada donde se espera non-nullable

**Solución:**
```dart
// ❌ Incorrecto
void setName(String name) {
  final user = User(name: name); // ¿Qué si name es null?
}

// ✅ Correcto - Opción 1: Validar
void setName(String? name) {
  if (name == null || name.isEmpty) {
    throw ValidationException('Name cannot be empty');
  }
  final user = User(name: name);
}

// ✅ Correcto - Opción 2: Default value
void setName(String? name) {
  final user = User(name: name ?? 'Unknown');
}

// ✅ Correcto - Opción 3: Early return
void setName(String? name) {
  if (name == null) return;
  final user = User(name: name);
}
```

---

## 🟡 Warnings Comunes

### Warning: "The parameter 'onPressed' is required"

**Solución:**
```dart
// ✅ Siempre proporciona onPressed
ElevatedButton(
  onPressed: () {
    Provider.of<AuthProvider>(context, listen: false).signIn();
  },
  child: Text('Login'),
)
```

---

### Warning: "The argument type 'Widget' can't be assigned to 'Widget Function()'"

**Solución:**
```dart
// ❌ Incorrecto - Widget como parámetro
Consumer<UserProvider>(
  builder: (context, provider, child) {
    return Center(child: Text(provider.name)); // ✅ Correcto
  },
)
```

---

## 🟢 Debugging Tools

### 1. Print Debugging
```dart
// ✅ Agrega prints estratégicos
print('🟢 User cargado: ${user.id}');
print('🔴 Error: $e');
print('🟡 Loading...');
print('📊 Data: ${jsonEncode(data)}');
```

### 2. DevTools
```bash
# Abre DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Luego en Terminal:
flutter run
# Abre navegador: http://localhost:9100
```

### 3. Logging estructurado
```dart
import 'dart:developer' as developer;

void logEvent(String message, {required String level}) {
  developer.log(
    message,
    level: level == 'error' ? 1000 : 0,
    name: 'ConVive',
  );
}

// Uso:
logEvent('User authenticated', level: 'info');
logEvent('Network error', level: 'error');
```

### 4. Network Inspection
```dart
// En main.dart, agrega logger de HTTP:
import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner;

  LoggingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('➡️  ${request.method} ${request.url}');
    final response = await _inner.send(request);
    print('⬅️  ${response.statusCode}');
    return response;
  }
}
```

### 5. State Inspector
```dart
// En main.dart, visualiza estado actual:
@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        print('🔐 AuthState: ${auth.currentUser?.email}');
        print('📊 IsLoading: ${auth.isLoading}');
        print('⚠️  Error: ${auth.error}');
      },
      child: Icon(Icons.bug_report),
    ),
  );
}
```

---

## 🔍 Checklist de Debugging

Cuando algo no funciona, verifica en orden:

- [ ] ¿Se ejecutó `flutter pub get`?
- [ ] ¿Se ejecutó `build_runner build`?
- [ ] ¿Supabase está inicializado en main()?
- [ ] ¿Las credenciales son correctas?
- [ ] ¿El widget está dentro de MultiProvider?
- [ ] ¿Los providers están registrados?
- [ ] ¿El servicio está respondiendo?
- [ ] ¿Hay errores de null safety?
- [ ] ¿La tabla existe en BD?
- [ ] ¿La RLS policy permite la acción?
- [ ] ¿El emulador tiene conexión a internet?
- [ ] ¿Los paths de imports son correctos?

---

## 📱 Debugging en Emulador Android

```bash
# Ver logs en tiempo real
adb logcat | grep flutter

# Tomar screenshot
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./

# Acceder a localhost desde emulador
# En emulador: http://10.0.2.2:8000
# En dispositivo real: http://192.168.x.x:8000
```

---

## 📞 Cómo Pedir Ayuda

Cuando reportes un bug, proporciona:

1. **Stack trace completo**
   ```
   flutter run -v > debug.log 2>&1
   ```

2. **Output de build_runner**
   ```
   flutter pub run build_runner build --verbose
   ```

3. **Credenciales (sin exponer**))
   ```
   Supabase URL: https://xxxxx.supabase.co
   AI Service: http://localhost:8000
   Status: ✅ conectando / ❌ error
   ```

4. **Versiones**
   ```
   Flutter version: flutter --version
   Dart version: dart --version
   Pub packages: flutter pub deps
   ```

5. **Pasos para reproducir**
   ```
   1. Ejecuta flutter run
   2. Tap en...
   3. Ver error en console
   ```

---

**¡Recuerda: Los errores son lecciones, no enemigos! 🚀**
