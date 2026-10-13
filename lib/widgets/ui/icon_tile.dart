import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Mosaico con ícono circular y nombre debajo.
class IconTile extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;

  const IconTile({
    super.key,
    required this.titulo,
    required this.icono,
    this.color = AppColors.dorado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.75), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icono, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: royal.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
