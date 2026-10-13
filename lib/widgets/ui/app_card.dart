import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'hover_lift.dart';

/// Tarjeta base: superficie redondeada, borde suave y sombra liviana.
/// Si tiene [onTap], reacciona al hover (escritorio), al foco (Tab) y al toque.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radio;
  final Color? color;
  final bool conBorde;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radio = AppRadius.lg,
    this.color,
    this.conBorde = true,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final brillo = Theme.of(context).brightness;
    final borde = BorderRadius.circular(radio);

    return HoverLift(
      habilitado: onTap != null,
      builder: (context, activo) => AnimatedContainer(
        duration: AppDurations.rapida,
        decoration: BoxDecoration(
          color: color ?? royal.superficie,
          borderRadius: borde,
          border: conBorde
              ? Border.all(color: activo ? AppColors.dorado.withValues(alpha: 0.6) : royal.borde)
              : null,
          boxShadow: activo ? AppShadows.elevada(brillo) : AppShadows.suave(brillo),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: borde,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
