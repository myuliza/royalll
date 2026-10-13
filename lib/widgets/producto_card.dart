import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../screens/producto_detalle_screen.dart';
import '../utils/visual.dart';
import 'app_product_image.dart';
import 'ui/hover_lift.dart';

/// Abre el detalle del producto (diálogo en escritorio, pantalla completa en móvil).
/// Se mantiene el nombre por compatibilidad con las pantallas existentes.
void mostrarModalProductoDetalle(BuildContext context, Producto p) => abrirDetalleProducto(context, p);

/// Tarjeta de producto minimalista estilo Apple Store.
/// - Nombre formateado con 'Funda' y el modelo de iPhone correspondiente.
/// - Carga imágenes con AppProductImage (fallback seguro y fluido).
/// - No incluye botón de carrito interno redundante.
/// - Se eleva al pasar el mouse o al enfocarla con Tab; responde al toque en móvil.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final royal = context.royal;
    final brillo = Theme.of(context).brightness;
    final swatchColor = colorDesdeHex(producto.colorHex, porDefecto: Colors.transparent);
    final tieneDescuento = producto.enDescuento && producto.porcentajeDescuento > 0;
    final colorPrecio = context.esOscuro ? AppColors.doradoClaro : AppColors.azul;
    final borde = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: true,
      label: '${producto.nombre}, ${producto.precioFinalFormateado}',
      child: HoverLift(
        builder: (context, activo) => AnimatedContainer(
          duration: AppDurations.rapida,
          decoration: BoxDecoration(
            color: royal.superficie,
            borderRadius: borde,
            border: Border.all(color: activo ? AppColors.dorado.withValues(alpha: 0.7) : royal.borde),
            boxShadow: activo ? AppShadows.elevada(brillo) : AppShadows.suave(brillo),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: borde,
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
                          margin: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: royal.fondoImagen,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AnimatedScale(
                            duration: AppDurations.media,
                            scale: activo ? 1.05 : 1,
                            child: AppProductImage(
                              imageUrl: producto.fotoPrincipalUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Badge de Descuento (Top Left)
                        if (tieneDescuento)
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.rojoDescuento,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                boxShadow: AppShadows.color(AppColors.rojoDescuento),
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
                            top: 14,
                            right: 14,
                            child: Tooltip(
                              message: 'Personalizable',
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: royal.superficie.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: royal.borde),
                                ),
                                child: const Icon(Icons.brush_rounded, size: 13, color: AppColors.dorado),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Información del producto
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
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
                                  border: Border.all(color: royal.borde, width: 0.8),
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
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: royal.textoSecundario,
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: royal.textoPrincipal,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Precios
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              producto.precioFinalFormateado,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: tieneDescuento ? AppColors.rojoDescuento : colorPrecio,
                              ),
                            ),
                            if (tieneDescuento)
                              Text(
                                producto.precioOriginalFormateado,
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: royal.textoAtenuado,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
