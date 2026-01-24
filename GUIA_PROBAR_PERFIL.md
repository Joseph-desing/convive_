# 🚀 GUÍA DE CONEXIÓN CON SUPABASE - ConVive

## 📋 Pasos para Probar la Pantalla de Perfil con Supabase

### 1️⃣ Crear Cuenta en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Crea una cuenta gratuita
3. Crea un nuevo proyecto
   - Nombre: `convive-app`
   - Región: Elige la más cercana a ti
   - Password: Guarda esta contraseña de manera segura

### 2️⃣ Obtener Credenciales de Supabase

1. Ve a **Settings** → **API** en tu proyecto
2. Copia los siguientes valores:
   - **Project URL** (URL del proyecto)
   - **anon public** key (API Key pública)

### 3️⃣ Configurar Credenciales en la App

1. Abre el archivo `lib/config/app_config.dart`
2. Reemplaza las credenciales:

```dart
class AppConfig {
  // Reemplazar con tu URL de Supabase
  static const String supabaseUrl = 'https://TU_PROYECTO.supabase.co';
  
  // Reemplazar con tu Anon Key de Supabase
  static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';
  
  // ... resto del código
}
```

### 4️⃣ Crear las Tablas en Supabase

1. Ve a **SQL Editor** en Supabase
2. Abre el archivo `SQL_COMPLETO_SUPABASE.sql` de tu proyecto
3. Copia todo el contenido
4. Pégalo en el SQL Editor
5. Haz click en **Run** (▶️)
6. Verifica que aparezca "Success" en verde

### 5️⃣ Crear Usuario de Prueba

1. Ve a **Authentication** en Supabase
2. Haz click en **Add user** → **Create new user**
3. Ingresa:
   - **Email**: `test@convive.com`
   - **Password**: `Test123456!`
   - ✅ Marca "Auto Confirm User"
4. Haz click en **Create user**
5. **IMPORTANTE**: Copia el **UUID** del usuario que aparece en la columna ID

### 6️⃣ Insertar Datos de Prueba

1. Abre el archivo `SQL_DATOS_PRUEBA.sql`
2. **REEMPLAZA** todas las ocurrencias de `TU_USER_ID_DE_SUPABASE_AUTH` con el UUID que copiaste
3. Ve a **SQL Editor** en Supabase
4. Pega el SQL modificado
5. Haz click en **Run** (▶️)

### 7️⃣ Verificar Datos en Supabase

1. Ve a **Table Editor** en Supabase
2. Verifica que existan datos en las siguientes tablas:
   - ✅ `users` - 1 fila
   - ✅ `profiles` - 1 fila
   - ✅ `habits` - 1 fila

### 8️⃣ Probar en la App

#### Opción A: Usar Datos de Ejemplo (Sin conexión)

En `lib/screens/home_screen.dart`, línea ~356:

```dart
return const ProfileScreen(useExampleData: true); // Datos de ejemplo
```

#### Opción B: Conectar con Supabase (Datos reales)

En `lib/screens/home_screen.dart`, línea ~356:

```dart
return const ProfileScreen(useExampleData: false); // Datos de Supabase
```

### 9️⃣ Ejecutar la App

```bash
flutter run
```

### 🔟 Iniciar Sesión

1. Abre la app
2. Ve a la pantalla de login
3. Ingresa las credenciales:
   - **Email**: `test@convive.com`
   - **Password**: `Test123456!`
4. Navega a la pestaña **Perfil**
5. ¡Deberías ver tu perfil completo! 🎉

---

## 🐛 Solución de Problemas

### Error: "No hay usuario autenticado"

**Solución**: Asegúrate de iniciar sesión primero con las credenciales de prueba.

### Error: "Failed to load profile"

**Verificar**:
1. ¿Las credenciales de Supabase están correctas en `app_config.dart`?
2. ¿Las tablas se crearon correctamente?
3. ¿El `user_id` en las tablas coincide con el ID del usuario en Authentication?

### Error: "Invalid JSON"

**Solución**: Verifica que los datos en las tablas tengan el formato correcto:
- `sleep_start` y `sleep_end` deben ser TEXT (ej: '23:00')
- Los niveles deben ser INTEGER entre 1-10
- `work_mode` debe ser 'remote', 'presencial' o 'hibrido'

### Verificar User ID

```sql
-- En SQL Editor de Supabase
SELECT auth.uid(); -- Este es tu user_id actual (cuando estés logueado)

-- Verificar que coincida con la tabla users
SELECT * FROM users WHERE id = 'EL_ID_QUE_COPIASTE';
```

---

## 📊 Estructura de Datos

### Tabla: users
```sql
id              | UUID    | ID del usuario (mismo que auth.users)
email           | TEXT    | test@convive.com
role            | TEXT    | student / non_student / admin
subscription_type | TEXT  | free / premium
```

### Tabla: profiles
```sql
id              | UUID    | ID autogenerado
user_id         | UUID    | ID del usuario (FK a users)
full_name       | TEXT    | Ana María García
birth_date      | DATE    | 2000-05-15
gender          | TEXT    | male / female / other
bio             | TEXT    | Descripción del usuario
profile_image_url | TEXT  | URL de la imagen
verified        | BOOLEAN | true / false
```

### Tabla: habits
```sql
user_id         | UUID    | ID del usuario
sleep_start     | TEXT    | 23:00
sleep_end       | TEXT    | 07:00
cleanliness_level | INT   | 1-10
noise_tolerance | INT     | 1-10
party_frequency | INT     | 0-7 (días por semana)
work_mode       | TEXT    | remote / presencial / hibrido
... más campos
```

---

## 🎯 Cambiar entre Datos de Ejemplo y Datos Reales

### En `lib/screens/home_screen.dart`:

```dart
// DATOS DE EJEMPLO (no requiere Supabase)
return const ProfileScreen(useExampleData: true);

// DATOS REALES DE SUPABASE (requiere autenticación)
return const ProfileScreen(useExampleData: false);
```

---

## ✅ Checklist de Configuración

- [ ] Proyecto creado en Supabase
- [ ] Credenciales copiadas a `app_config.dart`
- [ ] Tablas creadas con `SQL_COMPLETO_SUPABASE.sql`
- [ ] Usuario de prueba creado en Authentication
- [ ] User ID copiado
- [ ] Datos de prueba insertados con `SQL_DATOS_PRUEBA.sql`
- [ ] Datos verificados en Table Editor
- [ ] App ejecutada con `flutter run`
- [ ] Login exitoso
- [ ] Perfil visible en la app

---

## 🔄 Próximos Pasos

Una vez que la pantalla de perfil funcione:

1. **Editar Perfil**: Crear pantalla para actualizar datos
2. **Subir Foto**: Implementar carga de imagen al Storage
3. **Editar Hábitos**: Crear formulario para modificar hábitos
4. **Verificación**: Implementar proceso de verificación de perfil
5. **Configuración**: Añadir más opciones de configuración

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs en la terminal donde ejecutas `flutter run`
2. Verifica los logs en Supabase Dashboard → Logs
3. Asegúrate de que las políticas RLS estén deshabilitadas para pruebas
4. Comprueba que el formato de datos sea correcto

---

## 🎨 Personalización

### Cambiar Foto de Perfil

En `SQL_DATOS_PRUEBA.sql`, modifica:

```sql
profile_image_url = 'TU_URL_DE_IMAGEN_AQUI'
```

### Cambiar Datos del Perfil

Modifica directamente en Table Editor o actualiza el SQL.

---

¡Listo! Ahora tu pantalla de perfil está conectada con Supabase y lista para mostrar datos reales. 🚀
