import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Bloque gris animado (pulso suave) que ocupa el lugar del contenido mientras carga.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radio;

  const SkeletonBox({super.key, this.width, this.height, this.radio = AppRadius.sm});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.royal.superficieAlta;
    final brillo = context.esOscuro ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, Color.alphaBlend(brillo, base), _ctrl.value),
          borderRadius: BorderRadius.circular(widget.radio),
        ),
      ),
    );
  }
}

/// Esqueleto de una tarjeta de producto (imagen + dos líneas de texto).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return Container(
      decoration: BoxDecoration(
        color: royal.superficie,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: royal.borde),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SkeletonBox(width: double.infinity, radio: AppRadius.md)),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: 90, height: 10),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: 70, height: 14),
        ],
      ),
    );
  }
}

/// Grilla de esqueletos para listados que están cargando.
class SkeletonGrid extends StatelessWidget {
  final int cantidad;
  final double anchoMaximoItem;
  final double proporcion;

  const SkeletonGrid({
    super.key,
    this.cantidad = 8,
    this.anchoMaximoItem = 240,
    this.proporcion = 0.72,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: anchoMaximoItem,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: proporcion,
      ),
      itemCount: cantidad,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}
