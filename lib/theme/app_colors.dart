import 'package:flutter/material.dart';

class AppColors {
  // ===== Base Colors =====
  static const Color backgroundLight = Color(0xFFFFFFFF); // Fondo claro (opcional)
  static const Color backgroundDark = Color(0xFF0A0A0A);  // Fondo principal oscuro
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceDark = Color(0xFF1A1A1A);     // Tarjetas, inputs

  // ===== Text Colors =====
  static const Color textDark = Color(0xFFECECEC);        // Texto principal claro
  static const Color textLight = Color(0xFF0A0A0A);       // Texto secundario oscuro
  static const Color textMuted = Color(0xFF9E9E9E);       // Texto secundario / desactivado

  // ===== Accent Colors =====
  static const Color accentBlue = Color(0xFF0095F6);      // Azul Threads
  static const Color accentRed = Color(0xFFFF3B30);       // Error / alerta
  static const Color accentGreen = Color(0xFF34C759);     // Confirmación
  static const Color accentYellow = Color(0xFFFFCC00);    // Advertencia

  // ===== Borders =====
  static const Color borderLight = Color(0xFF2C2C2C);     // Bordes en dark
  static const Color borderDark = Color(0xFF2C2C2C);

  // ===== Misc =====
  static const Color divider = Color(0xFF333333);
  static const Color overlay = Color(0x1AFFFFFF);

  // ===== Theme Aliases =====
  static const Color primary = accentBlue;
  static const Color secondary = accentGreen;
  static const Color success = accentGreen;
  static const Color error = accentRed;
  static const Color warning = accentYellow;

  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color accentColor = primary;
  static const Color errorColor = error;
  static const Color warningColor = warning;
  static const Color textPrimary = textDark;
  static const Color textSecondary = textMuted;
  static const Color backgroundColor = backgroundDark;  // 🔹 Fondo principal dark
}
