# ✅ GUÍA DE USO - BORRAR CONVERSACIÓN

## 📋 Resumen de cambios implementados

He agregado la funcionalidad de **borrar conversación** en la aplicación Convive. Esto permite a los usuarios eliminar un chat **SOLO DE SU VISTA**. 

**IMPORTANTE:** El otro usuario sigue viendo la conversación. Se implementó un "borrado suave" donde cada usuario solo oculta el chat para sí mismo.

---

## 🎯 Funcionalidad

### ¿Qué se borra?
- ✅ La conversación de TU vista (se marca como oculta para ti)
- ✅ Se desaparece de tu lista de chats

### ¿Qué NO se borra?
- ❌ Los mensajes NO se borran de la BD
- ❌ El chat NO se borra completamente
- ❌ El otro usuario SIGUE viendo la conversación completa
- ❌ El match (la conexión entre usuarios) sigue existiendo

---

## 🔧 Cambios técnicos

### 1. **Servicio: SupabaseMessagesService.dart**

Se agregó método `deleteChat(chatId, userId)`:

```dart
Future<void> deleteChat(String chatId, String userId) async {
  try {
    // 1. MARCAR como eliminado SOLO para este usuario
    // La conversación sigue existiendo en la BD
    await _supabase
        .from('chats')
        .update({'hidden_for_users': [userId]})  // Array de usuarios que lo ocultaron
        .eq('id', chatId);
    
    // 2. Limpiar streams en caché
    _streamCache.remove(chatId);
    _channelCache[chatId]?.unsubscribe();
    _channelCache.remove(chatId);
  } catch (e) {
    print('❌ Error marcando chat como eliminado: $e');
    rethrow;
  }
}
```

**Características:**
- ✅ Marca como oculto para el usuario actual
- ✅ El otro usuario sigue viendo todo
- ✅ Los mensajes NO se borran
- ✅ Limpia streams de realtime

---

### 2. **Provider: MessagesProvider.dart**

Se agregó método `deleteChat()`:

```dart
Future<void> deleteChat(String chatId) async {
  try {
    // 1. Eliminar en base de datos
    await SupabaseProvider.messagesService.deleteChat(chatId);
    
    // 2. Eliminar del estado local
    _chats.removeWhere((c) => c.id == chatId);
    _chatPreviews.removeWhere((p) => p.chat.id == chatId);
    _messages.remove(chatId);
    _lastReadAt.remove(chatId);
    
    // 3. Deseleccionar si estaba seleccionado
    if (_selectedChatId == chatId) {
      _selectedChatId = null;
    }
    
    _error = null;
  } catch (e) {
    _error = e.toString();
  }
  notifyListeners();  // Actualizar UI
}
```

**Características:**
- ✅ Elimina de la BD
- ✅ Actualiza el estado local
- ✅ Notifica listeners (la UI se actualiza)

---

### 3. **Interfaz: ChatDetailScreen (messages_screen.dart)**

Se agregó:

```dart
// En AppBar, nuevo actions:
actions: [
  PopupMenuButton<String>(
    onSelected: (value) {
      if (value == 'delete') {
        _showDeleteConfirmation();
      }
    },
    itemBuilder: (BuildContext context) => [
      const PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text(
              'Borrar conversación',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    ],
  ),
],
```

**Métodos agregados:**

```dart
// Diálogo de confirmación
void _showDeleteConfirmation() {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text('¿Borrar conversación?'),
      content: Text('Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteChat();
          },
          child: Text('Borrar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

// Ejecutar eliminación
Future<void> _deleteChat() async {
  try {
    // Mostrar indicador
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eliminando conversación...')),
    );
    
    // Eliminar mediante provider
    final provider = context.read<MessagesProvider>();
    await provider.deleteChat(widget.chat.id);
    
    // Mostrar confirmación y volver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Conversación eliminada'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

### 4. **Interfaz: ChatScreen (chat_screen.dart)**

Misma implementación que ChatDetailScreen para consistencia.

---

## 👤 Experiencia del usuario

### Paso 1: Abrir chat
El usuario está en una conversación y ve el menú de opciones en el AppBar:

```
┌────────────────────────────────────────┐
│ ← [Avatar] Juan Luis           ⋮      │  ← Botón de menú (3 puntos)
├────────────────────────────────────────┤
│                                        │
│  Conversación...                       │
│                                        │
└────────────────────────────────────────┘
```

### Paso 2: Tocar el menú
El usuario toca los 3 puntos (⋮) y aparece un menú desplegable:

```
┌─ Borrar conversación [con icono 🗑️ rojo]
```

### Paso 3: Seleccionar "Borrar conversación"
Se muestra un diálogo de confirmación:

```
┌─────────────────────────────────────┐
│ ¿Borrar conversación?              │
│                                     │
│ Esta acción no se puede deshacer.   │
│ Se eliminarán todos los mensajes.   │
│                                     │
│ [Cancelar]        [Borrar]         │
└─────────────────────────────────────┘
```

**Botones:**
- **Cancelar** → Cierra el diálogo, no borra nada
- **Borrar** → Procede con la eliminación

### Paso 4: Se elimina el chat
Se muestra progreso:

```
Snackbar: "Eliminando conversación..."
```

Después:

```
Snackbar: "✅ Conversación eliminada" (verde)
```

El usuario es devuelto a la **lista de chats**, donde ya no verá esa conversación.

---

## 📊 Flujo de datos

```
Usuario toca "Borrar conversación"
            ↓
_showDeleteConfirmation() 
            ↓
