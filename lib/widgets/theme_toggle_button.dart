import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Botón sol / luna para alternar entre modo claro y oscuro.
/// Muestra el sol en modo claro y la luna en modo oscuro.
class ThemeToggleButton extends StatelessWidget {
  final Color? color;

  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ThemeController>();
    final oscuro = tema.esOscuro;

    return IconButton(
      tooltip: oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      color: color,
      onPressed: tema.alternar,
      icon: AnimatedSwitcher(
        duration: AppDurations.lenta,
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          oscuro ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          key: ValueKey(oscuro),
        ),
      ),
    );
  }
}
