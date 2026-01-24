## 🚀 GUÍA PARA EMPEZAR A CHATEAR

### Paso 1: Crear las tablas en Supabase
1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a tu proyecto ConVive
3. Abre el **SQL Editor**
4. Copia todo el contenido del archivo `SQL_MENSAJES.sql` de este proyecto
5. Pégalo en el editor de SQL y ejecuta

### Paso 2: Entender el flujo de mensajes

```
Usuario A                Usuario B
   ↓                        ↓
Swipe Like ←────────→ Swipe Like
   ↓
Match Creado ✅
   ↓
Chat Creado Automáticamente ✅
   ↓
Usuario puede ver el chat en "Mensajes"
   ↓
Enviar/Recibir Mensajes
```

### Paso 3: Probar en la app

**Para crear un match y empezar a chatear:**

1. **Crea 2 usuarios de prueba:**
   - Email 1: `user1@test.com` | Password: `Test1234!`
   - Email 2: `user2@test.com` | Password: `Test1234!`

2. **En cada usuario:**
   - Completa el perfil
   - Agrega hábitos
   - Crea una propiedad/búsqueda de compañero

3. **Crea un match manualmente en Supabase:**
   ```sql
   -- En Supabase SQL Editor
   INSERT INTO matches (user_a, user_b, compatibility_score)
   VALUES ('user_a_id', 'user_b_id', 85.0);
   ```

4. **Ahora en la app:**
   - Inicia sesión como Usuario A
   - Ve a "Mensajes"
   - Deberías ver el chat
   - ¡Abre y empieza a escribir!

5. **Prueba en tiempo real:**
   - Abre la app en 2 dispositivos/ventanas
   - Inicia sesión con usuarios diferentes
   - Envía mensajes desde uno y ve cómo aparecen en el otro

### Paso 4: Pantalla de Mensajes

**En la pantalla de Mensajes verás:**
- ✅ Lista de todos tus chats activos
- ✅ Último mensaje actualizado
- ✅ Fecha del match

**Al abrir un chat:**
- ✅ Historial completo de mensajes
- ✅ Burbujas diferenciadas (tuyas en rosa, del otro en gris)
- ✅ Horas de cada mensaje
- ✅ Campo para escribir y enviar

### Paso 5: Flujo completo (Futuro)

Cuando tengas matches reales:
1. Usuario A hace swipe en Usuario B → Like
2. Usuario B hace swipe en Usuario A → Like
3. Sistema detecta compatibilidad > 70
4. Match se crea automáticamente ✅
5. Chat se crea automáticamente ✅
6. Ambos usuarios ven el chat en "Mensajes"
7. ¡Pueden chatear!

### 🔧 Troubleshooting

**No ves mensajes:**
- ✅ Verifica que el usuario esté autenticado
- ✅ Verifica que el match exista
- ✅ Verifica que el chat esté creado
- ✅ Recarga la pantalla

**Errores de permisos:**
- ✅ Las políticas RLS están configuradas
- ✅ Solo puedes ver tus propios chats
- ✅ Solo puedes enviar desde tu user_id

**Mensajes no aparecen en tiempo real:**
- ✅ El Realtime está habilitado (SQL ya lo hace)
- ✅ Recarga la página en el navegador
- ✅ Verifica la consola para errores

### 📱 UI de Mensajes

```
PANTALLA DE CHATS          DETALLE DEL CHAT
┌─────────────────┐        ┌──────────────────┐
│  Mensajes    🔄 │        │ Chat [ID] ← Atrás│
├─────────────────┤        ├──────────────────┤
│ [Avatar] Chat 1 │        │ Mensaje tuyo   →│
│ Match 15 ene    │        │ ← Mensaje otro   │
├─────────────────┤        │ Mensaje tuyo   →│
│ [Avatar] Chat 2 │        ├──────────────────┤
│ Match 20 ene    │        │ [Escribe aquí...│
├─────────────────┤        │ Enviar botón   ✓│
│ Sin mensajes... │        └──────────────────┘
└─────────────────┘
```

### ✅ Checklist

- [ ] Ejecuté el SQL en Supabase
- [ ] Creé usuarios de prueba
- [ ] Creé un match de prueba
- [ ] Veo chats en "Mensajes"
- [ ] Puedo enviar mensajes
- [ ] Veo mensajes en tiempo real

¡Listo! 🎉 Tu sistema de mensajes está funcionando.
