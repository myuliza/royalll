import 'package:flutter/widgets.dart';

enum TipoPantalla { movil, tablet, escritorio }

/// Breakpoints: móvil < 600 px, tablet 600–1024 px, escritorio > 1024 px.
class Breakpoints {
  static const double tablet = 600;
  static const double escritorio = 1024;

  /// Ancho máximo del contenido centrado.
  static const double anchoMaximo = 1400;

  static TipoPantalla deAncho(double ancho) {
    if (ancho < tablet) return TipoPantalla.movil;
    if (ancho <= escritorio) return TipoPantalla.tablet;
    return TipoPantalla.escritorio;
  }

  static TipoPantalla of(BuildContext context) => deAncho(MediaQuery.sizeOf(context).width);

  static bool esMovil(BuildContext context) => of(context) == TipoPantalla.movil;
  static bool esTablet(BuildContext context) => of(context) == TipoPantalla.tablet;
  static bool esEscritorio(BuildContext context) => of(context) == TipoPantalla.escritorio;

  /// Padding lateral recomendado según el tamaño de pantalla.
  static double paddingLateral(BuildContext context) => switch (of(context)) {
        TipoPantalla.movil => 16,
        TipoPantalla.tablet => 24,
        TipoPantalla.escritorio => 32,
      };
}

/// Centra el contenido con un ancho máximo (por defecto 1400 px).
class ContenidoCentrado extends StatelessWidget {
  final Widget child;
  final double anchoMaximo;
  final EdgeInsetsGeometry? padding;

  const ContenidoCentrado({
    super.key,
    required this.child,
    this.anchoMaximo = Breakpoints.anchoMaximo,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: Breakpoints.paddingLateral(context)),
          child: child,
        ),
      ),
    );
  }
}
