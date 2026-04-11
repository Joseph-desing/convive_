# 🧪 TEST: Sistema de Reset de Contraseña

## ✅ PASOS PARA PROBAR

### 1️⃣ COMPILAR Y EJECUTAR

```bash
cd c:\Users\HP\Desktop\convive_
flutter clean
flutter pub get
flutter run
```

---

### 2️⃣ SOLICITAR RESET DE CONTRASEÑA

En la app:
1. En **LoginScreen** → haz clic en **"¿Olvidaste tu contraseña?"**
2. Abre **ForgotPasswordScreen**
3. Ingresa tu email (ejemplo: `tu@gmail.com`)
4. Haz clic en **"Enviar Email de Recuperación"**
5. Deberías ver: ✅ "¡Correo Enviado!"

---

### 3️⃣ REVISAR EL EMAIL

1. Abre tu **Gmail/Email**
2. Busca email de **"no-reply@supabase.io"** o **"ConVive"**
3. Verás el botón **"Cambiar Contraseña"**

---

### 4️⃣ HACER CLIC EN EL BOTÓN DEL EMAIL

1. Haz clic en **"Cambiar Contraseña"** del email
2. El navegador debería abrirse
3. **LA APP DEBERÍA ABRIRSE AUTOMÁTICAMENTE** (deep link)
4. Deberías ver **ResetPasswordScreen**

---

### 5️⃣ VALIDAR RESET PASSWORD SCREEN

Deberías ver:
- ✅ Título: "Crear Nueva Contraseña"
- ✅ Mensaje verde: "Link válido. Ingresa tu nueva contraseña."
- ✅ Botón: "Cambiar Contraseña" (habilitado - NO gris)

**Si ves rojo/gris = el token NO llegó correctamente**

---

### 6️⃣ CAMBIAR CONTRASEÑA

1. Ingresa nueva contraseña (mínimo 6 caracteres)
   - Ejemplo: `nuevaPassword123`
2. Confirma la contraseña (debe coincidir)
3. Haz clic en **"Cambiar Contraseña"**

---

### 7️⃣ VERIFICAR ÉXITO

Deberías ver:
- ✅ Mensaje: "✅ Contraseña cambiada correctamente"
- ✅ La app espera 2 segundos
- ✅ Redirige automáticamente a **LoginScreen**

---

### 8️⃣ INICIA SESIÓN CON NUEVA CONTRASEÑA

1. En LoginScreen, ingresa tu email
2. Ingresa la **nueva contraseña** (que acabas de cambiar)
3. Haz clic en **"Iniciar Sesión"**
4. **DEBERÍA FUNCIONAR** ✅

---

## ⚠️ POSIBLES PROBLEMAS

### 🔴 Problema: "Link válido" pero aparece en ROJO

**Causa:** El token o email NO llegaron al ResetPasswordScreen

**Solución:**
1. Abre la **consola de Flutter** (terminal)
2. Busca líneas que empiezan con `🔍` o `📝`:
   ```
   🔍 URI Completa: com.example.convive://auth-callback?token=XXXXX
   📝 Token: XXXXX
   📧 Email: user@example.com
   ```
3. Si están vacías = problema con deep linking
4. Si aparecen = problema con la ruta de GoRouter

### 🔴 Problema: El navegador abre pero la app NO se abre

**Causa:** Deep link no registrado en Android/iOS

**Solución:**
- Verifica `AndroidManifest.xml` tiene:
  ```xml
  <data android:scheme="com.example.convive" android:host="auth-callback" />
  ```
- Verifica `Info.plist` tiene:
  ```xml
  <string>com.example.convive</string>
  ```

### 🔴 Problema: "El enlace ha expirado"

**Causa:** Pasó más de 24 horas o el token es inválido

**Solución:**
- Solicita un nuevo email de recuperación
- Prueba nuevamente

### 🔴 Problema: "Contraseña no cumple requisitos"

**Causa:** Contraseña menor a 6 caracteres

**Solución:**
- Ingresa contraseña con mínimo 6 caracteres

---

## 📊 FLUJO COMPLETO ESPERADO

```
LoginScreen
  ↓ (¿Olvidaste contraseña?)
ForgotPasswordScreen
  ↓ (ingresa email + click)
"¡Correo Enviado!"
  ↓ (Usuario revisa Gmail)
Email de ConVive
  ↓ (click en "Cambiar Contraseña")
Navegador abre link
  ↓ (deep link intercepta)
ResetPasswordScreen ✅
  ↓ (ingresa password nueva)
"✅ Contraseña cambiada"
  ↓ (redirige automáticamente)
LoginScreen
  ↓ (login con nueva password)
HomeScreen ✅
```

---

## 🎯 CHECKLIST FINAL

- [ ] Email de recuperación llega correctamente
- [ ] Deep link abre la app (no solo navegador)
- [ ] ResetPasswordScreen muestra "Link válido" en verde
- [ ] Puedo ingresar nueva contraseña
- [ ] Muestra "✅ Contraseña cambiada correctamente"
- [ ] Redirige a LoginScreen después de 2 segundos
- [ ] Puedo iniciar sesión con nueva contraseña

¡Si todo está ✅, el sistema está perfecto!
