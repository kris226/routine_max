import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        surface: Color(0xFF1E293B),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6366F1),
        surface: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  // --- Theme-aware color helpers ---
  // Use these instead of hardcoded Colors.white / Color(0xFFF8FAFC) / etc.
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  static Color cardColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : Colors.white;

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1E293B);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? Colors.grey.shade600 : Colors.grey.shade400;
}