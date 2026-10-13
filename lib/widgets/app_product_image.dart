import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget de renderizado de imágenes para fundas de productos en RoyalApp.
///
/// Implementación robusta basada en [Image.network]:
/// - Validación de protocolos (http/https) y sanitización de URLs.
/// - [loadingBuilder] con indicador circular y porcentaje de descarga.
/// - [errorBuilder] para fallback visual inmediato ante URLs rotas o fallos de red.
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
      content = _buildPlaceholder();
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
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      final urlLimpia = imageUrl.trim();
      content = Image.network(
        urlLimpia,
        key: ValueKey(urlLimpia),
        width: width,
        height: height,
        fit: fit,
        headers: const {
          'Accept': 'image/*',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
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
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
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

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_iphone_rounded,
              size: (height != null && height! < 60) ? 22 : 36,
              color: AppColors.textoAtenuado,
            ),
          ],
        ),
      ),
    );
  }
}