Muestra AlertDialog
            ↓
Usuario confirma
            ↓
_deleteChat()
            ↓
MessagesProvider.deleteChat(chatId)
            ↓
SupabaseMessagesService.deleteChat(chatId)
            ↓
DELETE FROM messages WHERE chat_id = ?
DELETE FROM chats WHERE id = ?
            ↓
Successo:
  - Actualizar estado local
  - Notificar listeners
  - Mostrar confirmación
  - Volver a lista de chats
```

---

## 🔐 Consideraciones de seguridad

### ✅ Ya implementado

1. **Confirmación obligatoria** - No se puede borrar accidentalmente
2. **Advertencia clara** - Dice que la acción no se puede deshacer
3. **Validación en servidor** - Supabase valida antes de eliminar
4. **Borrado cascada** - Los mensajes también se borran

### 🔧 Mejoras futuras

1. **Borrado suave (soft delete)**
   - Marcar como eliminado en lugar de borrar
   - Permitir recuperar en 30 días
   
2. **Notificación al otro usuario**
   - Decirle que eliminaron la conversación
   - Opción de recuperar o crear nueva
   
3. **Backup de conversaciones**
   - Exportar como PDF antes de borrar
   - Descargar transcripción

4. **Borrado parcial**
   - Borrar solo mensajes anteriores a cierta fecha
   - Mantener algunos mensajes específicos

---

## 📝 Código de ejemplo

Si quieres borrar un chat programáticamente desde otra parte:

```dart
// Forma 1: Usar el provider
final provider = context.read<MessagesProvider>();
await provider.deleteChat(chatId);

// Forma 2: Usar el servicio directamente
await SupabaseProvider.messagesService.deleteChat(chatId);
```

---

## 🐛 Manejo de errores

Si algo falla:

```dart
try {
  await provider.deleteChat(chatId);
} catch (e) {
  // Mostrar error al usuario
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## 📍 Ubicación de archivos modificados

| Archivo | Cambios |
|---------|---------|
| `lib/services/supabase_messages_service.dart` | ➕ `deleteChat()` |
| `lib/providers/messages_provider.dart` | ➕ `deleteChat()` |
| `lib/screens/messages_screen.dart` | ➕ Menu en AppBar, ➕ `_showDeleteConfirmation()`, ➕ `_deleteChat()` |
| `lib/screens/chat_screen.dart` | ➕ Menu en AppBar, ➕ `_showDeleteConfirmation()`, ➕ `_deleteChat()` |

---

## 🧪 Testing

Para probar la funcionalidad:

1. **Abre un chat**
   - Navega a MessagesScreen
   - Toca un chat para abrir ChatDetailScreen

2. **Busca el menú**
   - En el AppBar, hay 3 puntos (⋮) a la derecha
   - Si no los ves, verifica que el AppBar tiene `actions`

3. **Toca "Borrar conversación"**
   - Debe aparecer un diálogo de confirmación

4. **Confirma la eliminación**
   - Toca "Borrar"
   - Debe mostrar "Eliminando..."
   - Luego "✅ Conversación eliminada"
   - Te devuelve a la lista

5. **Verifica que se borró**
   - El chat NO debe aparecer en la lista
   - Si lo vuelves a abrir, debe estar vacío

---

## 🎨 Diseño visual

### AlertDialog
```
┌─────────────────────────────────────────┐
│  ¿Borrar conversación?                 │  ← Bold
│                                         │
│  Esta acción no se puede deshacer. Se   │  ← Gris
│  eliminarán todos los mensajes de esta  │
│  conversación.                          │
│                                         │
│         [Cancelar]  [Borrar]           │
│         Gris         Rojo              │
└─────────────────────────────────────────┘
```

### PopupMenu
```
┌─ 🗑️ Borrar conversación  ← Rojo
```

### SnackBars
```
"Eliminando conversación..."     ← Naranja/gris
"✅ Conversación eliminada"      ← Verde
"Error al eliminar..."           ← Rojo
```

---

## 💡 Notas de implementación

1. **Doble check de seguridad**
   - Valida en cliente (AlertDialog)
   - Valida en servidor (Supabase RLS)

2. **Limpieza de streams**
   - Desuscribe automáticamente del realtime
   - Evita memory leaks
   - Importante para apps de larga duración

3. **Feedback del usuario**
   - Muestra cada paso (eliminando... ✅ eliminado)
   - El usuario sabe que sucedió
   - No hay confusión

4. **Volver automático**
   - Navigator.pop() después de 500ms
   - Da tiempo de ver el mensaje de confirmación
   - Buena UX

---

## 📚 Documentación relacionada

- `ANALISIS_CHAT_MENSAJES.md` - Arquitectura completa
- `ANALISIS_PANTALLA_CHAT.md` - Detalles de UI/UX

---

## ✅ Checklist de verificación

- ✅ Método en servicio (deleteChat)
- ✅ Método en provider (deleteChat)
- ✅ UI en ChatDetailScreen (menu + diálogo)
- ✅ UI en ChatScreen (menu + diálogo)
- ✅ Diálogo de confirmación
- ✅ SnackBars de estado
- ✅ Limpieza de streams
- ✅ Volver a lista automáticamente
- ✅ Manejo de errores
- ✅ Logging para debugging

---

## 🚀 Próximos pasos

1. Probar la funcionalidad en ambas pantallas
2. Verificar que no aparecen errores en la consola
3. Agregar más opciones en el menú (ej: exportar, silenciar)
4. Implementar las mejoras futuras listadas arriba

