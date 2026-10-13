import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Estado vacío / de error: ícono, título, mensaje y acción opcional.
class EmptyState extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? accion;
  final VoidCallback? onAccion;
  final Color? colorIcono;

  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
    this.onAccion,
    this.colorIcono,
  });

  /// Variante para errores de carga.
  const EmptyState.error({
    super.key,
    this.titulo = 'No se pudieron cargar los datos',
    this.mensaje = 'Revisá tu conexión e intentá de nuevo.',
    this.accion,
    this.onAccion,
  })  : icono = Icons.cloud_off_rounded,
        colorIcono = AppColors.rojoDescuento;

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final color = colorIcono ?? AppColors.dorado;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 38, color: color),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: royal.textoPrincipal),
              ),
              if (mensaje != null) ...[
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  mensaje!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: royal.textoSecundario, height: 1.4),
                ),
              ],
              if (accion != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton(onPressed: onAccion, child: Text(accion!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
