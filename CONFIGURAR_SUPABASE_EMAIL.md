# 🔧 Guía para Configurar Reset Password en Supabase

## ❌ Problema Actual
El error `otp_expired` ocurre porque:
- El link del email es inválido o no está redirigiendo correctamente
- El `redirect_to` no está configurado en Supabase
- La app no está capturando el deep link correctamente

---

## ✅ Solución: Configurar Correctamente en Supabase

### PASO 1: Configurar las Redirect URLs

1. Ve a **Supabase Dashboard**
2. Selecciona tu proyecto
3. Ve a **Project Settings** (engranaje abajo a la izquierda)
4. Busca **Auth** en el menú
5. Abre la pestaña **URL Configuration**
6. En **Redirect URLs**, agrega:

```
com.example.convive://auth-callback
http://localhost:3000
http://localhost:3000/auth/callback
```

Haz clic en **Save**

---

### PASO 2: Editar el Template del Email

1. Ve a **Authentication** → **Email Templates**
2. Haz clic en **Password Reset** 
3. Reemplaza TODO el contenido con esto:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        }
        .header {
            background: linear-gradient(135deg, #E91E8C 0%, #D81B84 100%);
            padding: 40px 20px;
            text-align: center;
            color: white;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .header-subtitle {
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 18px;
            font-weight: 600;
            color: #111;
            margin-bottom: 16px;
        }
        .description {
            font-size: 14px;
            color: #666;
            line-height: 1.8;
            margin-bottom: 32px;
        }
        .button-container {
            text-align: center;
            margin: 32px 0;
        }
        .button {
            display: inline-block;
            background: linear-gradient(135deg, #E91E8C 0%, #D81B84 100%);
            color: #00A8E8;
            padding: 16px 48px;
            border-radius: 12px;
            text-decoration: none;
            font-weight: 600;
            font-size: 16px;
            border: none;
            cursor: pointer;
            box-shadow: 0 4px 15px rgba(233, 30, 140, 0.4);
            transition: all 0.3s ease;
        }
        .button:hover {
            background: linear-gradient(135deg, #D81B84 0%, #C01579 100%);
            box-shadow: 0 6px 20px rgba(233, 30, 140, 0.6);
            color: #0089B8;
        }
        .expiry-warning {
            background: #FEF3C7;
            border-left: 4px solid #F59E0B;
            padding: 16px;
            border-radius: 8px;
            margin: 24px 0;
            font-size: 13px;
            color: #92400E;
        }
        .footer {
            background: #F9FAFB;
            padding: 32px 30px;
            text-align: center;
            border-top: 1px solid #E5E7EB;
        }
        .footer-text {
            font-size: 12px;
            color: #999;
            line-height: 1.6;
            margin-bottom: 12px;
        }
        .security-note {
            background: #FDE7F4;
            border: 1px solid #FBCFE8;
            padding: 12px;
            border-radius: 6px;
            font-size: 12px;
            color: #991B6B;
            margin-top: 12px;
        }
        .icon {
            font-size: 48px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="icon">🔐</div>
            <div class="logo">ConVive</div>
            <div class="header-subtitle">Restablecer tu contraseña</div>
        </div>

        <!-- Content -->
        <div class="content">
            <div class="greeting">¡Hola! 👋</div>
            
            <div class="description">
                Recibimos una solicitud para restablecer la contraseña de tu cuenta ConVive. 
                Si fuiste tú, haz clic en el botón de abajo para crear una nueva contraseña segura.
            </div>

            <!-- Button -->
            <div class="button-container">
                <a href="{{ .ConfirmationURL }}" class="button">
                    🔄 Cambiar Contraseña
                </a>
            </div>

            <!-- Expiry Warning -->
            <div class="expiry-warning">
                ⏰ <strong>Este enlace expirará en 24 horas</strong> por razones de seguridad.
            </div>

            <!-- Auto-link fallback -->
            <div style="font-size: 12px; color: #999; margin-top: 24px; word-break: break-all;">
                O copia y pega este enlace en tu navegador:<br/>
                <code style="background: #f0f0f0; padding: 8px; border-radius: 4px; display: inline-block; margin-top: 8px;">
                    {{ .ConfirmationURL }}
                </code>
            </div>
        </div>

        <!-- Footer -->
        <div class="footer">
            <div class="footer-text">
                <strong>¿No solicitaste este cambio?</strong><br/>
                Si no fuiste tú, ignora este email. Tu contraseña seguirá protegida.
            </div>

            <div class="security-note">
                🛡️ Nunca compartimos tu contraseña por email. 
                ConVive nunca te pedirá que respondas este email.
            </div>

            <div class="footer-text" style="margin-top: 16px; border-top: 1px solid #E5E7EB; padding-top: 16px;">
                © 2026 ConVive. Todos los derechos reservados.<br/>
                <a href="https://convive.app" style="color: #E91E8C; text-decoration: none;">Visita nuestro sitio</a> | 
                <a href="https://convive.app/privacy" style="color: #E91E8C; text-decoration: none;">Privacidad</a>
            </div>
        </div>
    </div>
</body>
</html>
```

Haz clic en **Save**

---

### PASO 3: Configurar OTP Expiry Duration

1. En **Project Settings** → **Auth**
2. Busca **OTP Expiry Duration**
3. Cámbialo a **86400** segundos (24 horas)
4. Haz clic en **Save**

---

### PASO 4: Verificar el Email Template Variables

Supabase proporciona automáticamente:
- `{{ .ConfirmationURL }}` - URL completa con token y redirect_to incluidos
- `{{ .SiteURL }}` - Tu URL de Supabase
- `{{ .ConfirmationURLWithRedirect }}` - URL con redirect automático

**NO NECESITAS** agregar manualmente `token=` o `type=` en el email. Supabase lo hace automáticamente.

---

## 🔍 Verificar la Configuración

Después de cambiar el template, prueba así:

1. Abre tu app
2. Ve a **Forgot Password**
3. Ingresa tu email
4. **Revisa el email inmediatamente** (antes de 24 horas)
5. Haz clic en el botón **"Cambiar Contraseña"**
6. Deberías ir directamente a la pantalla de reset en la app

---

## 📱 Lo que debería pasar:

```
Email llega → Haces clic en "Cambiar Contraseña"
    ↓
Se abre el navegador con URL como:
  com.example.convive://auth-callback?token=XXX&type=recovery&redirect_to=...
    ↓
Deep link abre la app automáticamente
    ↓
GoRouter lo captura y navega a ResetPasswordScreen
    ↓
Usuario ingresa nueva contraseña
    ↓
Se cambiar exitosamente ✅
```

---

## 🆘 Si aún no funciona:

### Opción A: Usar el Template Alternativo

Si el botón no funciona, prueba con un template simplificado:

```html
<p>Hola,</p>
<p>Aquí está tu enlace para cambiar la contraseña:</p>
<p><a href="{{ .ConfirmationURL }}">{{ .ConfirmationURL }}</a></p>
<p>Este enlace expira en 24 horas.</p>
```

Luego copia y pega el link completo en el navegador.

### Opción B: Verificar que el Scheme sea Correcto

En tu código de Flutter, busca en todos los archivos donde aparezca `com.example.convive` y asegúrate de que sea consistente.

Debería estar en:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `Supabase → URL Configuration → Redirect URLs`
- El template del email (automático)

Todos deben tener: **`com.example.convive`**

### Opción C: Testing Manual

Para probar sin esperar email, puedes:

1. Abre el navegador
2. Ingresa esta URL (con tu dominio de Supabase):
   ```
   https://tu-proyecto.supabase.co/auth/v1/verify?token=test_token&type=recovery&redirect_to=com.example.convive://auth-callback
   ```

3. Observa qué sucede

---

## ✨ Checklist Final

- [ ] Configuré Redirect URLs en Supabase
- [ ] Edité el template del email con {{ .ConfirmationURL }}
- [ ] Cambié OTP Expiry a 86400 segundos
- [ ] El scheme es `com.example.convive` en todas partes
- [ ] AndroidManifest.xml tiene el deep link configurado
- [ ] Info.plist tiene el URL scheme configurado
- [ ] main.dart tiene la ruta `/auth-callback` en GoRouter

Si completaste todo esto, ¡el flujo debería funcionar! 🎉
