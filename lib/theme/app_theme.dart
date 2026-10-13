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

  // Tonos del modo oscuro
  static const oscuroSuperficieAlta = Color(0xFF1F2630);
  static const oscuroBorde = Color(0xFF30363D);
  static const oscuroTextoPrincipal = Color(0xFFE6EDF3);
  static const oscuroTextoSecundario = Color(0xFF9DA7B3);
  static const oscuroTextoAtenuado = Color(0xFF6E7681);

  /// Degradados de marca para tarjetas destacadas (FeatureTile / StatCard)
  static const degradadoCyan = [Color(0xFF00B4D8), Color(0xFF0369A1)];
  static const degradadoVerde = [Color(0xFF22C55E), Color(0xFF0F766E)];
  static const degradadoNaranja = [Color(0xFFFB923C), Color(0xFFEA580C)];
  static const degradadoRosa = [Color(0xFFF472B6), Color(0xFFBE185D)];
  static const degradadoVioleta = [Color(0xFF818CF8), Color(0xFF5B4FCF)];
  static const degradadoGrafito = [Color(0xFF334155), Color(0xFF161B22)];
}

/// Radios de borde estándar (16 a 24 px para superficies grandes).
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

/// Espaciados estándar.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Duraciones de animación (sutiles, 150 a 300 ms).
class AppDurations {
  static const rapida = Duration(milliseconds: 150);
  static const media = Duration(milliseconds: 220);
  static const lenta = Duration(milliseconds: 300);
}

