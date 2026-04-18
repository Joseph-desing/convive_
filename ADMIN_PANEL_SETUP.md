# 🔧 GUÍA DE CONFIGURACIÓN - PANEL DE ADMINISTRADOR

## 📋 Descripción General

Se ha implementado un **Panel de Administrador completo** para ConVive con las siguientes funcionalidades:

✅ **Gestión de Usuarios** - Editar roles, suspender/activar usuarios
✅ **Gestión de Departamentos** - Activar, desactivar, eliminar propiedades
✅ **Gestión de Quejas/Sugerencias** - Responder a feedback, cambiar estados

---

## 🚀 PASOS DE INSTALACIÓN

### 1️⃣ Generar archivos .g.dart (JSON Serialization)

El modelo `Feedback` necesita ser generado por `build_runner`:

```bash
# En la raíz del proyecto
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Archivo generado:**
```
lib/models/feedback.g.dart
```

---

### 2️⃣ Crear tabla en Supabase

Accede a tu dashboard de Supabase y ejecuta el siguiente SQL:

```sql
-- Tabla de Feedback/Quejas/Sugerencias
CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('complaint', 'suggestion', 'bug_report')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_review', 'resolved', 'closed')),
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT,
  attachment_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  admin_response TEXT,
  admin_response_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  
  CONSTRAINT feedback_pkey PRIMARY KEY (id),
  CONSTRAINT feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Índices para mejor performance
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON public.feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON public.feedback(status);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON public.feedback(type);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON public.feedback(created_at DESC);

-- Row Level Security (RLS)
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios pueden ver sus propios feedback
CREATE POLICY feedback_user_view ON public.feedback
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Los usuarios pueden crear feedback
CREATE POLICY feedback_user_create ON public.feedback
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Los admins pueden hacer todo
CREATE POLICY feedback_admin_all ON public.feedback
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );
```

---

### 3️⃣ Dar permisos de acceso a tabla de usuarios

El AdminService necesita acceder a la tabla `users`. Verifica que el RLS esté configurado:

```sql
-- Permitir a admins consultar todos los usuarios
CREATE POLICY users_admin_view ON public.users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

