import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'hover_lift.dart';

/// Tarjeta grande de color (degradado) con ícono en círculo, título y contador.
class FeatureTile extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Color> degradado;
  final String? contador;
  final String? subtitulo;
  final VoidCallback? onTap;

  const FeatureTile({
    super.key,
    required this.titulo,
    required this.icono,
    this.degradado = AppColors.degradadoCyan,
    this.contador,
    this.subtitulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(AppRadius.xl);

    return HoverLift(
      habilitado: onTap != null,
      builder: (context, activo) => AnimatedContainer(
        duration: AppDurations.rapida,
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          borderRadius: borde,
          gradient: LinearGradient(
            colors: degradado,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppShadows.color(degradado.last).map((s) {
            return activo ? s.copyWith(blurRadius: s.blurRadius * 1.5) : s;
          }).toList(),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: borde,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg + 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, size: 30, color: degradado.last),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Título a lo ancho (hasta 2 líneas) para que no se corte en pantallas chicas
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitulo ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                      ),
                      if (contador != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            contador!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
