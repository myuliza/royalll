import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui/skeleton.dart';

/// Widget de renderizado de imágenes para fundas de productos en RoyalApp.
///
/// Implementación robusta basada en [Image.network]:
/// - Validación de protocolos (http/https) y sanitización de URLs.
/// - [loadingBuilder] con esqueleto animado e indicador de porcentaje de descarga.
/// - [frameBuilder] con aparición suave al terminar de cargar.
/// - [errorBuilder] para fallback visual inmediato ante URLs rotas o fallos de red (nunca queda vacío).
/// - [ValueKey] que garantiza la actualización fluida e inmediata en tiempo real al editar la URL.
class AppProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.borderRadius,
  });

  bool get _esAssetLocal => imageUrl.trim().startsWith('assets/');

  bool get _esUrlValida {
    final s = imageUrl.trim();
    if (s.isEmpty) return false;
    if (_esAssetLocal) return true;
    final uri = Uri.tryParse(s);
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (!_esUrlValida) {
      content = _buildPlaceholder(context);
    } else if (_esAssetLocal) {
      // Si la URL guardada en Firestore aún tiene .png, corregir a .jpg que es el formato real
      var assetPath = imageUrl.trim();
      if (assetPath.endsWith('.png')) {
        assetPath = assetPath.replaceAll(RegExp(r'\.png$', caseSensitive: false), '.jpg');
      }

      content = Image.asset(
        assetPath,
        key: ValueKey(assetPath),
        width: width,
        height: height,
        fit: fit,
        frameBuilder: _aparicionSuave,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    } else {
      final urlLimpia = imageUrl.trim();
      content = Image.network(
        urlLimpia,
        key: ValueKey(urlLimpia),
        width: width,
        height: height,
        fit: fit,
        // En web, si el servidor no permite CORS (p. ej. Firebase Storage sin configurar),
        // se muestra con un <img> del navegador (requiere no enviar headers).
        // En las demás plataformas no tiene efecto.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        frameBuilder: _aparicionSuave,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: SkeletonBox(width: width, height: height, radio: 0)),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.dorado,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context);
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  /// Aparición suave (fade) de la imagen cuando llega el primer cuadro.
  static Widget _aparicionSuave(BuildContext context, Widget child, int? frame, bool sincronica) {
    if (sincronica) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: AppDurations.lenta,
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final royal = context.royal;
    return Container(
      width: width,
      height: height,
      color: royal.fondoImagen,
      child: Center(
        child: Icon(
          Icons.phone_iphone_rounded,
          size: (height != null && height! < 60) ? 22 : 36,
          color: royal.textoAtenuado,
        ),
      ),
    );
  }
}
