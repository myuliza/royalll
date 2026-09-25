import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import 'app_product_image.dart';

/// Tarjeta de producto minimalista estilo Apple Store.
/// - Nombre formateado con 'Funda' y el modelo de iPhone correspondiente.
/// - Carga imágenes con AppProductImage (fallback seguro y fluido).
/// - No incluye botón de carrito interno redundante.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  Color _parseColorHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final swatchColor = _parseColorHex(producto.colorHex);
    final tieneDescuento = producto.enDescuento && producto.porcentajeDescuento > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bordeSuave, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor de imagen flotante tipo Apple Store
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: AppProductImage(
                      imageUrl: producto.fotoPrincipalUrl,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Badge de Descuento (Top Left)
                  if (tieneDescuento)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.rojoDescuento,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rojoDescuento.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${producto.porcentajeDescuento}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                  // Badge de Personalizable (Top Right)
                  if (producto.personalizable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bordeSuave),
                        ),
                        child: const Icon(
                          Icons.brush_rounded,
                          size: 13,
                          color: AppColors.dorado,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categoría, punto de color y código de color
                  Row(
                    children: [
                      if (swatchColor != Colors.transparent) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: swatchColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.bordeSuave,
                              width: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          producto.codigoColor.isNotEmpty
                              ? '${producto.categoria.toUpperCase()} • ${producto.codigoColor.toUpperCase()}'
                              : producto.categoria.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Nombre limpio (modelo de iPhone)
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Precios
                  if (tieneDescuento)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          producto.precioFinalFormateado,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rojoDescuento,
                          ),
                        ),
                        Text(
                          producto.precioOriginalFormateado,
                          style: const TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textoAtenuado,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      producto.precioFormateado,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.azul,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
