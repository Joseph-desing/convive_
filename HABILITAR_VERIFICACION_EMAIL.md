# 🔒 Habilitar Verificación de Email en Supabase

## ✅ Cambios Realizados en la App

Ya hemos implementado en el código:

1. ✅ **Nueva pantalla de verificación** (`EmailVerificationScreen`)
   - Muestra instrucciones claras al usuario
   - Verifica automáticamente cada 3 segundos
   - Redirige a Home cuando el email se verifica

2. ✅ **Métodos de validación** en `SupabaseAuthService`
   - `isEmailVerified()` - Verifica si el email está confirmado
   - `getUserVerificationStatus()` - Obtiene estado completo

3. ✅ **Lógica de redirección** en `LoginScreen`
   - Si el usuario registra: Va a la pantalla de verificación
   - Si el usuario inicia sesión SIN verificar: Va a la pantalla de verificación
   - Si el usuario inicia sesión VERIFICADO: Va a Home

---

## 🔧 PASOS PARA HABILITAR EN SUPABASE

### Paso 1: Acceder a Supabase
1. Ve a https://app.supabase.com
2. Selecciona tu proyecto **ConVive**
3. En el menú izquierdo, ve a **Authentication**

### Paso 2: Habilitar Email Verification

1. En la sección **Authentication**, haz clic en **Providers**
2. Haz clic en **Email** (o busca Email)
3. En la sección **Email**, buscas **"Confirm email"** o **"Email Verification"**
4. **ACTIVA** el toggle (si está desactivado)

✅ **Esto es lo opuesto a lo que hicimos antes**

### Paso 3: Configura el Proveedor de Email (IMPORTANTE)

**OPCIÓN A: Usar Supabase Auth (Gratuito, pero lento)**
- Dejalo como está, Supabase enviará el email automáticamente

**OPCIÓN B: Usar Resend (Recomendado, más rápido)**
1. Ve a https://resend.com
2. Crea una cuenta gratuita
3. Copia tu API Key
4. En Supabase → Email → Resend
5. Pega la API Key

**OPCIÓN C: Usar SendGrid**
1. Ve a https://sendgrid.com
2. Crea una cuenta y obtén la API Key
3. En Supabase → Email → SendGrid
4. Pega la API Key

---

## 🧪 PROBAR EL FLUJO

### Ahora cuando registres:
```
1. Usuario completa el formulario
   ↓
2. Se crea la cuenta
   ↓
3. Se muestra pantalla "Verifica tu Email"
   ↓
4. Usuario recibe email con enlace
   ↓
5. Usuario hace clic en el enlace
   ↓
6. Email se marca como verificado
   ↓
7. App detecta automáticamente y redirige a Home
```

---

## 🚨 IMPORTANTE

Si **NO quieres verificación de email temporalmente**:
- Desactiva "Confirm email" en Supabase
- La app volverá al comportamiento anterior (acceso inmediato a Home)

---

## 📧 Configurar URL de Redirección (SI USAS RESEND O SENDGRID)

1. En Supabase → Authentication → URL Configuration
2. Bajo **Redirect URLs**, agrega:
   - `http://localhost:5000/auth/callback` (para desarrollo)
   - Tu URL de producción (cuando despliegues)

3. En el email, el enlace de verificación llevará al usuario a Supabase Auth
4. Supabase redirigirá automáticamente a tu app

---

## ✨ Resumen

- ✅ App lista para verificación de email
- ⏳ Solo falta activar en Supabase
- 📱 El flujo es automático y amigable
- 🔐 Los usuarios no pueden entrar sin verificar

¿Listo para activar la verificación? 🚀
