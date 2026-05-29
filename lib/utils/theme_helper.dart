import 'package:flutter/material.dart';

/// Helper para obtener colores que se adapten automáticamente al tema oscuro/claro
class ThemeHelper {
  // ==================== BACKGROUNDS ====================
  /// Color de fondo principal
  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Fondo oscuro elegante para modo oscuro, claro para modo claro
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF9FAFB);
  }

  // ==================== SURFACES / CARDS ====================
  /// Color de superficie (cards, dialogs, contenedores)
  static Color surface(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Superficie secundaria (inputs, elementos secundarios)
  static Color secondaryBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF242424) : Colors.grey[100] ?? Colors.grey;
  }

  /// Superficie terciaria (elementos aún más claros/oscuros)
  static Color tertiaryBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2A2A2A) : Colors.grey[50] ?? Colors.white;
  }

  // ==================== TEXT ====================
  /// Color de texto primario (títulos, texto importante)
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF5F5F5)
        : const Color(0xFF1F2937);
  }

  /// Color de texto secundario (subtítulos, texto menos importante)
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF6B7280);
  }

  /// Color de texto terciario (texto muy suave)
  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA0A0A0)
        : const Color(0xFF9CA3AF);
  }

  /// Color de texto very light (para desactivado, muy suave)
  static Color textHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF808080)
        : const Color(0xFFC2C2C2);
  }

  // ==================== BORDERS / DIVIDERS ====================
  /// Color de borde suave
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF333333)
        : const Color(0xFFE5E7EB);
  }

  /// Color de divisor
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEEEEEE);
  }

  // ==================== SPECIAL COLORS ====================
  /// Color para overlay/sombra semi-transparente
  static Color overlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.5)
        : Colors.black.withOpacity(0.1);
  }

  /// Color para overlay suave (semi-transparente light)
  static Color overlayLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);
  }

  /// Color para error/eliminación elegante (rojo coral)
  static Color error(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF5A5F)
        : const Color(0xFFFF5A5F);
  }

  /// Color para warning/alert elegante (naranja oscuro)
  static Color warning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF9800)
        : const Color(0xFFFFA500);
  }

  /// Color para success
  static Color success(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF4CAF50);
  }

  // ==================== UTILITIES ====================
  /// Verifica si está en modo oscuro
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Retorna color basado en condición de modo oscuro
  static Color conditional(BuildContext context, Color darkColor, Color lightColor) {
    return isDarkMode(context) ? darkColor : lightColor;
  }

  /// Retorna texto blanco/negro automático según el color de fondo
  static Color contrastText(Color backgroundColor) {
    // Calcular luminancia del color
    final luminance = backgroundColor.computeLuminance();
    // Si es muy oscuro, texto blanco; si es claro, texto negro
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
