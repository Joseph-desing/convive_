# Guía: Implementar Tema Oscuro Global en ConVive

## Problema Identificado
El tema oscuro existe globalmente en `ThemeProvider`, pero muchas pantallas usan colores hardcodeados como:
- `Colors.white` → debe usar `Theme.of(context).scaffoldBackgroundColor`
- `Colors.grey[200]` → debe usar `ThemeHelper.secondaryBackground(context)`
- `Colors.black87` → debe usar `ThemeHelper.textPrimary(context)`

## Solución Implementada

### 1. ThemeProvider Mejorado (`lib/providers/theme_provider.dart`)
- ✅ DarkTheme con colores OLED reales (#0F0F0F, #1A1A1A)
- ✅ Colores de texto, inputs, cards definidos correctamente
- ✅ Se sync automáticamente en toda la app

### 2. ThemeHelper Nuevo (`lib/utils/theme_helper.dart`)
- ✅ Métodos helper para obtener colores adaptativos
- ✅ Funciona automáticamente con Material Design 3

## Cómo Usar en las Pantallas

### Ejemplo 1: Fondo de Scaffold
```dart
// ❌ MAL - Hardcodeado
Scaffold(
  backgroundColor: Colors.white,
  ...
)

// ✅ CORRECTO - Se adapta al tema
Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  ...
)
```

### Ejemplo 2: Contenedores y Cards
```dart
// ❌ MAL
Container(
  color: Colors.white,
  ...
)

// ✅ CORRECTO
Container(
  color: Theme.of(context).cardColor,
  ...
)
```

### Ejemplo 3: Botones y Backgrounds Secundarios
```dart
// ❌ MAL
Container(
  color: Colors.grey[200],
)

// ✅ CORRECTO - Importa el helper
import '../utils/theme_helper.dart';

Container(
  color: ThemeHelper.secondaryBackground(context),
)
```

### Ejemplo 4: Texto
```dart
// ❌ MAL
Text('Hola', style: TextStyle(color: Colors.black87))

// ✅ CORRECTO - Opción 1: Theme
Text(
  'Hola',
  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)
)

// ✅ CORRECTO - Opción 2: Helper (más fácil)
Text(
  'Hola',
  style: TextStyle(color: ThemeHelper.textPrimary(context))
)
```

## Pantallas que Necesitan Cambios

### Orden Prioritario:
1. **home_screen.dart** - Cambiar `Colors.white` background
2. **messages_screen.dart** - Cambiar colores de background
3. **profile_screen.dart** - Cambiar colores de cards
4. **matches_screen.dart** - Cambiar colores
5. **my_publications_screen.dart** - Cambiar colores
6. Todas las demás pantallas

## Búsqueda Rápida de Cambios Necesarios

### En VS Code, busca:
```
Colors.white
Colors.grey\[
Colors.black\d+
Color(0x
backgroundColor: Colors\.
color: Colors\.
fillColor: Colors\.
```

## Verificación Final

Una vez completado, deberia:
1. ✅ Todo el fondo cambiar a negro (#0F0F0F) en modo oscuro
2. ✅ Todo el texto volverse blanco automáticamente
3. ✅ Cards y overlays adaptar su color
4. ✅ Entrar a cualquier pantalla y todo debería ser oscuro

## Ejemplo Completo de una Pantalla Modernizada

```dart
import '../utils/theme_helper.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mi Pantalla'),
      ),
      body: ListView(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Contenido',
              style: TextStyle(
                color: ThemeHelper.textPrimary(context),
                fontSize: 16,
              ),
            ),
          ),
          Container(
            color: ThemeHelper.secondaryBackground(context),
            child: TextButton(
              onPressed: () {},
              child: const Text('Botón'),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Nota Importante

**El Material Design 3 en Flutter MANEJA AUTOMÁTICAMENTE:**
- `Theme.of(context).scaffoldBackgroundColor`
- `Theme.of(context).cardColor`
- `Theme.of(context).textTheme`
- `Colors.white` en inputs automáticamente cambia

**No necesitas:** crear CustomTheme personalizado, solo reemplazar hardcoded colors.
