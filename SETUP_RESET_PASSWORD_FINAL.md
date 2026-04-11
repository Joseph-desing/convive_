# 🔐 Setup Reset Password - Final

## ✅ QUÉ PEGAR EN SUPABASE

### 1️⃣ Redirect URLs (Agregar ESTE)

**Copia y pega en: Authentication → URL Configuration → Redirect URLs**

```
com.example.convive://reset-password
```

---

### 2️⃣ Email Template (Dejar VACÍO o usar DEFAULT)

**Ve a: Authentication → Email Templates → Password Reset**

**Opción A: Dejar vacío (RECOMENDADO)**
- Selecciona TODO el contenido
- Presiona Delete
- Guarda

**Opción B: Template minimalista**
```
Hola, recibimos tu solicitud de cambio de contraseña.

Haz clic aquí: {{ .ConfirmationURL }}

Este enlace expira en 24 horas.
```

---

## 📋 CHECKLIST FINAL

- [ ] Agregué `com.example.convive://reset-password` a Redirect URLs
- [ ] Limpié o simplifiqué el Email Template
- [ ] Compilé con `flutter clean && flutter pub get && flutter run`
- [ ] Probé: Forgot Password → Email → Link → Reset Password ✅

---

## 🧪 TEST FLOW

1. **En la app**: Login → Forgot Password
2. **Ingresa tu email**
3. **Revisa el email** - debe haber un link
4. **Haz clic en el link** → Abre la app en ResetPasswordScreen
5. **Ingresa nueva contraseña** (6+ caracteres)
6. **Haz clic "Cambiar Contraseña"**
7. ✅ **Debería ir al login automáticamente**

---

## ❌ Si NO funciona

- Verifica que el deep link esté en Supabase Redirect URLs
- Compila con `flutter clean`
- Intenta de nuevo

---

**¡Listo! El flujo está completo.**
