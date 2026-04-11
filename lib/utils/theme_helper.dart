import 'package:flutter/material.dart';

/// Helper para obtener colores que se adapten automáticamente al tema oscuro/claro
class ThemeHelper {
  /// Color de fondo principal
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Color de superficie (cards, dialogs)
  static Color surface(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Color de texto primario
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
  }

  /// Color de texto secundario
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
  }

  /// Color de texto terciario (más claro)
  static Color textTertiary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white30 : Colors.black26;
  }

  /// Fondo para elementos secundarios (botones, inputs)
  static Color secondaryBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : Colors.grey[100] ?? Colors.grey;
  }

  /// Color de borde
  static Color border(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white10 : Colors.black12;
  }

  /// Color de overlay (semi-transparente)
  static Color overlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1);
  }

  /// Verifica si está en modo oscuro
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
