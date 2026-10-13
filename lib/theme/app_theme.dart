import 'package:flutter/material.dart';

/// Paleta e identidad visual de Royale Cell.
/// - Negro/oscuro como color base (AppBar, navegación, fondos de contraste)
/// - Cyan/azul eléctrico como acento principal (badges, acciones clave, detalles premium)
/// - Inspirado en los tonos del logo Royale CELL (negro + cyan + plata).
class AppColors {
  // Acento principal — cyan/azul eléctrico (antes dorado)
  static const dorado = Color(0xFF00B4D8);
  static const doradoClaro = Color(0xFF38BDF8);
  static const doradoOscuro = Color(0xFF0891B2);

  // Fondo oscuro — negro profundo como el logo
  static const azul = Color(0xFF0D1117);
  static const azulClaro = Color(0xFF161B22);
  static const azulProfundo = Color(0xFF010409);

  // Tonos de soporte y fondo
  static const fondo = Color(0xFFF7F8FA);
  static const superficie = Colors.white;
  static const bordeSuave = Color(0xFFE5E7EB);

  // Tipografía
  static const textoPrincipal = Color(0xFF111827);
  static const textoSecundario = Color(0xFF6B7280);
  static const textoAtenuado = Color(0xFF9CA3AF);

  // Estados
  static const rojoDescuento = Color(0xFFDC2626);
  static const verdeStock = Color(0xFF16A34A);
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
        surface: AppColors.superficie,
        onPrimary: Colors.white,
        onSecondary: AppColors.azul,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textoPrincipal,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textoPrincipal,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textoSecundario,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dorado,
          foregroundColor: AppColors.azul,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azul,
          side: const BorderSide(color: AppColors.azul, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordeSuave),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bordeSuave),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dorado, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.bordeSuave, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.dorado,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.bordeSuave),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textoPrincipal,
        ),
      ),
    );
  }
}
