import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Inspirados en el rosado/fucsia
  static const primary = Color(0xFFD91E78); // Fucsia/Rosa fuerte
  static const secondary = Color(0xFF9C27B0); // Púrpura
  static const accent = Color(0xFFE91E63); // Rosa accent
  
  // Gradientes actualizados
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFD91E78), Color(0xFF9C27B0)], // Fucsia a Púrpura
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const purplePinkGradient = LinearGradient(
    colors: [Color(0xFFD91E78), Color(0xFFE91E63)], // Fucsia a Rosa
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const pinkGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFD91E78), Color(0xFF9C27B0)], // Degradado completo
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Backgrounds
  static const background = Color(0xFFF9FAFB);
  static const backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFFCE4EC), // Rosa muy claro
      Color(0xFFFFFFFF), // Blanco
      Color(0xFFF3E5F5), // Púrpura muy claro
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Textos
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  
  // Inputs
  static const inputFill = Color(0xFFF6F6F9);
  
  // Bordes
  static const borderColor = Color(0xFFE5E7EB);
}