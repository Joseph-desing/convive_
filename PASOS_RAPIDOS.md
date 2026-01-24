# ⚡ PASOS RÁPIDOS PARA PROBAR PERFIL

## 1. Configurar Supabase (5 minutos)

### A. Crear proyecto en Supabase
1. Ve a https://supabase.com
2. Crea proyecto: `convive-app`
3. Copia **URL** y **anon key** desde Settings → API

### B. Actualizar credenciales
En `lib/config/app_config.dart`:
```dart
static const String supabaseUrl = 'TU_URL_AQUI';
static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';
```

### C. Crear tablas
1. Abre SQL Editor en Supabase
2. Pega contenido de `SQL_COMPLETO_SUPABASE.sql`
3. Click en **Run**

## 2. Crear usuario de prueba

### En Authentication de Supabase:
1. Click "Add user" → "Create new user"
2. Email: `test@convive.com`
3. Password: `Test123456!`
4. ✅ Marca "Auto Confirm User"
5. **COPIA EL UUID** del usuario creado

## 3. Insertar datos

### En SQL Editor:
1. Abre `SQL_DATOS_PRUEBA.sql`
2. Reemplaza **TODOS** los `TU_USER_ID_DE_SUPABASE_AUTH` con el UUID copiado
3. Pega en SQL Editor
4. Click **Run**

## 4. Ejecutar app

```bash
flutter run
```

## 5. Probar

1. En login:
   - Email: `test@convive.com`
   - Password: `Test123456!`
2. Click pestaña **Perfil** (última)
3. ¡Listo! 🎉

---

## ⚠️ Si no funciona:

Verifica en Supabase Table Editor que existan datos en:
- ✅ `users` → 1 fila
- ✅ `profiles` → 1 fila  
- ✅ `habits` → 1 fila

El `user_id` debe ser el mismo UUID en las 3 tablas.
