import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../providers/carrito_provider.dart';
import '../screens/producto_detalle_screen.dart';
import 'app_product_image.dart';

Color _parseHexGenerico(String hex) {
  try {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return Colors.grey;
  }
}

/// Muestra el modal compacto de producto con cierre automático al agregar al carrito.
void mostrarModalProductoDetalle(BuildContext context, Producto p) {
  final tieneDescuento = p.enDescuento && p.porcentajeDescuento > 0;
  final swatchColor = _parseHexGenerico(p.colorHex);
  final agotado = p.stock <= 0;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.60),
    builder: (dialogCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superior con botón de cerrar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.fondo,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.colorLegible.isNotEmpty
                          ? '${p.categoria.toUpperCase()} • ${p.colorLegible}'
                          : p.categoria.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Cerrar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
            ),

            // Imagen compacta
            Container(
              height: 160,
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(10),
              child: AppProductImage(
                imageUrl: p.fotoPrincipalUrl,
                fit: BoxFit.contain,
              ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Precios
                  Row(
                    children: [
                      Text(
                        p.precioFinalFormateado,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: tieneDescuento ? AppColors.rojoDescuento : AppColors.azul,
                        ),
                      ),
                      if (tieneDescuento) ...[
                        const SizedBox(width: 6),
                        Text(
                          p.precioOriginalFormateado,
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textoAtenuado,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.rojoDescuento,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '-${p.porcentajeDescuento}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Color y Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.colorLegible.isNotEmpty ? p.colorLegible : 'Estándar',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: agotado
                              ? Colors.red.withValues(alpha: 0.12)
                              : AppColors.verdeStock.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          agotado ? 'Agotado' : 'Stock: ${p.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: agotado ? Colors.red : AppColors.verdeStock,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(agotado ? 'Agotado' : 'Agregar al carrito'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: agotado ? Colors.grey : AppColors.dorado,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: agotado
                          ? null
                          : () {
                              final carrito = context.read<CarritoProvider>();
                              final agregado = carrito.agregar(p);
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    agregado
                                        ? '${p.nombre} agregado al carrito'
                                        : 'Stock agotado o límite alcanzado para ${p.nombre}',
                                  ),
                                  backgroundColor: agregado ? AppColors.azul : Colors.orange,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(height: 4),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 14),
                      label: const Text('Ver detalle completo', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductoDetalleScreen(producto: p),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bordeSuave, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                          producto.colorLegible.isNotEmpty
                              ? '${producto.categoria.toUpperCase()} • ${producto.colorLegible}'
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
