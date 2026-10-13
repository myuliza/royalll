import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Encabezado de sección: título, subtítulo opcional y una acción como botón (no enlace).
class SectionHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final String? accion;
  final VoidCallback? onAccion;
  final IconData iconoAccion;
  final bool grande;

  const SectionHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
    this.onAccion,
    this.iconoAccion = Icons.arrow_forward_rounded,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: grande ? 26 : 18,
                    fontWeight: grande ? FontWeight.w800 : FontWeight.w700,
                    color: royal.textoPrincipal,
                    letterSpacing: grande ? -0.5 : 0,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: TextStyle(fontSize: grande ? 14 : 13, color: royal.textoSecundario),
                  ),
                ],
              ],
            ),
          ),
          if (accion != null)
            FilledButton.tonalIcon(
              onPressed: onAccion,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dorado.withValues(alpha: 0.14),
                foregroundColor: context.esOscuro ? AppColors.doradoClaro : AppColors.doradoOscuro,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600, fontSize: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
              iconAlignment: IconAlignment.end,
              icon: Icon(iconoAccion, size: 16),
              label: Text(accion!),
            ),
        ],
      ),
    );
  }
}
