import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Tarjeta de resumen: etiqueta, número grande, variación vs. período anterior.
/// Con [degradado] se pinta como tarjeta de color (texto blanco).
class StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final double? variacion; // porcentaje: 12.5 = +12,5 %
  final String textoVariacion;
  final List<Color>? degradado;

  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.variacion,
    this.textoVariacion = 'vs. período anterior',
    this.degradado,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final brillo = Theme.of(context).brightness;
    final conColor = degradado != null;
    final texto = conColor ? Colors.white : royal.textoPrincipal;
    final textoSuave = conColor ? Colors.white.withValues(alpha: 0.8) : royal.textoSecundario;

    final sube = (variacion ?? 0) >= 0;
    final colorVariacion = conColor
        ? Colors.white
        : (sube ? AppColors.verdeStock : AppColors.rojoDescuento);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        color: conColor ? null : royal.superficie,
        gradient: conColor
            ? LinearGradient(colors: degradado!, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: conColor ? null : Border.all(color: royal.borde),
        boxShadow: conColor ? AppShadows.color(degradado!.last) : AppShadows.suave(brillo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textoSuave),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: conColor ? Colors.white.withValues(alpha: 0.2) : AppColors.dorado.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 18, color: conColor ? Colors.white : AppColors.dorado),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: texto, letterSpacing: -0.5),
            ),
          ),
          if (variacion != null) ...[
            const SizedBox(height: AppSpacing.xs),
            // Si no entra en una línea, el texto de comparación baja (nunca se corta)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sube ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 16,
                      color: colorVariacion,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sube ? '+' : ''}${variacion!.toStringAsFixed(1).replaceAll('.', ',')} %',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorVariacion),
                    ),
                  ],
                ),
                Text(textoVariacion, style: TextStyle(fontSize: 11, color: textoSuave)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
