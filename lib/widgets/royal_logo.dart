import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logo oficial de Royal.
/// Diseñado con un emblema de corona vectorial minimalista,
/// acabados en dorado metálico y tipografía premium con kerning expandido.
class RoyalLogo extends StatelessWidget {
  final double size;
  final bool isLight; // Si true, texto blanco (para AppBar azul). Si false, texto azul.
  final bool showSubtitle;

  const RoyalLogo({
    super.key,
    this.size = 28,
    this.isLight = true,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? Colors.white : AppColors.azul;
    final subtitleColor = isLight ? AppColors.doradoClaro : AppColors.textoSecundario;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emblema con corona vectorial y gradiente dorado
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFDF70), // Dorado brillante
                AppColors.dorado,   // Dorado base
                Color(0xFF997512), // Dorado profundo
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.dorado.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: Size(size * 0.65, size * 0.65),
              painter: _CoronaPainter(color: AppColors.azul),
            ),
          ),
        ),
        const SizedBox(width: 9),
        // Tipografía
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROYAL',
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.62,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.5,
                height: 1.0,
              ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                'CASE STUDIO',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Dibuja una corona real minimalista y precisa.
class _CoronaPainter extends CustomPainter {
  final Color color;

  _CoronaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Base de la corona
    final path = Path();
    path.moveTo(w * 0.12, h * 0.85); // esquina inferior izquierda
    path.lineTo(w * 0.88, h * 0.85); // esquina inferior derecha
    path.lineTo(w * 0.95, h * 0.30); // pico derecho
    path.lineTo(w * 0.68, h * 0.52); // valle derecho
    path.lineTo(w * 0.50, h * 0.18); // pico central (más alto)
    path.lineTo(w * 0.32, h * 0.52); // valle izquierdo
    path.lineTo(w * 0.05, h * 0.30); // pico izquierdo
    path.close();

    canvas.drawPath(path, paint);

    // Banda inferior decorativa
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.90, w * 0.76, h * 0.08),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(baseRect, paint);

    // Pequeñas esferas en las 3 puntas
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final r = w * 0.06;
    canvas.drawCircle(Offset(w * 0.05, h * 0.28), r, circlePaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.14), r * 1.15, circlePaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.28), r, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