-- Permitir a admins actualizar usuarios
CREATE POLICY users_admin_update ON public.users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );
```

---

### 4️⃣ Actualizar tabla de usuarios (si no existe el campo is_suspended)

```sql
-- Agregar campo is_suspended si no existe
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT FALSE;
```

---

### 5️⃣ Asignar rol de Admin a un usuario

Para probar el panel, asigna el rol `admin` a un usuario:

```sql
UPDATE public.users
SET role = 'admin'
WHERE email = 'tu_email@ejemplo.com';
```

---

## 📂 ARCHIVOS CREADOS

### Modelos
- **lib/models/feedback.dart** - Modelo de feedback con tipos (complaint, suggestion, bug_report)

### Servicios
- **lib/services/admin_service.dart** - Servicio para CRUD de admin (usuarios, propiedades, feedback)

### Providers
- **lib/providers/admin_provider.dart** - State management para admin

### Pantallas
- **lib/screens/admin_dashboard.dart** - Dashboard principal
- **lib/screens/admin_users_screen.dart** - Gestión de usuarios
- **lib/screens/admin_properties_screen.dart** - Gestión de departamentos
- **lib/screens/admin_feedback_screen.dart** - Gestión de quejas/sugerencias

### Configuración
- **lib/main.dart** - Rutas y providers actualizados

---

## 🔐 RUTAS DE ACCESO

| Ruta | Descripción | Requiere |
|------|-------------|----------|
| `/admin` | Dashboard de administrador | Sesión + Rol Admin |
| `/admin/users` | Gestión de usuarios | Sesión + Rol Admin |
| `/admin/properties` | Gestión de departamentos | Sesión + Rol Admin |
| `/admin/feedback` | Gestión de quejas | Sesión + Rol Admin |

---

## 🎯 CARACTERÍSTICAS IMPLEMENTADAS

### Dashboard de Administrador
- Estadísticas generales (usuarios, departamentos, feedback)
- Acceso rápido a módulos de gestión
- Información del administrador logueado

### Gestión de Usuarios
- Listar todos los usuarios
- Filtrar por rol (estudiante, no estudiante, admin)
- Buscar por email o nombre
- Cambiar rol de usuarios
- Suspender/Activar usuarios

### Gestión de Departamentos
- Listar todas las propiedades
- Filtrar por estado (activo, inactivo, pendiente)
- Buscar por título o descripción
- Activar/Desactivar propiedades
- Eliminar propiedades

### Gestión de Quejas/Sugerencias
- Listar todos los feedbacks
- Filtrar por estado (abierto, en revisión, resuelto, cerrado)
- Filtrar por tipo (queja, sugerencia, reporte de bug)
- Buscar por asunto o mensaje
- **Responder a feedbacks**
- Cambiar estado de feedback
- Cerrar tickets

---

## 📱 CÓMO ACCEDER

1. **Asegúrate de ser ADMIN**
   ```sql
   UPDATE public.users SET role = 'admin' WHERE email = 'tu@email.com';
   ```

2. **Inicia sesión en la app**

3. **Navega a**: `/admin`
   
   O agregadeun botón en el perfil para acceder al panel.

---

## 🔍 ESTRUCTURA DE DATOS - FEEDBACK

```dart
Feedback {
  String id;                    // UUID único
  String userId;                // Quién envía el feedback
  FeedbackType type;             // complaint | suggestion | bug_report
  FeedbackStatus status;         // open | in_review | resolved | closed
  String subject;               // Título
  String message;               // Descripción
  String? category;             // Categoría opcional
  String? attachmentUrl;        // URL de archivo adjunto
  DateTime createdAt;           // Fecha de creación
  DateTime? updatedAt;          // Última actualización
  String? adminResponse;        // Respuesta del admin
  DateTime? adminResponseAt;    // Cuándo respondió
  String? resolvedBy;           // ID del admin que resolvió
}
```

---

## ⚙️ VARIABLES DE ESTADO (AdminProvider)

```dart
// Datos
List<Map<String, dynamic>> allUsers;
List<Map<String, dynamic>> allProperties;
List<Feedback> allFeedback;
Map<String, dynamic> dashboardStats;

// Estados
bool isLoading;
String? errorMessage;

// Filtros
String selectedUserFilter;      // all | student | non_student | admin
String selectedPropertyFilter;  // all | active | inactive | pending
String selectedFeedbackFilter;  // all | open | in_review | resolved | closed
```

---

## 🚨 PRÓXIMOS PASOS

### Opcionales (Mejoras)
- [ ] Agregar paginación en listas
- [ ] Implementar búsqueda avanzada con filtros
- [ ] Agregar exportación de reportes (CSV/PDF)
- [ ] Implementar logs de auditoría
- [ ] Agregar sistema de notificaciones para nuevos feedbacks
- [ ] Dashboard con gráficos de estadísticas
- [ ] Sistema de permisos granulares (roles adicionales)

### Configuración de Acceso
- [ ] Agregar botón "Panel de Admin" en menú de usuario
- [ ] Crear ruta protegida con verificación de rol
- [ ] Agregar logs de quién accede al panel

---

## 📞 SOPORTE

Si tienes problemas:

1. **Verifica que el usuario sea ADMIN:**
   ```sql
   SELECT id, email, role FROM public.users WHERE role = 'admin';
   ```

2. **Verifica que la tabla feedback exista:**
   ```sql
   SELECT * FROM public.feedback LIMIT 1;
   ```

3. **Ejecuta build_runner si hay errores de serialización:**
   ```bash
   flutter pub run build_runner clean
   flutter pub run build_runner build
   ```

4. **Revisa los logs en consola** para mensajes de error específicos

---

## 📄 NOTAS IMPORTANTES

- El campo `is_suspended` en tabla `users` es opcional pero recomendado
- Las políticas de RLS deben permitir a admins acceder a todas las tablas
- El `AdminProvider` usa Singleton pattern con Supabase
- Todas las acciones se reflejan en tiempo real gracias a `notifyListeners()`
- Los feedbacks se guardan con timezone UTC en Supabase

---

**¡Listo! El panel de administrador está completamente configurado y listo para usar.**
