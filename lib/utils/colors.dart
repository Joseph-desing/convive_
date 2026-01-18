import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF9333EA);
  static const secondary = Color(0xFF3B82F6);
  static const accent = Color(0xFF10B981);
  
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const background = Color(0xFFF9FAFB);
  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAF5FF), Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
}