/// Sombras suaves.
class AppShadows {
  static List<BoxShadow> suave(Brightness brillo) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: brillo == Brightness.dark ? 0.35 : 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> elevada(Brightness brillo) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: brillo == Brightness.dark ? 0.5 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> color(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Colores semánticos que cambian entre modo claro y oscuro.
/// Uso: `context.royal.textoPrincipal`, `context.royal.superficie`, etc.
@immutable
class RoyalColors extends ThemeExtension<RoyalColors> {
  final Color fondo;
  final Color superficie;
  final Color superficieAlta;
  final Color borde;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color textoAtenuado;
  final Color fondoImagen;
  final Color barraLateral;
  final Color acento;

  const RoyalColors({
    required this.fondo,
    required this.superficie,
    required this.superficieAlta,
    required this.borde,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.textoAtenuado,
    required this.fondoImagen,
    required this.barraLateral,
    required this.acento,
  });

  static const claro = RoyalColors(
    fondo: AppColors.fondo,
    superficie: AppColors.superficie,
    superficieAlta: Color(0xFFF1F3F6),
    borde: AppColors.bordeSuave,
    textoPrincipal: AppColors.textoPrincipal,
    textoSecundario: AppColors.textoSecundario,
    textoAtenuado: AppColors.textoAtenuado,
    fondoImagen: Color(0xFFF9FAFB),
    barraLateral: AppColors.azul,
    acento: AppColors.dorado,
  );

  static const oscuro = RoyalColors(
    fondo: AppColors.azul,
    superficie: AppColors.azulClaro,
    superficieAlta: AppColors.oscuroSuperficieAlta,
    borde: AppColors.oscuroBorde,
    textoPrincipal: AppColors.oscuroTextoPrincipal,
    textoSecundario: AppColors.oscuroTextoSecundario,
    textoAtenuado: AppColors.oscuroTextoAtenuado,
    // Las fotos de las fundas tienen fondo blanco: se presentan sobre una bandeja clara
    fondoImagen: Color(0xFFF3F4F6),
    barraLateral: AppColors.azulProfundo,
    acento: AppColors.doradoClaro,
  );

  @override
  RoyalColors copyWith({
    Color? fondo,
    Color? superficie,
    Color? superficieAlta,
    Color? borde,
    Color? textoPrincipal,
    Color? textoSecundario,
    Color? textoAtenuado,
    Color? fondoImagen,
    Color? barraLateral,
    Color? acento,
  }) {
    return RoyalColors(
      fondo: fondo ?? this.fondo,
      superficie: superficie ?? this.superficie,
      superficieAlta: superficieAlta ?? this.superficieAlta,
      borde: borde ?? this.borde,
      textoPrincipal: textoPrincipal ?? this.textoPrincipal,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      textoAtenuado: textoAtenuado ?? this.textoAtenuado,
      fondoImagen: fondoImagen ?? this.fondoImagen,
      barraLateral: barraLateral ?? this.barraLateral,
      acento: acento ?? this.acento,
    );
  }

  @override
  RoyalColors lerp(ThemeExtension<RoyalColors>? other, double t) {
    if (other is! RoyalColors) return this;
    return RoyalColors(
      fondo: Color.lerp(fondo, other.fondo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      superficieAlta: Color.lerp(superficieAlta, other.superficieAlta, t)!,
      borde: Color.lerp(borde, other.borde, t)!,
      textoPrincipal: Color.lerp(textoPrincipal, other.textoPrincipal, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      textoAtenuado: Color.lerp(textoAtenuado, other.textoAtenuado, t)!,
      fondoImagen: Color.lerp(fondoImagen, other.fondoImagen, t)!,
      barraLateral: Color.lerp(barraLateral, other.barraLateral, t)!,
      acento: Color.lerp(acento, other.acento, t)!,
    );
  }
}

extension RoyalThemeContext on BuildContext {
  RoyalColors get royal => Theme.of(this).extension<RoyalColors>() ?? RoyalColors.claro;
  bool get esOscuro => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static const fontFamily = 'Poppins';

  /// Tema claro (se mantiene el nombre `theme` por compatibilidad).
  static ThemeData get theme => light;

  static ThemeData get light => _construir(
        brillo: Brightness.light,
        royal: RoyalColors.claro,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azul,
          primary: AppColors.azul,
          secondary: AppColors.dorado,
          surface: AppColors.superficie,
          onPrimary: Colors.white,
          onSecondary: AppColors.azul,
        ),
        appBarFondo: AppColors.azul,
      );

  static ThemeData get dark => _construir(
        brillo: Brightness.dark,
        royal: RoyalColors.oscuro,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.dorado,
          brightness: Brightness.dark,
          primary: AppColors.doradoClaro,
          onPrimary: AppColors.azul,
          secondary: AppColors.dorado,
          onSecondary: AppColors.azul,
          surface: AppColors.azulClaro,
          onSurface: AppColors.oscuroTextoPrincipal,
          onSurfaceVariant: AppColors.oscuroTextoSecundario,
          surfaceContainerHighest: AppColors.oscuroSuperficieAlta,
          outline: AppColors.oscuroBorde,
          outlineVariant: AppColors.oscuroBorde,
        ),
        appBarFondo: AppColors.azulProfundo,
      );

  static ThemeData _construir({
    required Brightness brillo,
    required RoyalColors royal,
    required ColorScheme colorScheme,
    required Color appBarFondo,
  }) {
    final esOscuro = brillo == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brillo,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: royal.textoPrincipal,
          displayColor: royal.textoPrincipal,
        )
        .copyWith(
          headlineSmall: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            color: royal.textoPrincipal,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            color: royal.textoPrincipal,
            fontSize: 15,
          ),
          bodyMedium: TextStyle(
            fontFamily: fontFamily,
            color: royal.textoSecundario,
            fontSize: 14,
          ),
        );

    final formaBoton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm));
    final transiciones = PageTransitionsTheme(
      builders: {
        for (final plataforma in TargetPlatform.values)
          plataforma: const FadeForwardsPageTransitionsBuilder(),
      },
    );

    return base.copyWith(
      scaffoldBackgroundColor: royal.fondo,
      canvasColor: royal.fondo,
      textTheme: textTheme,
      extensions: [royal],
      pageTransitionsTheme: transiciones,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: royal.borde, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: royal.textoPrincipal),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dorado,
          foregroundColor: AppColors.azul,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: formaBoton,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.dorado,
          foregroundColor: AppColors.azul,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: formaBoton,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: esOscuro ? AppColors.doradoClaro : AppColors.azul,
          side: BorderSide(color: esOscuro ? AppColors.doradoClaro : AppColors.azul, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: formaBoton,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: esOscuro ? AppColors.doradoClaro : AppColors.azul,
          shape: formaBoton,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: royal.superficie,
        hintStyle: TextStyle(color: royal.textoAtenuado),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: royal.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: royal.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.dorado, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: royal.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: royal.borde, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: royal.superficie,
        selectedColor: AppColors.dorado,
        side: BorderSide(color: royal.borde),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: royal.borde),
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: royal.textoPrincipal,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: royal.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: royal.superficie,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: royal.textoAtenuado,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: royal.superficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.dorado.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: royal.textoPrincipal),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: royal.barraLateral,
        indicatorColor: AppColors.dorado,
        selectedIconTheme: const IconThemeData(color: AppColors.azul),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white70),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: royal.textoSecundario,
        textColor: royal.textoPrincipal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.dorado),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: esOscuro ? AppColors.oscuroSuperficieAlta : AppColors.azul,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
