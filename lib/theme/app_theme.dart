import 'package:flutter/material.dart';

/// Paleta e identidad visual de Royal.
/// Dorado como color de acento (precios, botones principales, detalles)
/// Azul como color base/estructural (app bar, fondos oscuros, textos fuertes)
class AppColors {
  static const dorado = Color(0xFFC9A227);
  static const doradoClaro = Color(0xFFE4C766);
  static const azul = Color(0xFF0B2545);
  static const azulClaro = Color(0xFF13315C);
  static const fondo = Color(0xFFF7F7F5);
  static const textoPrincipal = Color(0xFF1A1A1A);
  static const textoSecundario = Color(0xFF6B6B6B);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azul,
        primary: AppColors.azul,
        secondary: AppColors.dorado,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textoPrincipal),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textoPrincipal),
        bodyMedium: TextStyle(color: AppColors.textoSecundario),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dorado,
          foregroundColor: AppColors.azul,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azul,
          side: const BorderSide(color: AppColors.azul),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
